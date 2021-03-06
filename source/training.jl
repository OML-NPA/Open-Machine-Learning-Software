
# Get urls of files in selected folders
function get_urls_training_main(training::Training,training_data::Training_data,
        model_data::Model_data)
    if model_data.type[2]=="Images"
        allowed_ext = ["png","jpg","jpeg"]
    end
    urls = get_urls2(training,training_data,allowed_ext)
    return urls
end
get_urls_training() = get_urls_training_main(training,training_data,model_data)

# Set training starting time
function set_training_starting_time_main(training_plot_data::Training_plot_data)
    training_plot_data.starting_time = now()
    return nothing
end
set_training_starting_time() =
    set_training_starting_time_main(training_plot_data)

# Calculates the time elapsed from the begining of training
function training_elapsed_time_main(training_plot_data::Training_plot_data)
    dif = (now() - training_plot_data.starting_time).value
    hours = string(Int64(round(dif/3600000)))
    minutes_num = floor(dif/60000)
    minutes = string(Int64(minutes_num - floor(minutes_num/60)*60))
    if length(minutes)<2
        minutes = string("0",minutes)
    end
    seconds_num = round(dif/1000)
    seconds = string(Int64(seconds_num - floor(seconds_num/60)*60))
    if length(seconds)<2
        seconds = string("0",seconds)
    end
    return string(hours,":",minutes,":",seconds)
end
training_elapsed_time() = training_elapsed_time_main(training_plot_data)

#---
# Augments images using rotation and mirroring
function augment!(data::Vector{Tuple{T1,T2}},img::T1,label::T2,num_angles::Int64,
        pix_num::Tuple{Int64,Int64},min_fr_pix::Float64) where {T1<:Array{Float32,3},T2<:BitArray{3}}
    lim = prod(pix_num)*min_fr_pix
    angles_range = range(0,stop=2*pi,length=num_angles+1)
    angles = collect(angles_range[1:end-1])
    num = length(angles)
    @threads for g = 1:num
        angle_val = angles[g]
        img2 = rotate_img(img,angle_val)
        label2 = rotate_img(label,angle_val)
        num1 = Int64(floor(size(label2,1)/(pix_num[1]*0.9)))
        num2 = Int64(floor(size(label2,2)/(pix_num[2]*0.9)))
        step1 = Int64(floor(size(label2,1)/num1))
        step2 = Int64(floor(size(label2,2)/num2))
        num_batch = 2*(num1-1)*(num2-1) 
        @threads for i = 1:num1-1
            @threads for j = 1:num2-1
                ymin = (i-1)*step1+1;
                xmin = (j-1)*step2+1;
                I1 = img2[ymin:ymin+pix_num[1]-1,xmin:xmin+pix_num[2]-1,:]
                I2 = label2[ymin:ymin+pix_num[1]-1,xmin:xmin+pix_num[2]-1,:]
                if std(I1)<0.01 || sum(I2)<lim 
                    continue
                else
                    for h = 1:2
                        if h==1
                            I1_out = I1
                            I2_out = I2
                        elseif h==2
                            I1_out = reverse(I1, dims = 2)
                            I2_out = reverse(I2, dims = 2)
                        end
                        data_out = (I1_out,I2_out)
                        push!(data,data_out)
                    end
                end
            end
        end
    end
    return nothing
end

# Prepare data for training
function prepare_training_data_main(training::Training,training_data::Training_data,
    model_data::Model_data,progress::RemoteChannel,results::RemoteChannel)
    # Return of features are empty
    if isempty(model_data.features)
        @info "Empty features"
        return nothing
    elseif isempty(training_data.url_input)
        @info "Empty urls"
        return nothing
    end
    # Initialize
    features = model_data.features
    options = training.Options
    min_fr_pix = options.Processing.min_fr_pix
    num_angles = options.Processing.num_angles
    border_num_pixels = options.Processing.border_num_pixels
    # Get output image size for dimensions 1 and 2
    pix_num = model_data.input_size[1:2]
    # Get feature data
    labels_color,labels_incl,border,border_thickness = get_feature_data(features)
    # Load images and labels
    imgs = load_images(training_data.url_input)
    labels = load_images(training_data.url_labels)
    # Get number of images
    num = length(imgs)
    # Initialize accumulators
    data = Vector{Tuple{Array{Float32,3},BitArray{3}}}(undef,0)
    # Return progress target value
    put!(progress, num+1)
    # Make imput images
    @threads for k = 1:num
        # Abort if requested
        if isready(channels.training_data_modifiers)
            if fetch(channels.training_data_modifiers)[1]=="stop"
                take!(channels.training_data_modifiers)
                return nothing
            end
        end
        # Get current image and label
        img = imgs[k]
        label = labels[k]
        # Convert to grayscale
        img = image_to_gray_float(img)
        # Crope to remove black background
        # img,label = correct_view(img,label)
        # Convert BitArray labels to Array{Float32}
        label = label_to_bool(label,labels_color,labels_incl,border,border_thickness)
        # Augment images
        augment!(data,img,label,num_angles,pix_num,min_fr_pix)
        # Return progress
        put!(progress, 1)
    end
    # Flatten input images and labels array
    data_input = getfield.(data, 1)
    data_labels = getfield.(data, 2)
    # Return results
    put!(results, (data_input,data_labels))
    # Return progress
    put!(progress, 1)
    return nothing
end

# Wrapper allowing for remote execution
function prepare_training_data_main2(training::Training,training_data::Training_data,
    model_data::Model_data,progress::RemoteChannel,results::RemoteChannel)
    @everywhere training,training_data,model_data
    remote_do(prepare_training_data_main,workers()[end],training,training_data,
    model_data,progress,results)
end
prepare_training_data() = prepare_training_data_main2(training,training_data,
    model_data,channels.training_data_progress,channels.training_data_results)

# Creates data sets for training and testing
function get_train_test(training_plot_data::Training_plot_data,training::Training)
    # Get inputs and labels
    data_input = training_plot_data.data_input
    data_labels = convert(Vector{Array{Float32,3}},training_plot_data.data_labels)
    # Get the number of elements
    num = length(data_input)
    # Get shuffle indices
    inds = randperm(num)
    # Shuffle using randomized indices
    data_input = data_input[inds]
    data_labels = data_labels[inds]
    # Get fraction of data used for testing
    test_fraction = training.Options.General.test_data_fraction
    # Get index after which all data is for testing
    ind = Int64(round((1-test_fraction)*num))
    # Separate data into training and testing data
    train_set = (data_input[1:ind],data_labels[1:ind])
    test_set = (data_input[ind+1:end],data_labels[ind+1:end])
    return train_set, test_set
end

# Creates a minibatch
function make_minibatch_inds(num_data::Int64,batch_size::Int64)
    # Calculate final index
    num = num_data - batch_size
    val = Int64(max(0.0,floor(num/batch_size)))
    finish = val*batch_size
    # Get indices
    inds_start = collect(0:batch_size:finish)
    inds_all = collect(1:num_data)
    # Number of indices
    num = length(inds_start)
    return inds_start,inds_all,num
end

function make_minibatch(data_input::Vector{Array{Float32,3}},data_labels::Vector{Array{Float32,3}},
        batch_size::Int64,inds_start::Vector{Int64},inds_all::Vector{Int64},i::Int64)
    ind = inds_start[i]
    # First and last minibatch indices
    ind1 = ind+1
    ind2 = ind+batch_size
    # Get inputs and labels
    current_inds = inds_all[ind1:ind2]
    current_input = data_input[current_inds]
    current_labels = data_labels[current_inds]
    # Catenating inputs and labels
    current_input_cat = reduce(cat4,current_input)[:,:,:,:]
    current_labels_cat = reduce(cat4,current_labels)[:,:,:,:]
    # Form a minibatch
    minibatch = (current_input_cat,current_labels_cat)
    return minibatch
end

#---

# Reset training related data accumulators
function reset_training_data(training_plot_data::Training_plot_data,
        training_results_data::Training_results_data)
    training_results_data.accuracy = Float32[]
    training_results_data.loss = Float32[]
    training_results_data.test_accuracy = Float32[]
    training_results_data.test_loss = Float32[]
    training_plot_data.iteration = 0
    training_plot_data.epoch = 0
    training_plot_data.iterations_per_epoch = 0
    training_plot_data.starting_time = now()
    return nothing
end

#---

# Returns an optimiser with preset parameters
function get_optimiser(training::Training)
    # List of possible optimisers
    optimisers = (Descent,Momentum,Nesterov,RMSProp,ADAM,
        RADAM,AdaMax,ADAGrad,ADADelta,AMSGrad,NADAM,ADAMW)
    # Get optimiser index
    optimiser_ind = training.Options.Hyperparameters.optimiser[2]
    # Get optimiser parameters
    parameters_in =
        training.Options.Hyperparameters.optimiser_params[optimiser_ind]
    # Get learning rate
    learning_rate = training.Options.Hyperparameters.learning_rate
    # Collect optimiser parameters and learning rate
    if length(parameters_in)==0
        parameters = [learning_rate]
    elseif length(parameters_in)==1
        parameters = [learning_rate,parameters_in[1]]
    elseif length(parameters_in)==2
        parameters = [learning_rate,(parameters_in[1],parameters_in[2])]
    else
        parameters = [learning_rate,(parameters_in[1],parameters_in[2]),parameters_in[3]]
    end
    # Get optimiser function
    optimiser_func = optimisers[optimiser_ind]
    # Initialize optimiser with parameters
    optimiser = optimiser_func(parameters...)
    return optimiser
end

#---
function minibatch_part(data_input,data_labels,epochs,num,inds_start,inds_all,
        counter,run_test,data_input_test,data_labels_test,inds_start_test,
        inds_all_test,counter_test,batch_size,minibatch_channel,abort)
    epoch_idx = 1
    iteration_local = 0
    iteration_test_local = 0
    # Data preparation
    while epoch_idx<=epochs[]
        # Shuffle indices
        inds_start_sh = shuffle!(inds_start)
        inds_all_sh = shuffle!(inds_all)
        if run_test
            inds_start_test_sh = shuffle!(inds_start_test)
            inds_all_test_sh = shuffle!(inds_all_test)
        end
        for i=1:num
            #@info "Iteration DP" i
            iteration_local+=1
            while true
                numel_channel = (iteration_local-counter.iteration)
                if numel_channel<50
                    minibatch = make_minibatch(data_input,data_labels,batch_size,
                        inds_start_sh,inds_all_sh,i)
                    put!(minibatch_channel,minibatch)
                    break
                else
                    sleep(0.01)
                end
            end
            if run_test && iteration_test_local!=num_test
                numel_test_channel = (iteration_test_local-counter_test.iteration)
                if numel_test_channel<1
                    iteration_test_local+=1
                    minibatch = make_minibatch(data_input_test,data_labels_test,batch_size,
                        inds_start_test_sh,inds_all_test_sh,i)
                end
            end
            if abort[]
                @info "Aborted"
                return
            end
        end
        # Update epoch counter
        epoch_idx += 1
    end
    return nothing
end

function check_modifiers(model_data,model,model_name,accuracy_vector,
        loss_vector,allow_lr_change,composite,opt,num,epochs,max_iterations,
        testing_frequency,modifiers_channel,abort;gpu=false) 
    while isready(modifiers_channel)
        modifs = fix_QML_types(take!(modifiers_channel))
        modif1::String = modifs[1]
        if modif1=="stop"
            Threads.atomic_xchg!(abort, true)
            # Save model
            if gpu==true
                model_data.model = move(model,cpu)
            else
                model_data.model = model
            end
            save_model_main(model_data,model_name)
            @info "Aborted"
            break
        elseif modif1=="learning rate"
            if allow_lr_change
                if composite
                    opt[1].eta = convert(Float64,modifs[2])
                else
                    opt.eta = convert(Float64,modifs[2])
                end
            end
        elseif modif1=="epochs"
            new_epochs::Int64 = convert(Int64,modifs[2])
            new_max_iterations::Int64 = convert(Int64,new_epochs*num)
            Threads.atomic_xchg!(epochs, new_epochs)
            Threads.atomic_xchg!(max_iterations, new_max_iterations)
            resize!(accuracy_vector,max_iterations[])
            resize!(loss_vector,max_iterations[])
        elseif modif1=="testing frequency"
            new_frequency_times::Float64 = modifs[2]
            testing_frequency::Float64 = convert(Float64,floor(num/new_frequency_times))
        end
    end
    return testing_frequency
end

# Training on CPU
function training_part_CPU(model_data,model_name,opt,accuracy,loss,
    accuracy_vector,loss_vector,counter,accuracy_test_vector,
    loss_test_vector,iteration_test_vector,counter_test,epochs,num,
    max_iterations,testing_frequency,allow_lr_change,composite,
    run_test,minibatch_channel,channels,abort)
    local loss_val::Float32
    local predicted::Array{Float32,4}
    epoch_idx = 1
    # Prepare model
    model = model_data.model
    while epoch_idx<=epochs[]
        for i=1:num
            #@info "Iteration T" i
            # Prepare training data
            local minibatch_data::Tuple{Array{Float32,4},Array{Float32,4}}
            while true
                # Update parameters or abort if needed
                if isready(channels.training_modifiers)
                    testing_frequency = check_modifiers(model_data,model,model_name,
                        accuracy_vector,loss_vector,allow_lr_change,composite,opt,num,epochs,
                        max_iterations,testing_frequency,channels.training_modifiers,abort;gpu=false)
                    if abort[]==true
                        return nothing
                    end
                end
                if isready(minibatch_channel)
                    minibatch_data = take!(minibatch_channel)
                    break
                else
                    sleep(0.01)
                end
            end
            counter()
            iteration = counter.iteration
            input_data = minibatch_data[1]
            actual = minibatch_data[2]
            # Calculate gradient
            ps = Flux.Params(Flux.params(model))
            gs = gradient(ps) do
                predicted = model(input_data)
                loss_val = loss(predicted,actual)
            end
            # Update weights
            Flux.Optimise.update!(opt,ps,gs)
            # Calculate accuracy
            accuracy_val::Float32 = accuracy(predicted,actual)
            # Return training information
            put!(channels.training_progress,["Training",accuracy_val,loss_val])
            accuracy_vector[iteration] = accuracy_val
            loss_vector[iteration] = loss_val
            # Testing part
            if run_test
                testing_frequency_cond::Bool = ceil(i/testing_frequency)>counter_test.iteration
                training_finished_cond = iteration==(max_iterations[]-1)
                # Test if testing frequency reached or training is done
                if testing_frequency_cond || training_finished_cond
                    # Update test counter
                    counter_test()
                    # Calculate test accuracy and loss
                    data_test = test_CPU(model,accuracy,loss,test_batches,num_test)
                    # Return testing information
                    put!(channels.training_progress,["Testing",data_test...,iteration])
                    push!(accuracy_test_vector,data_test[1])
                    push!(loss_test_vector,data_test[2])
                    push!(iteration_test_vector,iteration)
                end
            end
            GC.safepoint()
        end
        # Update epoch counter
        epoch_idx += 1
        # Save model
        save_model_main(model_data,model_name)
    end
    return nothing
end


# Training on GPU
function training_part_GPU(model_data,model_name,opt,accuracy,loss,
        accuracy_vector,loss_vector,counter,accuracy_test_vector,
        loss_test_vector,iteration_test_vector,counter_test,epochs,num,
        max_iterations,testing_frequency,allow_lr_change,composite,
        run_test,minibatch_channel,channels,abort)
    local loss_val::Float32
    local predicted::CuArray{Float32,4}
    epoch_idx = 1
    # Prepare model
    model = model_data.model
    model = move(model,gpu)
    while epoch_idx<=epochs[]
        for i=1:num
            #@info "Iteration T" i
            # Prepare training data
            local minibatch_data::Tuple{Array{Float32,4},Array{Float32,4}}
            while true
                # Update parameters or abort if needed
                if isready(channels.training_modifiers)
                    testing_frequency = check_modifiers(model_data,model,model_name,
                        accuracy_vector,loss_vector,allow_lr_change,composite,opt,num,epochs,
                        max_iterations,testing_frequency,channels.training_modifiers,abort;gpu=true)
                    if abort[]==true
                        return nothing
                    end
                end
                if isready(minibatch_channel)
                    minibatch_data = take!(minibatch_channel)
                    break
                else
                    sleep(0.01)
                end
            end
            counter()
            iteration = counter.iteration
            input_data = CuArray(minibatch_data[1])
            actual = CuArray(minibatch_data[2])
            # Calculate gradient
            ps = Flux.Params(Flux.params(model))
            gs = gradient(ps) do
                predicted = model(input_data)
                loss_val = loss(predicted,actual)
            end
            # Update weights
            Flux.Optimise.update!(opt,ps,gs)
            # Calculate accuracy
            accuracy_val::Float32 = accuracy(predicted,actual)
            # Return training information
            put!(channels.training_progress,["Training",accuracy_val,loss_val])
            accuracy_vector[iteration] = accuracy_val
            loss_vector[iteration] = loss_val
            # Needed to avoid GPU out of memory issue
            CUDA.unsafe_free!(predicted)
            # Testing part
            if run_test
                testing_frequency_cond::Bool = ceil(i/testing_frequency)>counter_test.iteration
                training_finished_cond = iteration==(max_iterations[]-1)
                # Test if testing frequency reached or training is done
                if testing_frequency_cond || training_finished_cond
                    # Update test counter
                    counter_test()
                    # Calculate test accuracy and loss
                    data_test = test_GPU(model,accuracy,loss,test_batches,num_test)
                    # Return testing information
                    put!(channels.training_progress,["Testing",data_test...,iteration])
                    push!(accuracy_test_vector,data_test[1])
                    push!(loss_test_vector,data_test[2])
                    push!(iteration_test_vector,iteration)
                end
            end
            GC.safepoint()
        end
        # Update epoch counter
        epoch_idx += 1
        # Save model
        model_data.model = move(model,cpu)
        save_model_main(model_data,model_name)
    end
    return nothing
end

function train!(model_data::Model_data,training::Training,
        args::Hyperparameters_training,opt,accuracy::Function,loss::Function,
        train_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        test_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        testing_times::Float64,use_GPU::Bool,channels::Channels)
    # Initialize constants
    epochs = Threads.Atomic{Int64}(args.epochs)
    batch_size = args.batch_size
    accuracy_vector = Vector{Float32}(undef,0)
    loss_vector = Vector{Float32}(undef,0)
    accuracy_test_vector = Vector{Float32}(undef,0)
    loss_test_vector = Vector{Float32}(undef,0)
    iteration_test_vector = Vector{Int64}(undef,0)
    max_iterations = Threads.Atomic{Int64}(0)
    counter = Counter()
    counter_test = Counter()
    run_test = length(test_set[1])!=0
    composite = hasproperty(opt, :os)
    if !composite
        allow_lr_change = hasproperty(opt, :eta)
    else
        allow_lr_change = hasproperty(opt[1], :eta)
    end
    abort = Threads.Atomic{Bool}(false)
    model_name = string("models/",training.name,".model")
    # Initialize data
    data_out = 
    data_input = train_set[1]
    data_labels = train_set[2]
    num_data = length(data_input)
    inds_start,inds_all,num = make_minibatch_inds(num_data,batch_size)
    testing_frequency = num/testing_times
    data_input_test = test_set[1]
    data_labels_test = test_set[2]
    num_data_test = length(data_input_test)
    inds_start_test,inds_all_test,num_test = make_minibatch_inds(num_data_test,batch_size)
    Threads.atomic_xchg!(max_iterations, epochs[]*num)
    # Return epoch information
    resize!(accuracy_vector,max_iterations[])
    resize!(loss_vector,max_iterations[])
    put!(channels.training_progress,[epochs[],num,max_iterations[]])
    # Make channels
    minibatch_channel = Channel{Tuple{Array{Float32,4},Array{Float32,4}}}(Inf)
    minibatch_test_channel = Channel{Tuple{Array{Float32,4},Array{Float32,4}}}(Inf)
    # Data preparation thread
    Threads.@spawn minibatch_part(data_input,data_labels,epochs,num,inds_start,
        inds_all,counter,run_test,data_input_test,data_labels_test,inds_start_test,
        inds_all_test,counter_test,batch_size,minibatch_channel,abort)
    # Training thread
    inputs = (model_data,model_name,opt,accuracy,loss,accuracy_vector,
        loss_vector,counter,accuracy_test_vector,loss_test_vector,iteration_test_vector,
        counter_test,epochs,num,max_iterations,testing_frequency,allow_lr_change,composite,
        run_test,minibatch_channel,channels,abort)
    if use_GPU
        training_part_GPU(inputs...)
    else
        training_part_CPU(inputs...)
    end
    # Return training information
    resize!(accuracy_vector,counter.iteration)
    resize!(loss_vector,counter.iteration)
    data = (accuracy_vector,loss_vector,accuracy_test_vector,loss_test_vector,iteration_test_vector)
    return data
end

# Testing on CPU
function test_CPU(model::Chain,accuracy::Function,loss::Function,
        test_batches::Array{Tuple{Array{Float32,4},Array{Float32,4}},1},num_test::Int64)
    test_accuracy = Vector{Float32}(undef,num_test)
    test_loss = Vector{Float32}(undef,num_test)
    for j=1:num_test
        test_minibatch = test_batches[j]
        predicted = model(test_minibatch[1])
        actual = test_minibatch[2]
        test_accuracy[j] = accuracy(predicted,actual)
        test_loss[j] = loss(predicted,actual)
    end
    data = [mean(test_accuracy),mean(test_loss)]
    return data
end

# Testing on GPU
function test_GPU(model::Chain,accuracy::Function,loss::Function,
        test_batches::Array{Tuple{Array{Float32,4},Array{Float32,4}},1},num_test::Int64)
    test_accuracy = Vector{Float32}(undef,num_test)
    test_loss = Vector{Float32}(undef,num_test)
    for j=1:num_test
        test_minibatch = CuArray.(test_batches[j])
        predicted = model(test_minibatch[1])
        actual = test_minibatch[2]
        test_accuracy[j] = accuracy(predicted,actual)
        test_loss[j] = loss(predicted,actual)
    end
    data = [mean(test_accuracy),mean(test_loss)]
    return data
end

# Main training function
function train_main(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    # Initialization
    GC.gc()
    training = settings.Training
    training_options = training.Options
    training_plot_data = training_data.Plot_data
    training_results_data = training_data.Results_data
    args = training_options.Hyperparameters
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    reset_training_data(training_plot_data,training_results_data)
    # Preparing train and test sets
    train_set, test_set = get_train_test(training_plot_data,training)
    # Setting functions and parameters
    opt = get_optimiser(training)
    accuracy = get_accuracy_func(training)
    loss = model_data.loss
    learning_rate = args.learning_rate
    epochs = args.epochs
    testing_times = training_options.General.testing_frequency
    # Check whether user wants to abort
    if isready(channels.training_modifiers)
        stop_cond::String = fetch(channels.training_modifiers)[1]
        if stop_cond=="stop"
            take!(channels.training_modifiers)
            return nothing
        end
    end
    # Run training
    data = train!(model_data,training,args,opt,accuracy,loss,
        train_set,test_set,testing_times,use_GPU,channels)
    # Clean up
    results_data = training_data.Results_data
    empty!(results_data.loss)
    empty!(results_data.accuracy)
    empty!(results_data.test_loss)
    empty!(results_data.test_accuracy)
    empty!(results_data.test_iteration)
    # Return training results
    put!(channels.training_results,(model_data.model,data...))
    return nothing
end
function train_main2(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    @everywhere settings,training_data,model_data
    remote_do(train_main,workers()[end],settings,training_data,model_data,channels)
end
train() = train_main2(settings,training_data,model_data,channels)
