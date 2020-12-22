
function prepare_training_data_main(training::Training,training_data::Training_data,
    model_data::Model_data,progress::RemoteChannel,results::RemoteChannel)
    # Code
    if isempty(model_data.features)
        put!(results, "Empty features")
    end
    features = model_data.features
    type = training.type
    options = training.Options
    min_fr_pix = options.Processing.min_fr_pix
    num_angles = options.Processing.num_angles
    pix_num = model_data.input_size[1:2]
    labels_color,labels_incl,border = get_feature_data(features)
    imgs = load_images(training_data)
    labels = load_labels(training_data)
    num = length(imgs)
    data_input = Vector{Vector{Array{Float32,3}}}(undef,num)
    data_labels = Vector{Vector{BitArray{3}}}(undef,num)
    put!(progress, num+1)
    Threads.@threads for k = 1:num
        if isready(channels.training_data_modifiers)
            if fetch(channels.training_data_modifiers)[1]=="stop"
                take!(channels.training_data_modifiers)
                return nothing
            end
        end
        img = imgs[k]
        img = image_to_gray_float(img)
        label = labels[k]
        #img,label = correct_view(img,label)
        label = label_to_float(label,labels_color,labels_incl,border)
        data_input[k],data_labels[k] = augment(k,img,label,num_angles,pix_num,min_fr_pix)
        put!(progress, 1)
    end
    data_out_input::Vector{Array{Float32,3}} = vcat(data_input...)
    data_out_labels::Vector{BitArray{3}} = vcat(data_labels...)
    put!(results, (data_out_input,data_out_labels))
    put!(progress, 1)
    return
end
function prepare_training_data_main2(training::Training,training_data::Training_data,
    model_data::Model_data,progress::RemoteChannel,results::RemoteChannel)
    @everywhere training,training_data,model_data
    remote_do(prepare_training_data_main,workers()[end],training,training_data,
    model_data,progress,results)
end
prepare_training_data() = prepare_training_data_main2(training,training_data,
    model_data,channels.training_data_progress,channels.training_data_results)

function set_training_starting_time_main(training_plot_data::Training_plot_data)
    training_plot_data.starting_time = now()
    return nothing
end
set_training_starting_time() =
    set_training_starting_time_main(training_plot_data)

function training_elapsed_time_main(training_plot_data::Training_plot_data)
    dif = (now() - training_plot_data.starting_time).value
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
training_elapsed_time() = training_elapsed_time_main(training_plot_data)

function get_train_test(training_plot_data::Training_plot_data,training::Training)
    data_input = training_plot_data.data_input
    data_labels = convert(Vector{Array{Float32,3}},training_plot_data.data_labels)
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

function make_minibatch(set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        batch_size::Int64)
    finish = Int64(floor(length(set[1])/batch_size)*batch_size)-batch_size
    range_array = Vector(1:batch_size:finish)
    inds = shuffle!(range_array)
    set_size = size(set[1][1])
    dim = length(set_size)+1
    data_input = set[1]
    data_labels = set[2]
    set_minibatch = Vector{Tuple{Array{Float32,4},
        Array{Float32,4}}}(undef,length(inds))
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

function accuracy_regular(predicted::Union{Array,CuArray},actual::Union{Array,CuArray})
    dif = predicted - actual
    acc = 1-mean(mean.(map(x->abs.(x),dif)))
    return acc
end

function accuracy_weighted(predicted::Union{Array{Float32,4},CuArray{Float32,4}},
        actual::Union{Array{Float32,4},CuArray{Float32,4}})
    num_feat = size(actual,3)
    num_batch = size(actual,4)
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    comp_bool = predicted_bool .& actual_bool
    dif_bool = xor.(predicted_bool,actual_bool)
    comp_background_bool = (!).(dif_bool .| actual_bool)
    dif_background_bool = dif_bool-actual_bool
    array_size = size(actual)[1:2]
    numel = prod(array_size)
    pix_sum = sum(actual_bool,dims=(1,2,4))[:]
    feature_counts = Vector{Int64}(undef,num_feat)
    if pix_sum isa CuArray
        feature_counts .= cpu(pix_sum)
    else
        feature_counts .= pix_sum
    end
    fr = feature_counts./numel./num_batch
    w = 1 ./fr
    w2 = 1 ./(1 .- fr)
    w_sum = w + w2
    w = w./w_sum
    w2 = w2./w_sum
    w_adj = w./feature_counts
    w2_adj = w2./(numel*num_batch .- feature_counts)
    features_correct = Vector{Float32}(undef,num_feat)
    background_correct = Vector{Float32}(undef,num_feat)
    for i = 1:num_feat
        sum_comp = sum(comp_bool[:,:,i,:])
        sum_dif = sum(dif_bool[:,:,i,:])
        sum_comb = sum_comp*sum_comp/(sum_comp+sum_dif)
        features_correct[i] = w_adj[i]*sum_comb
        sum_comp = sum(comp_background_bool[:,:,i,:])
        sum_dif = sum(dif_background_bool[:,:,i,:])
        sum_comb = sum_comp*sum_comp/(sum_comp+sum_dif)
        background_correct[i] = w2_adj[i]*sum_comb
    end
    acc = mean(features_correct+background_correct)
    if acc>1.0
        acc = 1.0f0
    end
    return acc
end

function get_accuracy_func(training::Training)
    if training.Options.General.weight_accuracy
        return accuracy_weighted
    else
        return accuracy_regular
    end
end

function get_optimiser(training::Training)
    optimisers = (Descent,Momentum,Nesterov,RMSProp,ADAM,
        RADAM,AdaMax,ADAGrad,ADADelta,AMSGrad,NADAM,ADAMW)
    optimiser_ind = training.Options.Hyperparameters.optimiser[2]
    parameters_in =
        training.Options.Hyperparameters.optimiser_params[optimiser_ind]
    learning_rate = training.Options.Hyperparameters.learning_rate
    if length(parameters_in)==1
        parameters = [learning_rate,parameters_in[1]]
    elseif length(parameters_in)==2
        parameters = [learning_rate,(parameters_in[1],parameters_in[2])]
    else
        parameters = [learning_rate,(parameters_in[1],parameters_in[2]),parameters_in[3]]
    end
    optimiser_func = optimisers[optimiser_ind]
    optimiser = optimiser_func(parameters...)
    return optimiser::Function
end

function train_CPU!(model::Chain,accuracy::Function,loss::Function,
        args::Hyperparameters_training,testing_frequency::Float64,
        train_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        test_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        opt,channels::Channels)
    # Training loop
    epochs = args.epochs
    batch_size = args.batch_size
    accuracy_array = Vector{Float32}(undef,0)
    loss_array = Vector{Float32}(undef,0)
    test_accuracy = Vector{Float32}(undef,0)
    test_loss = Vector{Float32}(undef,0)
    test_iteration = Vector{Int64}(undef,0)
    max_iterations = 0
    iteration = 0
    epoch_idx = 0
    while epoch_idx<epochs
        epoch_idx += 1
        # Make minibatches
        num_test = length(test_set[1])
        run_test = num_test!=0
        train_batches = make_minibatch(train_set,batch_size)
        if run_test
            test_batches = make_minibatch(test_set,batch_size)
        else
            test_batches = Vector{Tuple{Array{Float32,4},Array{Float32,4}}}(undef,0)
        end
        num = length(train_batches)
        if epoch_idx==1
            testing_frequency = num/testing_frequency
            max_iterations = epochs*num
            put!(channels.training_progress,[epochs,num,max_iterations])
        end
        last_test = 0
        # Run iteration
        for i=1:num
            iteration+=1
            if isready(channels.training_modifiers)
                modifs::Union{Vector{String},Vector{String,Float64},
                    Vector{String,Int64}} = fix_QML_types(take!(channels.training_modifiers))
                while isready(channels.training_modifiers)
                    modifs = fix_QML_types(take!(channels.training_modifiers))
                end
                modif1::String = modifs[1]
                if modif1=="stop"
                    data = (accuracy_array,loss_array,
                        test_accuracy,test_loss,test_iteration)
                    return data
                elseif modif1=="learning rate"
                    opt.eta = convert(Float64,modifs[2])
                elseif modif1=="epochs"
                    epochs::Int64 = convert(Int64,modifs[2])
                elseif modif1=="testing frequency"
                    testing_frequency::Int64 = convert(Int64,floor(num/modif2))
                end
            end
            train_minibatch = train_batches[i]
            # Training part
            local temp_loss = 0.0f0
            local predicted = Array{Float32,4}(undef,0,0,0,0)
            input = train_minibatch[1]
            actual = train_minibatch[2]
            ps = Flux.Params(params(model))
            gs = gradient(ps) do
              predicted = model(input)
              temp_loss = loss(predicted,actual)
            end
            Flux.Optimise.update!(opt,ps,gs)
            accuracy_val::Float32 = accuracy(predicted,actual)
            loss_val::Float32 = temp_loss
            data_temp = [accuracy_val,loss_val]
            put!(channels.training_progress,["Training",data_temp...])
            push!(accuracy_array,data_temp[1])
            push!(loss_array,data_temp[2])
            # Testing part
            if run_test
              if ceil(i/testing_frequency)>last_test || iteration==max_iterations
                  data_test = test(model,loss,channels,test_batches,length(test_batches),use_GPU)
                  last_test += 1
                  put!(channels.training_progress,["Testing",data_test...,iteration])
                  push!(test_accuracy,data_test[1])
                  push!(test_loss,data_test[2])
                  push!(test_iteration,iteration)
              end
            end
            @everywhere GC.safepoint()
        end
        @everywhere GC.gc()
    end
    data = (accuracy_array,loss_array,test_accuracy,test_loss,test_iteration)
    return data
end

function train_GPU!(model::Chain,accuracy::Function,loss::Function,
        args::Hyperparameters_training,testing_frequency::Float64,
        train_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        test_set::Tuple{Vector{Array{Float32,3}},Vector{Array{Float32,3}}},
        opt,channels::Channels)
    # Training loop
    model = move(model,gpu)
    epochs = args.epochs
    batch_size = args.batch_size
    accuracy_array = Vector{Float32}(undef,0)
    loss_array = Vector{Float32}(undef,0)
    test_accuracy = Vector{Float32}(undef,0)
    test_loss = Vector{Float32}(undef,0)
    test_iteration = Vector{Int64}(undef,0)
    max_iterations = 0
    iteration = 0
    epoch_idx = 0
    while epoch_idx<epochs
        epoch_idx += 1
        # Make minibatches
        num_test = length(test_set[1])
        run_test = num_test!=0
        train_batches = make_minibatch(train_set,batch_size)
        if run_test
            test_batches = make_minibatch(test_set,batch_size)
        else
            test_batches = Vector{Tuple{Array{Float32,4},Array{Float32,4}}}(undef,0)
        end
        num = length(train_batches)
        if epoch_idx==1
            testing_frequency = num/testing_frequency
            max_iterations = epochs*num
            put!(channels.training_progress,[epochs,num,max_iterations])
        end
        last_test = 0
        # Run iteration
        for i=1:num
            iteration+=1
            if isready(channels.training_modifiers)
                modifs = fix_QML_types(take!(channels.training_modifiers))
                while isready(channels.training_modifiers)
                    modifs = fix_QML_types(take!(channels.training_modifiers))
                end
                modif1::String = modifs[1]
                if modif1=="stop"
                    data = (accuracy_array,loss_array,
                        test_accuracy,test_loss,test_iteration)
                    return data
                elseif modif1=="learning rate"
                    opt.eta = convert(Float64,modifs[2])
                elseif modif1=="epochs"
                    epochs::Int64 = convert(Int64,modifs[2])
                elseif modif1=="testing frequency"
                    testing_frequency::Float64 = floor(num/modif2)
                end
            end
            train_minibatch = CuArray.(train_batches[i])
            # Training part
            local temp_loss = 0.0f0
            local predicted = CuArray(Array{Float32,4}(undef,0,0,0,0))
            input_data = train_minibatch[1]
            actual = train_minibatch[2]
            ps = Flux.Params(params(model))
            gs = gradient(ps) do
              predicted = model(input_data)
              temp_loss = loss(predicted,actual)
            end
            Flux.Optimise.update!(opt,ps,gs)
            accuracy_val::Float32 = accuracy(predicted,actual)
            loss_val::Float32 = temp_loss
            data_temp = [accuracy_val,loss_val]
            CUDA.unsafe_free!(predicted)
            put!(channels.training_progress,["Training",data_temp...])
            push!(accuracy_array,data_temp[1])
            push!(loss_array,data_temp[2])
            # Testing part
            if run_test
              if ceil(i/testing_frequency)>last_test || iteration==max_iterations
                  data_test = test(model,loss,channels,test_batches,length(test_batches),use_GPU)
                  last_test += 1
                  put!(channels.training_progress,["Testing",data_test...,iteration])
                  push!(test_accuracy,data_test[1])
                  push!(test_loss,data_test[2])
                  push!(test_iteration,iteration)
              end
            end
            @everywhere GC.safepoint()
        end
        @everywhere GC.gc()
    end
    data = (accuracy_array,loss_array,test_accuracy,test_loss,test_iteration)
    return data
end

function test_CPU(model::Chain,loss::Function,channels::Channels,
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

function test_GPU(model::Chain,loss::Function,channels::Channels,
        test_batches::Array{Tuple{Array{Float32,4},Array{Float32,4}},1},num_test::Int64)
    test_accuracy = Vector{Float32}(undef,num_test)
    test_loss = Vector{Float32}(undef,num_test)
    for j=1:num_test
        test_minibatch = CuArray.(test_batches[j])
        predicted = model(test_minibatch[1])
        actual = test_minibatch[2]
        test_accuracy[j] = cpu(accuracy(predicted,actual))
        test_loss[j] = cpu(loss(predicted,actual))
    end
    data = [mean(test_accuracy),mean(test_loss)]
    return data
end

function reset_training_data(training_plot_data::Training_plot_data)
    training_plot_data.accuracy = []
    training_plot_data.loss = []
    training_plot_data.test_accuracy = []
    training_plot_data.test_loss = []
    training_plot_data.iteration = 0
    training_plot_data.epoch = 0
    training_plot_data.iterations_per_epoch = 0
    training_plot_data.starting_time = now()
    return nothing
end

function move(model,target::Union{typeof(cpu),typeof(gpu)})
    model_moved = []
    if model isa Chain
        for i = 1:length(model)
            if model[i] isa Parallel
                layers = model[i].layers
                new_layers = Array{Any}(undef,length(layers))
                for i = 1:length(layers)
                    new_layers[i] = move(layers[i],target)
                end
                new_layers = (new_layers...,)
                push!(model_moved,target(Parallel(new_layers)))
            else
                push!(model_moved,target(model[i]))
            end
        end
    else
        push!(model_moved,target(model))
    end
    if length(model_moved)==1
        model_moved = model_moved[1]
    else
        model_moved = target(Chain(model_moved...))
    end
    return model_moved
end

function train_main(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    training = settings.Training
    training_plot_data = training_data.Training_plot_data
    model = model_data.model
    loss = model_data.loss
    accuracy = get_accuracy_func(training)
    args = training.Options.Hyperparameters
    learning_rate = args.learning_rate
    epochs = args.epochs
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    reset_training_data(training_plot_data)
    # Preparing train and test sets
    train_set, test_set = get_train_test(training_plot_data,training)
    opt = get_optimiser(training)
    if isready(channels.training_modifiers)
        stop_cond::String = fetch(channels.training_modifiers)[1]
        if stop_cond=="stop"
            take!(channels.training_modifiers)
            return nothing
        end
    end
    testing_frequency = training.Options.General.testing_frequency
    if use_GPU
        data = train_GPU!(model,accuracy,loss,args,testing_frequency,
            train_set,test_set,opt,channels)
    else
        data = train_CPU!(model,accuracy,loss,args,testing_frequency,
            train_set,test_set,opt,channels)
    end
    if use_GPU
        model = move(model,cpu)
    end
    model_data.model = model
    save_model_main(model_data,string("models/",training.name,".model"))
    put!(channels.training_data_results,(model,data...))
    return nothing
end
function train_main2(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    @everywhere settings,training_data,model_data
    remote_do(train_main,workers()[end],settings,training_data,model_data,channels)
end
train() = train_main2(settings,training_data,model_data,channels)
