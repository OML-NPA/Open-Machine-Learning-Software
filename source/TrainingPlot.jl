
function training_elapsed_time_main(training)
  dif = (now() - DateTime(training.starting_time)).value
  hours = string(Int64(round(dif/3600000)))
  minutes = round(dif/60000)
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

function accuracy(predicted::Union{Array,CUDA.CuArray},
    actual::Union{Array,CUDA.CuArray})
  acc = 1-mean(mean.(map(x->abs.(x),predicted.-actual)))
  return acc
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


function train!(loss,model,train_batches,test_batches,opt,training)
  num = length(train_batches)
  num_test = length(test_batches)
  run_test = num_test!=0
  testing_frequency = training.Options.General.testing_frequency
  last_test = 0
  for i=1:num
    local temp_loss, predicted
    train_minibatch = train_batches[i]
    if use_GPU
      train_minibatch = gpu.(train_minibatch)
    end
    if master.Training.stop_training
      master.Training.stop_training = false
      master.Training.task_done = true
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
      if ceil(i/testing_frequency)>last_test
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
        last_test = last_test + 1
        push!(training.test_accuracy,mean(test_accuracy))
        push!(training.test_loss,mean(test_loss))
      end
    end
    training.iteration = training.iteration + 1
    push!(training.loss,cpu(temp_loss))
    push!(training.accuracy,cpu(accuracy(predicted,actual)))
    @info i
  end
  return nothing
end

function prepare_training_data_main(master)
  task = @async process_images_labels()
end
prepare_training_data() = prepare_training_data_main(master)

function reset_training_data(training::Training)
  training.accuracy = []
  training.loss = []
  training.test_accuracy = []
  training.test_loss = []
  training.iteration = 0
  training.epoch = 0
  training.iterations_per_epoch = 0
  training.starting_time = string(now())
  training.training_started = false
  return nothing
end

function train_main(master,model_data)
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
  # Load model and datasets onto GPU, if enabled
  use_GPU = master.Options.Hardware_resources.allow_GPU && has_cuda()
  if use_GPU
    model = gpu(model)
    loss = gpu(loss)
    precomp_data = gpu(precomp_data)
  end
  # Precompile model
  model(precomp_data)
  # Use ADAM optimiser
  opt = get_optimiser(training)
  reset_training_data(training)
  # Training loop
  for epoch_idx = 1:epochs
    training.epoch = training.epoch + 1
    if master.Training.stop_training
      master.Training.stop_training = false
      master.Training.task_done = true
      return nothing
    end
    # Make minibatches
    train_batches = make_minibatch(train_set,batch_size)
    test_batches = make_minibatch(test_set,batch_size)
    training.iterations_per_epoch = length(train_batches)
    training.max_iterations = epochs*training.iterations_per_epoch
    training.training_started = true
    # Train neural network returning loss
    train!(loss,model,train_batches,test_batches,opt,training)
  end
end
train() = @async train_main(master,model_data)
