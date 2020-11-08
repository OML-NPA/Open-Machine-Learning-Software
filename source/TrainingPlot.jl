
function training_elapsed_time_main(training)
    dif = (now() - DateTime(training.Training_plot.starting_time)).value
    hours = string(Int64(round(dif/3600000)))
    minutes = floor(dif/60000)
    minutes = string(Int64(minutes - floor(minutes/60)*60))
    if length(minutes)<2
        minutes = string("0",minutes)
    end
    seconds = round(dif/1000)
    seconds = string(Int64(seconds - floor(seconds/60)*60))
    if length(seconds)<2
        seconds = string("0",seconds)
    end
    return string(hours,":",minutes,":",seconds)
end
training_elapsed_time() = training_elapsed_time_main(training)


function get_train_test(training::Training;validation::Bool=false)
    if validation
        data_input = training.Validation_plot.data_input
        data_labels = convert.(Array{Float32},
            training.Validation_plot.data_labels)
        data_input = map(x->x[:,:,:,:],data_input)
        data_labels = map(x->x[:,:,:,:],data_labels)
        set = (data_input,data_labels)
        return set
    else
        data_input = training.Training_plot.data_input
        data_labels = convert.(Array{Float32},
            training.Training_plot.data_labels)
        num = length(data_input)
        inds = randperm(num)
        data_input = data_input[inds]
        data_labels = data_labels[inds]
        test_fraction = training.Options.General.test_data_fraction
        ind = Int64(round((1-test_fraction)*num))
        train_set = (data_input[1:ind],data_labels[1:ind])
        test_set = (data_input[ind+1:end],data_labels[ind+1:end])
        return train_set, test_set
    end
end

function make_minibatch(set::Tuple,batch_size::Int64)
    finish = Int64(floor(length(set[1])/batch_size)*batch_size)-batch_size
    inds = shuffle!([1:batch_size:finish...])
    dim = length(size(set[1][1]))+1
    data_input = set[1]
    data_labels = set[2]
    set_minibatch = Vector{Tuple}(undef,length(inds))
    Threads.@threads for i=1:length(inds)
        ind = inds[i]
        current_input = data_input[ind+1:(ind+10)]
        current_labels = data_labels[ind+1:(ind+10)]
        minibatch = (cat(current_input...,dims=dim),
              cat(current_labels...,dims=dim))
        set_minibatch[i] = minibatch
    end
    return set_minibatch
end

function accuracy(predicted::Union{Array,CuArray},
      actual::Union{Array,CuArray})
    acc = 1-mean(mean.(map(x->abs.(x),predicted.-actual)))
    return acc
end

function accuracy_validation(predicted::Union{Array,CuArray},
      actual::Union{Array,CuArray})
    dif = predicted.-actual
    acc = 1-mean(mean.(map(x->abs.(x),dif)))
    return acc, std(dif)
end

function get_optimiser(training)
    optimisers = [Descent,Momentum,Nesterov,RMSProp,ADAM,
        RADAM,AdaMax,ADAGrad,ADADelta,AMSGrad,NADAM,ADAMW]
    optimiser_ind = training.Options.Hyperparameters.optimiser[2]
    parameters = training.Options.Hyperparameters.
        optimiser_params[optimiser_ind]
    learning_rate = training.Options.Hyperparameters.learning_rate
    if length(parameters)==1
        parameters = [learning_rate,parameters[1]]
    elseif length(parameters)==2
        parameters = [learning_rate,(parameters[1],parameters[2])]
    elseif length(parameters)==3
        parameters = [learning_rate,(parameters[1],parameters[2]),parameters[3]]
    end
    optimiser = optimisers[optimiser_ind]
    return optimiser(parameters...)
end

function train!(model::Chain,loss,training::Training,train_batches::Array,
        test_batches::Array,opt,run_test::Bool,use_GPU)
    training.training_started = true
    num = length(train_batches)
    last_test = 0
    for i=1:num
        local temp_loss, predicted
        if training.Training_plot.learning_rate_changed
          opt.eta = training.Options.Hyperparameters.learning_rate
        end
        train_minibatch = train_batches[i]
        if use_GPU
        train_minibatch = gpu.(train_minibatch)
        end
        if training.stop_training
          training.stop_training = false
          training.task_done = true
          return nothing
        end
        actual = train_minibatch[2]
        predicted = []
        ps = Flux.Params(params(model))
        gs = gradient(ps) do
          predicted = model(train_minibatch[1])
          temp_loss = loss(predicted,actual)
          return temp_loss
        end
        Flux.Optimise.update!(opt,ps,gs)
        if run_test
          if ceil(i/training.Options.General.testing_frequency)>last_test
              test(model,loss,training,test_batches,length(test_batches),use_GPU)
              last_test = last_test + 1
          end
        end
        training.Training_plot.iteration = training.Training_plot.iteration + 1
        push!(training.Training_plot.loss,cpu(temp_loss))
        push!(training.Training_plot.accuracy,cpu(accuracy(predicted,actual)))
    end
    return nothing
end

function test(model::Chain,loss,training::Training,test_batches::Array,
    num_test::Int64,use_GPU::Bool)
    test_accuracy = Vector{Float32}(undef,num_test)
    test_loss = Vector{Float32}(undef,num_test)
    for j=1:num_test
        test_minibatch = test_batches[j]
        if use_GPU
            test_minibatch = gpu.(test_minibatch)
        end
        predicted = model(test_minibatch[1])
        actual = test_minibatch[2]
        test_accuracy[j] = cpu(accuracy(predicted,actual))
        test_loss[j] = cpu(loss(predicted,actual))
    end
    push!(training.Training_plot.test_accuracy,mean(test_accuracy))
    push!(training.Training_plot.test_loss,mean(test_loss))
end

function prepare_training_data_main(master)
    task = @async process_images_labels()
end
prepare_training_data() = prepare_training_data_main(master)

function prepare_validation_data_main(master,model_data)
    images = load_images()
    labels = load_labels()
    training.Validation_plot.data_input_orig = images
    training.Validation_plot.data_labels_orig = labels
    features = model_data.features
    if isempty(features)
        @info "empty features"
        return false
    end
    labels_color,labels_incl,border = get_feature_data(features)
    training.Validation_plot.data_input =
        map(x->image_to_float(x,gray=true),images)
    training.Validation_plot.data_labels =
        map(x->label_to_float(x,labels_color,labels_incl,border),labels)
    training.data_ready = [1]
    return nothing
end
prepare_validation_data() = @async prepare_validation_data_main(master,model_data)

function reset_training_data(training::Training)
    training.Training_plot.accuracy = []
    training.Training_plot.loss = []
    training.Training_plot.test_accuracy = []
    training.Training_plot.test_loss = []
    training.Training_plot.iteration = 0
    training.Training_plot.epoch = 0
    training.Training_plot.iterations_per_epoch = 0
    training.Training_plot.starting_time = string(now())
    return nothing
end

function reset_validation_data(training::Training)
    training.Validation_plot.accuracy = []
    training.Validation_plot.loss = []
    training.Validation_plot.loss_std = NaN
    training.Validation_plot.accuracy_std = NaN
    training.Validation_plot.accuracy_std_in = []
    training.Validation_plot.progress = 0
    return nothing
end

function move(model::Chain,target::Union{typeof(cpu),typeof(gpu)})
    model_moved = []
    for i = 1:length(model)
        if model[i] isa Parallel
            layers = (target.([model[i].layers...])...,)
            for i = 1:length(layers)
                if layers[i] isa Parallel
                    move(layers[i],target)
                end
            end
            push!(model_moved,Parallel(layers))
        else
            push!(model_moved,target(model[i]))
        end
    end
    model_moved = Chain(model_moved...)
    return model_moved
end

function train_main(master::Master,model_data::Model_data)
    training = master.Training
    model = model_data.model
    loss = model_data.loss
    args = training.Options.Hyperparameters
    batch_size = args.batch_size
    learning_rate = args.learning_rate
    epochs = args.epochs
    # Preparing train and test sets
    train_set, test_set = get_train_test(training)
    # Data for precompiling
    precomp_data = train_set[1][1][:,:,:,:]
    # Load model onto GPU, if enabled
    use_GPU = master.Options.Hardware_resources.allow_GPU && has_cuda()
    if use_GPU
        model = move(model,gpu)
        loss = gpu(loss)
        precomp_data = gpu(precomp_data)
    end
    reset_training_data(training)
    # Precompile model
    model(precomp_data)
    # Use ADAM optimiser
    opt = get_optimiser(training)
    # Training loop
    for epoch_idx = 1:epochs
        training.Training_plot.epoch = training.Training_plot.epoch + 1
        if master.Training.stop_training
            master.Training.stop_training = false
            master.Training.task_done = true
            return nothing
        end
        # Make minibatches
        num_test = length(test_set[1])
        run_test = num_test!=0
        train_batches = make_minibatch(train_set,batch_size)
        if run_test
            test_batches = make_minibatch(test_set,batch_size)
        else
            test_batches = []
        end
        training.Training_plot.iterations_per_epoch = length(train_batches)
        training.Training_plot.max_iterations =
            epochs*training.Training_plot.iterations_per_epoch
        # Train neural network
        train!(model,loss,training,train_batches,test_batches,opt,run_test,use_GPU)
    end
    if use_GPU
        model_data.model = move(model,cpu)
        save_model(string("models/",training.name,".model"))
    end
end
train() = @async train_main(master,model_data)

function output_and_error_images(predicted_array::Array{<:Array{<:AbstractFloat}},
        set::Tuple{Array{<:Array{<:AbstractFloat,4},1},Array{<:Array{<:AbstractFloat,4},1}})
    labels_color,labels_incl,border = get_feature_data(model_data.features)
    perm_labels_color = map(x -> permutedims(x[:,:,:]/255,[3,2,1]),labels_color)
    data_array = apply_border_data.(predicted_array)
    predicted_color = []
    predicted_error = []
    for i = 1:length(predicted_array)
        predicted_color_temp = []
        predicted_error_temp = []
        for j = 1:num_features()
            temp_bool = data_array[i][:,:,j].>0.5
            truth = set[2][i][:,:,j].>0
            correct = temp_bool .& truth
            false_pos = copy(temp_bool)
            false_pos[truth] .= false
            false_neg = copy(truth)
            false_neg[temp_bool] .= false
            error_img = zeros(Bool,(size(temp_bool)...,3))
            error_img[:,:,1:2] .= false_pos
            error_img[:,:,1] = error_img[:,:,1] .| false_neg
            error_img[:,:,2] = error_img[:,:,2] .| correct
            error_img = Float32.(permutedims(error_img,[3,1,2]))
            error_img = colorview(RGB,error_img)
            push!(predicted_error_temp,error_img)
            temp = Float32.(temp_bool)
            temp = cat(temp,temp,temp,dims=3)
            temp = temp.*perm_labels_color[j]
            temp = colorview(RGB,permutedims(temp,[3,1,2]))
            push!(predicted_color_temp,temp)
        end
        push!(predicted_color,predicted_color_temp)
        push!(predicted_error,predicted_error_temp)
    end
    validation_plot.data_predicted = predicted_color
    validation_plot.data_error = predicted_error
    return nothing
end

function validate_main(master::Master,model_data::Model_data)
    training = master.Training
    validation_plot = training.Validation_plot
    model = model_data.model
    loss_function = model_data.loss
    args = training.Options.Hyperparameters
    batch_size = args.batch_size
    learning_rate = args.learning_rate
    reset_validation_data(training)
    # Preparing set
    set = get_train_test(training,validation=true)
    # Data for precompiling
    precomp_data = set[1][1][:,:,:,:]
    # Load model onto GPU, if enabled
    use_GPU = master.Options.Hardware_resources.allow_GPU && has_cuda()
    if use_GPU
        model = move(model,gpu)
        loss = gpu(loss_function)
        precomp_data = gpu(precomp_data)
    end
    # Precompile model
    model(precomp_data)
    # Validate
    num = length(set[1])
    accuracy_array = Vector{Float32}(undef,num)
    predicted_array = Vector{Array{Float32}}(undef,num)
    loss_array = Vector{Float32}(undef,num)
    accuracy_std_in = Vector{Float32}(undef,num)
    training.validation_started = true
    for i = 1:num
        data = (set[1][i],set[2][i])
        if use_GPU
            data = gpu.(data)
        end
        predicted = model(data[1])
        actual = data[2]
        accuracy_array[i], accuracy_std_in[i] =
            cpu(accuracy_validation(predicted,actual))
        loss_array[i] = cpu(loss(predicted,actual))
        predicted_array[i] = cpu(predicted)
        validation_plot.progress = i/num
    end
    validation_plot.accuracy = loss_array
    validation_plot.loss = accuracy_array
    validation_plot.loss_std = std(loss_array)
    validation_plot.accuracy_std = std(accuracy_array)
    validation_plot.accuracy_std_in = accuracy_std_in
    output_and_error_images(predicted_array,set)
    validation_plot.validation_done = true
end
validate() = @async validate_main(master,model_data)
