
args = master.Training.Options.Hyperparameters

function get_train_test(training)
    data_input = training.data_input
    data_labels = convert.(Array{Float32},training.data_labels)
    test_fraction = training.Options.General.test_data_fraction
    set = (data_input,data_labels)
    ind = Int64(round((1-test_fraction)*length(data_input)))
    train_set = (data_input[1:ind],data_labels[1:ind])
    test_set = (data_input[ind+1:end],data_labels[ind+1:end])
    return train_set, test_set
end

function make_minibatch(set::Tuple,batch_size::Int64)
    finish = Int64(floor(length(set[1])/batch_size)*batch_size)
    inds = shuffle!([1:batch_size:finish...])
    dim = length(size(set[1][1]))+1
    data_input = set[1]
    data_labels = set[2]
    set_minibatch = Vector{Tuple}(undef,length(inds))
    for i=1:length(inds)
        ind = inds[i]
        current_input = data_input[ind+1:(ind+10)]
        current_labels = data_labels[ind+1:(ind+10)]
        minibatch = (cat(current_input...,dims=dim),
            cat(current_labels...,dims=dim))
        set_minibatch[i] = minibatch
    end
    return set_minibatch
end

function accuracy(data,model)
    num = length(data)
    predicted = Vector{Array{Float32}}(undef,num)
    actual = Vector{Array{Float32}}(undef,num)
    fill!(predicted,zeros(Float32,size(data[1][1])))
    fill!(predicted,zeros(Float32,size(data[1][1])))
    for i = 1:num
      predicted[i] = cpu(model(data[i][1]))
      actual[i] = Float32.(cpu(data[i][2]))
    end
    acc = mean(mean.(map(x->abs.(x),predicted.-actual)))
    return acc
end

function train!(loss, model, data, opt)
  num = length(data)
  ps = Params(params(model))
  training_loss = Vector{Float32}(undef,num)
  for i=1:num
    local temp_loss
    gs = gradient(ps) do
      temp_loss = loss(model(data[i][1]),data[i][2])
      return temp_loss
    end
    Flux.update!(opt, ps, gs)
    training_loss[i] = temp_loss
  end
  return mean(training_loss)
end

function prepare_training_data_main(master)
  master.Training.task = @async process_images_labels()
end
prepare_training_data() = prepare_training_data_main(master)

function train_main(master,model_data)
    training = master.Training
    model = model_data.model
    loss = model_data.loss
    use_GPU = false && master.Options.Hardware_resources.allow_GPU && has_cuda()

    args = training.Options.Hyperparameters
    batch_size = args.batch_size
    learning_rate = args.learning_rate
    epochs = args.epochs
    # Preparing train and test sets
    train_set, test_set = get_train_test(training)
    # Data for precompiling
    precomp_data = train_set[1][1][:,:,:,:]
    # Load model and datasets onto GPU, if enabled
    if use_GPU
        model = gpu(model)
        loss = gpu(loss)
        precomp_data = gpu(precomp_data)
    end
    # Precompile model
    model(precomp_data)

    # Use ADAM optimiser
    opt = ADAM(args.learning_rate)

    @info("Beginning training loop...")
    best_acc = 0.0
    last_improvement = 0
    # Training loop
    for epoch_idx = 1:epochs
        # Make minibatches
        train_batches = make_minibatch(train_set,batch_size)
        test_batches = make_minibatch(test_set,batch_size)
        # Load minibatches onto GPU if enabled
        if use_GPU
            train_batches = gpu.(train_batches)
            if ~isempty(test_set)
                test_set = gpu.(test_set)
                test = true
            else
                test = false
            end
        end
        # Train neural network returning loss
        push!(training.loss,train!(loss, model, train_batches, opt))
        # Calculate accuracy
        push!(training.accuracy,accuracy(train_batches, model))
    end
end
train() = train_main(master,model_data)
