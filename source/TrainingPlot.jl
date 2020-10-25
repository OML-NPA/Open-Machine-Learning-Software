
args = master.Training.Options.Hyperparameters

function get_train_test(training)
    data_input = training.data_input
    data_labels = training.data_labels
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

function accuracy(x, y, model)
    predicted = cpu(model.(x))
    actual = cpu(y)
    return 0
end

function train_main(master,model_data)
    training = master.Training
    model = model_data.model
    use_GPU = master.Options.Hardware_resources.allow_GPU && has_cuda()
    get_urls_imgs_labels()
    if isempty(training.url_imgs) ||
        isempty(training.url_labels) ||
        isempty(model_data.features)
        return false
    end
    process_images_labels()

    args = training.Options.Hyperparameters
    batch_size = args.batch_size
    learning_rate = args.learning_rate
    epochs = args.epochs
    @info("Loading data set")
    train_set, test_set = get_train_test(training)
    train_batches = make_minibatch(train_set,batch_size)
    test_batches = make_minibatch(test_set,batch_size)
    # Load model and datasets onto GPU, if enabled
    if use_GPU
        model = gpu(model)
    end
    # Precompile model
    model(train_set[1][1])

    # Train our model with the given training set using the ADAM optimizer and
    # printing out performance against the test set as we go.
    opt = ADAM(args.learning_rate)

    @info("Beginning training loop...")
    best_acc = 0.0
    last_improvement = 0
    for epoch_idx in 1:args.epochs
        # Train for a single epoch

        if use_GPU
            train_set = gpu.(train_set)
            if ~isempty(test_set)
                test_set = gpu.(test_set)
                test = true
            else
                test = false
            end
            model = gpu(model)
        end

        Flux.train!(model_data.loss, params(model), train_set, opt)

        # Terminate on NaN
        if anynan(paramvec(model))
            @error "NaN params"
            break
        end

        # Calculate accuracy:
        if test==true
            acc = accuracy(test_set, model)
        end

        # If this is the best accuracy we've seen so far, save the model out
        if acc >= best_acc
            @info(" -> New best accuracy! Saving model out to mnist_conv.bson")
            BSON.@save joinpath(args.savepath, "mnist_conv.bson") params=cpu.(params(model)) epoch_idx acc
            best_acc = acc
            last_improvement = epoch_idx
        end

        # If we haven't seen improvement in 5 epochs, drop our learning rate:
        if epoch_idx - last_improvement >= 5 && opt.eta > 1e-6
            opt.eta /= 10.0
            @warn(" -> Haven't improved in a while, dropping learning rate to $(opt.eta)!")

            # After dropping learning rate, give it a few epochs to improve
            last_improvement = epoch_idx
        end

        if epoch_idx - last_improvement >= 10
            @warn(" -> We're calling this converged.")
            break
        end
    end
end

# Testing the model, from saved model
function test_main(; kws...)
    args = Args(; kws...)

    # Loading the test data
    _,test_set = get_processed_data(args)

    # Re-constructing the model with random initial weights
    model = build_model(args)

    # Loading the saved parameters
    BSON.@load joinpath(args.savepath, "mnist_conv.bson") params

    # Loading parameters onto the model
    Flux.loadparams!(model, params)

    test_set = gpu.(test_set)
    model = gpu(model)
    @show accuracy(test_set...,model)
end

#cd(@__DIR__)
#train()
#test()
