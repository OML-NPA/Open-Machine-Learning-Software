
using Flux, Random
using Printf, BSON
using Parameters: @with_kw
using CUDAapi
if has_cuda()
    #@info "CUDA is on"
    import CUDA
    CUDA.allowscalar(false)
end

types = ["segmentation","classification","regression"]

function get_train_test(data_input, data_labels,args)
    set = [(data_input[i],data_labels[i]) for i in 1:length(data)]
    ind = Int64(round(0.8*length(set)))
    train_set = set[1:ind]
    test_set = set[ind+1:end]
    return train_set, test_set
end

function make_minibatch(set,batch_size)
    set_minibatch = []
    finish = Int64(floor(length(set)/batch_size)*batch_size)-1
    inds = shuffle!([0:batch_size:finish...])
    for i=0:batch_size:finish
        push!(set_minibatch,set[i+1:(i+10)])
    end
    return set_minibatch
end


# Build model
function build_model(args; imgsize = (28,28,1), nclasses = 10)
    cnn_output_size = Int.(floor.([imgsize[1]/8,imgsize[2]/8,32]))

    return Chain(
    # First convolution, operating upon a 28x28 image
    Conv((3, 3), imgsize[3]=>16, pad = SamePad()),
    BatchNorm(32,relu),
    MaxPool((2,2)),

    # Second convolution, operating upon a 14x14 image
    Conv((3, 3), 16=>32, pad=SamePad()),
    BatchNorm(32relu),
    MaxPool((2,2)),

    # Third convolution, operating upon a 7x7 image
    Conv((3, 3), 32=>32, pad=SamePad()),
    BatchNorm(32,relu),
    MaxPool((2,2)),

    # Reshape 3d tensor into a 2d one using `Flux.flatten`, at this point it should be (3, 3, 32, N)
    flatten,
    Dense(prod(cnn_output_size), 10, hardsigmoid))
end

# We augment `x` a little bit here, adding in random noise.
augment(x) = x .+ gpu(0.1f0*randn(eltype(x), size(x)))

# Returns a vector of all parameters used in model
paramvec(m) = vcat(map(p->reshape(p, :), params(m))...)

# Function to check if any element is NaN or not
anynan(x) = any(isnan.(x))

#accuracy(x, y, model) = mean(onecold(cpu(model(x))) .== onecold(cpu(y)))

function accuracy(x, y, model)
    predicted = cpu(model(x))
    actual = cpu(y)

    #@info(predicted[1:10])
    @info(typeof(actual))
    @info(typeof(predicted))
    return 0
end

function train(data; kws...)
    args = Args(; kws...)

    @info("Loading data set")
    train_set, test_set = get_train_test(data,args)

    @info("Building model...")
    model = build_model(args)

    # Load model and datasets onto GPU, if enabled
    train_set = gpu.(train_set)
    if ~isempty(test_set)
        test_set = gpu.(test_set)
        test = true
    else
        test = false
    end
    model = gpu(model)

    # Make sure our model is nicely precompiled before starting our training loop
    model(train_set[1][1])

    # `loss()` calculates the crossentropy loss between our prediction `y_hat`
    # (calculated from `model(x)`) and the ground truth `y`.  We augment the data
    # a bit, adding gaussian random noise to our image to make it more robust.
    function loss(x, y)
        x̂ = augment(x)
        ŷ = model(x̂)
        return logitcrossentropy(ŷ, y)
    end

    # Train our model with the given training set using the ADAM optimizer and
    # printing out performance against the test set as we go.
    opt = ADAM(args.lr)

    @info("Beginning training loop...")
    best_acc = 0.0
    last_improvement = 0
    for epoch_idx in 1:args.epochs
        # Train for a single epoch
        Flux.train!(loss, params(model), train_set, opt)

        # Terminate on NaN
        if anynan(paramvec(model))
            @error "NaN params"
            break
        end

        # Calculate accuracy:
        if test==true
            acc = accuracy(test_set..., model)
        end

        #@info(@sprintf("[%d]: Test accuracy: %.4f", epoch_idx, acc))
        # If our accuracy is good enough, quit out.
        if acc >= 0.990
            @info(" -> Early-exiting: We reached our target accuracy of 99.9%")
            break
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
function test(; kws...)
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
