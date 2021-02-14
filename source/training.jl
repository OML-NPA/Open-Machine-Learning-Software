
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
function make_minibatch(set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        batch_size::Int64)
    # Calculate final index
    num = length(set[1]) - batch_size
    val = max(0.0,floor(num/batch_size))
    finish = Int64(val*batch_size)
    # Get a vector of initial-1 indices
    range_array = collect(0:batch_size:finish)
    # Shuffle indices
    inds = shuffle!(range_array)
    # Separate set into inputs and labels
    data_input = set[1]
    data_labels = set[2]
    # Initialize accumulator for minibatches
    num = length(inds)
    set_minibatch = Vector{Tuple{Array{Float32,4},
        Array{Float32,4}}}(undef,num)
    @threads for i=1:num
        ind = inds[i]
        # First and last minibatch indices
        ind1 = ind+1
        ind2 = ind+batch_size
        # Get inputs and labels
        current_input = data_input[ind1:ind2]
        current_labels = data_labels[ind1:ind2]
        # Catenating inputs and labels
        current_input_cat = reduce(cat4,current_input)
        current_labels_cat = reduce(cat4,current_labels)
        # Form a minibatch
        minibatch = (current_input_cat,current_labels_cat)
        set_minibatch[i] = minibatch
    end
    return set_minibatch
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
# Training on CPU
function train_CPU!(model_data::Model_data,training::Training,accuracy::Function,
        loss::Function,args::Hyperparameters_training,testing_frequency::Float64,
        train_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        test_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        opt,channels::Channels)
    # Initialize
    epochs = args.epochs
    batch_size = args.batch_size
    accuracy_vector = Vector{Float32}(undef,0)
    loss_vector = Vector{Float32}(undef,0)
    test_accuracy = Vector{Float32}(undef,0)
    test_loss = Vector{Float32}(undef,0)
    test_iteration = Vector{Int64}(undef,0)
    max_iterations = 0
    iteration = 1
    epoch_idx = 1
    num_test = length(test_set[1])
    run_test = num_test!=0
    model = model_data.model
    name = string("models/",training.name,".model")
    composite = hasproperty(opt, :os)
    if !composite
        allow_lr_change = hasproperty(opt, :eta)
    else
        allow_lr_change = hasproperty(opt[1], :eta)
    end
    # Initialize so we get them returned by the gradient function
    local loss_val::Float32
    local predicted::Array{Float32,4}
    # Run training for n epochs
    while epoch_idx<epochs
        # Make minibatches
        run_test = num_test!=0
        train_batches = make_minibatch(train_set,batch_size)
        if run_test
            test_batches = make_minibatch(test_set,batch_size)
            num_test = length(test_batches)
        else
            test_batches = Vector{Tuple{Array{Float32,4},Array{Float32,4}}}(undef,0)
        end
        num = length(train_batches)
        # Return epoch information
        if epoch_idx==1
            testing_frequency = num/testing_frequency
            max_iterations = epochs*num
            resize!(accuracy_vector,max_iterations)
            resize!(loss_vector,max_iterations)
            put!(channels.training_progress,[epochs,num,max_iterations])
        end
        last_test = 0
        # Run iteration
        for i=1:num
            # Abort or update parameters if needed
            if isready(channels.training_modifiers)
                modifs::Union{Vector{String},Vector{String,Float64},
                    Vector{String,Int64}} = fix_QML_types(take!(channels.training_modifiers))
                while isready(channels.training_modifiers)
                    modifs = fix_QML_types(take!(channels.training_modifiers))
                end
                modif1::String = modifs[1]
                if modif1=="stop"
                    data = (accuracy_vector,loss_vector,
                        test_accuracy,test_loss,test_iteration)
                    return data
                elseif modif1=="learning rate"
                    if allow_lr_change
                        if composite
                            opt[1].eta = convert(Float64,modifs[2])
                        else
                            opt.eta = convert(Float64,modifs[2])
                        end
                    end
                elseif modif1=="epochs"
                    epochs::Int64 = convert(Int64,modifs[2])
                elseif modif1=="testing frequency"
                    testing_frequency::Int64 = convert(Int64,floor(num/modifs[2]))
                end
            end
            # Prepare training data
            train_minibatch = train_batches[i]
            input_data = train_minibatch[1]
            actual = train_minibatch[2]
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
                testing_frequency_cond = ceil(i/testing_frequency)>last_test
                training_finished_cond = iteration==(max_iterations-1)
                # Test if testing frequency reached or training is done
                if testing_frequency_cond || training_finished_cond
                    # Calculate test accuracy and loss
                    data_test = test_CPU(model,accuracy,loss,test_batches,num_test)
                    # Return testing information
                    put!(channels.training_progress,["Testing",data_test...,iteration])
                    push!(test_accuracy,data_test[1])
                    push!(test_loss,data_test[2])
                    push!(test_iteration,iteration)
                    # Update test counter
                    last_test += 1
                end
            end
            # Update iteration counter
            iteration+=1
            # Needed to avoid out of memory issue
            @everywhere GC.safepoint()
        end
        # Update epoch counter
        epoch_idx += 1
        # Save model
        model_data.model = model
        save_model_main(model_data,name)
        # Needed to avoid out of memory issue
        empty!(train_batches)
        empty!(test_batches)
        @everywhere GC.gc()
    end
    # Return training information
    accuracy_vector = accuracy_vector[1:iteration]
    loss_vector = loss_vector[1:iteration]
    data = (accuracy_vector,loss_vector,test_accuracy,test_loss,test_iteration)
    return data
end

# Training on GPU
function train_GPU!(model_data::Model_data,training::Training,accuracy::Function,
        loss::Function,args::Hyperparameters_training,testing_frequency::Float64,
        train_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        test_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        opt,channels::Channels)
    # Initialize
    epochs = args.epochs
    batch_size = args.batch_size
    accuracy_vector = Vector{Float32}(undef,0)
    loss_vector = Vector{Float32}(undef,0)
    test_accuracy = Vector{Float32}(undef,0)
    test_loss = Vector{Float32}(undef,0)
    test_iteration = Vector{Int64}(undef,0)
    max_iterations = 0
    iteration = 1
    epoch_idx = 1
    run_test = num_test!=0
    model = model_data.model
    model = move(model,gpu)
    name = string("models/",training.name,".model")
    composite = hasproperty(opt, :os)
    if !composite
        allow_lr_change = hasproperty(opt, :eta)
    else
        allow_lr_change = hasproperty(opt[1], :eta)
    end
    # Initialize so we get them returned by the gradient function
    local loss_val::Float32
    local predicted::CuArray{Float32,4}
    # Run training for n epochs
    while epoch_idx<=epochs
        # Make minibatches
        train_batches = make_minibatch(train_set,batch_size)
        if run_test
            test_batches = make_minibatch(test_set,batch_size)
            num_test = length(test_batches)
        else
            test_batches = Vector{Tuple{Array{Float32,4},Array{Float32,4}}}(undef,0)
        end
        num = length(train_batches)
        last_test = 0
        # Return epoch information
        if epoch_idx==1
            testing_frequency = num/testing_frequency
            max_iterations = epochs*num
            resize!(accuracy_vector,max_iterations)
            resize!(loss_vector,max_iterations)
            put!(channels.training_progress,[epochs,num,max_iterations])
        end
        # Run iteration
        for i=1:num
            # Abort or update parameters if needed
            if isready(channels.training_modifiers)
                modifs = fix_QML_types(take!(channels.training_modifiers))
                while isready(channels.training_modifiers)
                    modifs = fix_QML_types(take!(channels.training_modifiers))
                end
                modif1::String = modifs[1]
                if modif1=="stop"
                    data = (accuracy_vector,loss_vector,
                        test_accuracy,test_loss,test_iteration)
                    return data
                elseif modif1=="learning rate"
                    if allow_lr_change
                        if composite
                            opt[1].eta = convert(Float64,modifs[2])
                        else
                            opt.eta = convert(Float64,modifs[2])
                        end
                    end
                elseif modif1=="epochs"
                    epochs::Int64 = convert(Int64,modifs[2])
                    max_iterations = epochs*num
                    resize!(accuracy_vector,max_iterations)
                    resize!(loss_vector,max_iterations)
                elseif modif1=="testing frequency"
                    testing_frequency::Float64 = floor(num/modifs[2])
                end
            end
            # Prepare training data
            train_minibatch = CuArray.(train_batches[i])
            input_data = train_minibatch[1]
            actual = train_minibatch[2]
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
                testing_frequency_cond = ceil(i/testing_frequency)>last_test
                training_finished_cond = iteration==(max_iterations-1)
                # Test if testing frequency reached or training is done
                if testing_frequency_cond || training_finished_cond
                    # Calculate test accuracy and loss
                    data_test = test_GPU(model,accuracy,loss,test_batches,num_test)
                    # Return testing information
                    put!(channels.training_progress,["Testing",data_test...,iteration])
                    push!(test_accuracy,data_test[1])
                    push!(test_loss,data_test[2])
                    push!(test_iteration,iteration)
                    # Update test counter
                    last_test += 1
                end
            end
            # Update iteration counter
            iteration+=1
            # Needed to avoid GPU out of memory issue
            @everywhere GC.safepoint()
        end
        # Update epoch counter
        epoch_idx += 1
        # Save model
        model_data.model = move(model,cpu)
        save_model_main(model_data,name)
        # Clean up
        empty!(train_batches)
        empty!(test_batches)
        # Needed to avoid GPU out of memory issue
        @everywhere GC.gc()
    end
    # Return training information
    accuracy_vector = accuracy_vector[1:iteration]
    loss_vector = loss_vector[1:iteration]
    data = (accuracy_vector,loss_vector,test_accuracy,test_loss,test_iteration)
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
    testing_frequency = training_options.General.testing_frequency
    # Check whether user wants to abort
    if isready(channels.training_modifiers)
        stop_cond::String = fetch(channels.training_modifiers)[1]
        if stop_cond=="stop"
            take!(channels.training_modifiers)
            return nothing
        end
    end
    # Run training
    if use_GPU
        data = train_GPU!(model_data,training,accuracy,loss,args,
            testing_frequency,train_set,test_set,opt,channels)
    else
        data = train_CPU!(model_data,training,accuracy,loss,args,
            testing_frequency,train_set,test_set,opt,channels)
    end
    # Clean up
    empty!(training_plot_data.data_input)
    empty!(training_plot_data.data_labels)
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
