
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

function get_validation_set(validation_plot_data::Validation_plot_data,training::Training)
    data_input_raw = validation_plot_data.data_input
    data_labels_raw = convert(Vector{Array{Float32,3}},
        validation_plot_data.data_labels)
    data_input = map(x->x[:,:,:,:],data_input_raw)
    data_labels = map(x->x[:,:,:,:],data_labels_raw)
    set = (data_input,data_labels)
    return set
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
    optimiser_ind::Int64 = training.Options.Hyperparameters.optimiser[2]
    parameters::Vector{Union{Float64,Tuple{Float64,Float64}}} =
        training.Options.Hyperparameters.optimiser_params[optimiser_ind]
    learning_rate = training.Options.Hyperparameters.learning_rate
    if length(parameters)==1
        parameters = [learning_rate,parameters[1]]
    elseif length(parameters)==2
        parameters = [learning_rate,(parameters[1],parameters[2])]
    elseif length(parameters)==3
        parameters = [learning_rate,(parameters[1],parameters[2]),parameters[3]]
    end
    optimiser_func = optimisers[optimiser_ind]
    optimiser = optimiser_func(parameters...)
    return optimiser
end

function train!(model::Chain,args::Hyperparameters_training,testing_frequency::Int64,
    loss::Function,channels::Channels,
    train_set::Tuple{Vector{<:Array{Float32}},Vector{<:Array{Float32}}},
    test_set::Tuple{Vector{<:Array{Float32}},Vector{<:Array{Float32}}},opt,use_GPU::Bool)
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
                    epochs = convert(Int64,modifs[2])
                elseif modif1=="testing frequency"
                    testing_frequency = convert(Int64,floor(num/modif2))
                end
            end
            train_minibatch = train_batches[i]
            # Training part
            local temp_loss::Float32,predicted::Union{Array{Float32,4},CuArray{Float32,4}}
            if use_GPU
                train_minibatch::Tuple{CuArray{Float32,4},
                    CuArray{Float32,4}} = gpu.(train_minibatch)
            end
            input = train_minibatch[1]
            actual = train_minibatch[2]
            ps = Flux.Params(params(model))
            gs = gradient(ps) do
              predicted = model(input)
              temp_loss = loss(predicted,actual)
              return temp_loss
            end
            Flux.Optimise.update!(opt,ps,gs)
            data = [cpu(accuracy(predicted,actual)),cpu(temp_loss)]
            CUDA.unsafe_free!(predicted)
            put!(channels.training_progress,["Training",data...])
            push!(accuracy_array,data[1])
            push!(loss_array,data[2])
            # Testing part
            if run_test
              if ceil(i/testing_frequency)>last_test || iteration==max_iterations
                  data = test(model,loss,channels,test_batches,length(test_batches),use_GPU)
                  last_test += 1
                  data = [data...,iteration]
                  put!(channels.training_progress,["Testing",data...])
                  push!(test_accuracy,data[1])
                  push!(test_loss,data[2])
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

function test(model::Chain,loss::Function,channels::Channels,test_batches::Array,
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

function reset_validation_data(validation_plot_data::Validation_plot_data)
    validation_plot_data.accuracy = []
    validation_plot_data.loss = []
    validation_plot_data.loss_std = NaN
    validation_plot_data.accuracy_std = NaN
    validation_plot_data.data_error =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    validation_plot_data.data_target =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    validation_plot_data.data_predicted =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
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
    # Preparing train and test sets
    train_set, test_set = get_train_test(training_plot_data,training)
    # Load model onto GPU, if enabled
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    if use_GPU
        model = move(model,gpu)
        loss = gpu(loss)
    end
    reset_training_data(training_plot_data)
    # Use ADAM optimiser
    opt = get_optimiser(training)
    if isready(channels.training_modifiers)
        stop_cond::String = fetch(channels.training_modifiers)[1]
        if stop_cond=="stop"
            take!(channels.training_modifiers)
            return nothing
        end
    end
    testing_frequency = training.Options.General.testing_frequency
    data = train!(model,args,testing_frequency,loss,channels,
        train_set,test_set,opt,use_GPU)
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

function prepare_data(input_data::Union{Array{Float32,4},CuArray{Float32,4}},ind_max::Int64,
        max_value::Int64,offset::Int64,ind_split::Int64,j::Int64)
    start_ind = 1 + (j-1)*ind_split-1
    end_ind = start_ind + ind_split-1
    correct_size = end_ind-start_ind+1
    start_ind = start_ind - offset
    end_ind = end_ind + offset
    start_ind = start_ind<1 ? 1 : start_ind
    end_ind = end_ind>max_value ? max_value : end_ind
    temp_data = input_data[:,start_ind:end_ind,:,:]
    max_dim_size = size(temp_data,ind_max)
    offset_add = Int64(ceil(max_dim_size/16)*16) - max_dim_size
    temp_data = pad(temp_data,[0,offset_add],same)
    output_data = (temp_data,correct_size,offset_add)
    return output_data
end

function fix_size(temp_predicted::Union{Array{Float32,4},CuArray{Float32,4}},
        num_parts::Int64,correct_size::Int64,ind_max::Int64,
        offset_add::Int64,j::Int64)
    temp_size = size(temp_predicted,ind_max)
    offset_temp = (temp_size - correct_size) - offset_add
    if offset_temp>0
        div_result = offset_add/2
        offset_add1 = Int64(floor(div_result))
        offset_add2 = Int64(ceil(div_result))
        if j==1
            temp_predicted = temp_predicted[:,
                (1+offset_add1):(end-offset_temp-offset_add2),:,:]
        elseif j==num_parts
            temp_predicted = temp_predicted[:,
                (1+offset_temp+offset_add1):(end-offset_add2),:,:]
        else
            temp = (temp_size - correct_size - offset_add)/2
            offset_temp = Int64(floor(temp))
            offset_temp2 = Int64(ceil(temp))
            temp_predicted = temp_predicted[:,
                (1+offset_temp+offset_add1):(end-offset_temp2-offset_add2),:,:]
        end
    elseif offset_temp<0
        temp_predicted = pad(temp_predicted,[0,-offset_temp])
    end
end

function accum_parts(model::Chain,input_data::Array{Float32,4},
        num_parts::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_parts))
    predicted = Vector{Array{Float32,4}}(undef,0)
    for j = 1:num_parts
        if j==num_parts
            ind_split = ind_split+rem(max_value,num_parts)
        end
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,offset,ind_split,j)
        temp_predicted = model(temp_data)
        temp_predicted =
            fix_size(temp_predicted,num_parts,correct_size,ind_max,offset_add,j)
        push!(predicted,temp_predicted)
        GC.gs()
    end
    predicted_out::Array{Float32,4} = vcat(predicted...)
    return predicted_out
end

function accum_parts(model::Chain,input_data::CuArray{Float32,4},
        num_parts::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_parts))
    predicted = Vector{CuArray{Float32,4}}(undef,0)
    for j = 1:num_parts
        if j==num_parts
            ind_split = ind_split+rem(max_value,num_parts)
        end
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,offset,ind_split,j)
        temp_predicted::CuArray{Float32,4} = model(temp_data)
        temp_predicted =
            fix_size(temp_predicted,num_parts,correct_size,ind_max,offset_add,j)
        push!(predicted,cpu(temp_predicted))
        CUDA.unsafe_free!(temp_predicted)
    end
    predicted_out::CuArray{Float32,4} = hcat(predicted...)
    return predicted_out
end

function output_and_error_images(predicted_array::Vector{BitArray{3}},
        actual_array::Array{Array{Float32,4},1},
        model_data::Model_data,channels::Channels)
    labels_color,labels_incl,border = get_feature_data(model_data.features)
    border_colors = labels_color[findall(border)]
    labels_color = vcat(labels_color,border_colors,border_colors)
    array_size = size(predicted_array[1])
    array_size12 = array_size[1:2]
    num_feat = array_size[3]
    num = length(predicted_array)
    num2 = length(labels_color)
    perm_labels_color = Vector{Array{Float32,3}}(undef,num2)
    for i=1:num2
        perm_labels_color[i] = permutedims(labels_color[i][:,:,:]/255,[3,2,1])
    end
    num_border = sum(border)
    data_array = Vector{BitArray{3}}(undef,num+num_border)
    if num_border>0
        border_array = map(x->apply_border_data_main(x,model_data),predicted_array)
        data_array .= cat.(predicted_array,border_array,dims=3)
    else
        data_array .= predicted_array
    end
    predicted_color = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    predicted_error = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    target_color = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    Threads.@threads for i = 1:num
        set_part = actual_array[i]
        data_array_part = data_array[i]
        function compute(num2::Int64,num_feat::Int64,set_part::Array{Float32,4},
                data_array_part::BitArray{3})
            target_temp = Vector{Array{RGB{Float32},2}}(undef,0)
            predicted_color_temp = Vector{Array{RGB{Float32},2}}(undef,0)
            predicted_error_temp = Vector{Array{RGB{Float32},2}}(undef,0)
            function do_target!(target_temp::Vector{Array{RGB{Float32},2}},
                    target::Array{Float32,2},color::Array{Float32,3})
                target_img = target.*color
                target_img2 = permutedims(target_img,[3,1,2])
                target_img3 = colorview(RGB,target_img2)
                target_img3 = collect(target_img3)
                push!(target_temp,target_img3)
            end
            function do_predicted_error!(predicted_error_temp::Vector{Array{RGB{Float32},2}},
                    truth::BitArray{2},predicted_bool::BitArray{2})
                correct = predicted_bool .& truth
                false_pos = copy(predicted_bool)
                false_pos[truth] .= false
                false_neg = copy(truth)
                false_neg[predicted_bool] .= false
                error_img = zeros(Bool,(size(predicted_bool)...,3))
                error_img[:,:,1:2] .= false_pos
                error_img[:,:,1] = error_img[:,:,1] .| false_neg
                error_img[:,:,2] = error_img[:,:,2] .| correct
                error_img = permutedims(error_img,[3,1,2])
                error_img2 = convert(Array{Float32,3},error_img)
                error_img3 = colorview(RGB,error_img2)
                error_img3 = collect(error_img3)
                push!(predicted_error_temp,error_img3)
                return
            end
            function do_predicted_color!(predicted_color_temp::Vector{Array{RGB{Float32},2}},
                    predicted_bool::BitArray{2},color::Array{Float32,3})
                temp = Float32.(predicted_bool)
                temp = cat(temp,temp,temp,dims=3)
                temp = temp.*color
                temp = permutedims(temp,[3,1,2])
                temp2 = convert(Array{Float32,3},temp)
                temp3 = colorview(RGB,temp2)
                temp3 = collect(temp3)
                push!(predicted_color_temp,temp3)
                return
            end
            for j = 1:num2
                if j>num_feat
                    target = set_part[:,:,j-num_feat]
                else
                    target = set_part[:,:,j]
                end
                color = perm_labels_color[j]
                do_target!(target_temp,target,color)
                truth = target.>0
                predicted_bool = data_array_part[:,:,j]
                do_predicted_error!(predicted_error_temp,truth,predicted_bool)
                do_predicted_color!(predicted_color_temp,predicted_bool,color)
                @everywhere GC.safepoint()
            end
            return target_temp,predicted_color_temp,predicted_error_temp
        end
        target_temp,predicted_color_temp,predicted_error_temp =
            compute(num2,num_feat,set_part,data_array_part)
        predicted_color[i] = predicted_color_temp
        predicted_error[i] = predicted_error_temp
        target_color[i] = target_temp
        put!(channels.validation_progress,1)
        @everywhere GC.safepoint()
    end
    return predicted_color,predicted_error,target_color
end

function validate_main(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    training = settings.Training
    validation_plot_data = training_data.Validation_plot_data
    model = model_data.model
    loss = model_data.loss
    accuracy = get_accuracy_func(training)
    reset_validation_data(validation_plot_data)
    # Preparing set
    set = get_validation_set(validation_plot_data,training)
    # Load model onto GPU, if enabled
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    if use_GPU
        model = move(model,gpu)
    end
    # Validate
    num = length(set[1])
    accuracy_array = Vector{Float32}(undef,0)
    predicted_array = Vector{BitArray{3}}(undef,0)
    loss_array = Vector{Float32}(undef,0)
    put!(channels.validation_progress,[2*num])
    num_parts = 10
    offset = 20
    @everywhere GC.gc()
    for i = 1:num
        if isready(channels.validation_modifiers)
            stop_cond::String = fetch(channels.validation_modifiers)[1]
            if stop_cond=="stop"
                take!(channels.validation_modifiers)
                break
            end
        end
        input_data = set[1][i]
        actual = set[2][i]
        if use_GPU
            input_data::CuArray{Float32,4} = gpu(input_data)
            actual::CuArray{Float32,4} = gpu(actual)
        end
        if num_parts==1
            predicted = model(input_data)
        else
            predicted = accum_parts(model,input_data,num_parts,offset)
        end
        size_dim4 = size(predicted,4)
        accuracy_array_temp = Vector{Float32}(undef,size_dim4)
        predicted_array_temp = Vector{BitArray{3}}(undef,size_dim4)
        loss_array_temp = Vector{Float32}(undef,size_dim4)
        predicted_bool = predicted.>0.5
        for j = 1:size_dim4
            predicted_temp = predicted[:,:,:,j:j]
            actual_temp = actual[:,:,:,j:j]
            accuracy_array_temp[i] = accuracy(predicted_temp,actual_temp)
            loss_array_temp[i] = loss(predicted_temp,actual_temp)
            if has_GPU
                predicted_array_temp[i] = cpu(predicted_bool[:,:,:,j])
            else
                predicted_array_temp[i] = predicted_bool[:,:,:,j]
            end
        end
        push!(accuracy_array,accuracy_array_temp...)
        push!(loss_array,loss_array_temp...)
        push!(predicted_array,predicted_array_temp...)
        temp_accuracy = accuracy_array[1:i]
        temp_loss = loss_array[1:i]
        mean_accuracy = mean(temp_accuracy)
        mean_loss = mean(temp_loss)
        accuracy_std = std(temp_accuracy)
        loss_std = std(temp_loss)
        data_out = [mean_accuracy,mean_loss,accuracy_std,loss_std]
        put!(channels.validation_progress,data_out)
        @everywhere GC.safepoint()
    end
    #=empty!(validation_plot_data.data_input_orig)
    empty!(validation_plot_data.data_labels_orig)
    empty!(validation_plot_data.data_input)
    empty!(validation_plot_data.data_labels)=#
    actual_array = set[2]
    data_predicted,data_error,target = output_and_error_images(predicted_array,
        actual_array,model_data,channels)
    data = (data_predicted,data_error,target,
        accuracy_array,loss_array,std(accuracy_array),std(loss_array))
    put!(channels.validation_results,data)
    return nothing
end
function validate_main2(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    @everywhere settings,training_data,model_data
    remote_do(validate_main,workers()[end],settings,training_data,model_data,channels)
end
validate() = validate_main2(settings,training_data,model_data,channels)
