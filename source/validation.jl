
#---Data preparation

# Get urls of files in selected folders
function get_urls_validation_main(validation::Validation,model_data::Model_data)
    if model_data.type[2]=="Images"
        allowed_ext = ["png","jpg","jpeg"]
    end
    if validation.use_labels==true
        get_urls2(validation,validation_data,allowed_ext)
    else
        get_urls1(validation,validation_data,allowed_ext)
    end
end
get_urls_validation() = get_urls_validation_main(validation,model_data)

function prepare_validation_data_main(validation::Validation,validation_data::Validation_data,
        features::Array,progress::RemoteChannel,results::RemoteChannel)
    if isempty(features)
        @info "empty features"
        return false
    end
    labels_color,labels_incl,border,border_thickness = get_feature_data(features)
    put!(progress,2)
    images = load_images(validation_data.url_input)
    data_input = map(x->image_to_gray_float(x),images)
    put!(progress,1)
    if validation.use_labels
        labels = load_images(validation_data.url_labels)
        data_labels = map(x->label_to_bool(x,labels_color,labels_incl,
            border,border_thickness),labels)
        data = (images,labels,data_input,data_labels)
    else
        data = (images,data_input)
    end
    put!(results,data)
    put!(progress,1)
    return nothing
end
function  prepare_validation_data_main2(validation::Validation,
        validation_data::Validation_data,features::Array,
        progress::RemoteChannel,results::RemoteChannel)
    @everywhere validation,validation_data
    remote_do(prepare_validation_data_main,workers()[end],validation,validation_data,
    features,progress,results)
end
prepare_validation_data() = prepare_validation_data_main2(validation,validation_data,
    model_data.features,channels.validation_data_progress,
    channels.validation_data_results)

function get_validation_set(validation::Validation,validation_plot_data::Validation_plot_data)
    data_input_raw = validation_plot_data.data_input
    data_input = map(x->x[:,:,:,:],data_input_raw)
    if validation.use_labels
        data_labels_raw = convert(Vector{Array{Float32,3}},
            validation_plot_data.data_labels)
        data_labels = map(x->x[:,:,:,:],data_labels_raw)
    else
        data_labels = Vector{Array{Float32,4}}(undef,length(data_input))
        fill!(data_labels,Array{Float32,4}(undef,0,0,0,0))
    end
    set = (data_input,data_labels)
    return set
end

function reset_validation_data(validation_plot_data::Validation_plot_data,
        validation_results_data::Validation_results_data)
    validation_results_data.accuracy = Vector{Float32}(undef,0)
    validation_results_data.loss = Vector{Float32}(undef,0)
    validation_results_data.loss_std = NaN
    validation_results_data.accuracy_std = NaN
    validation_plot_data.data_error =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    validation_plot_data.data_target =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    validation_plot_data.data_predicted =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    return nothing
end

#---Makes output images
function do_target!(target_temp::Vector{Array{RGB{Float32},2}},
        target::Array{Float32,2},color::Array{Float32,3},j::Int64)
    target_img = target.*color
    target_img2 = permutedims(target_img,[3,1,2])
    target_img3 = colorview(RGB,target_img2)
    target_img3 = collect(target_img3)
    target_temp[j] = target_img3
end

function do_predicted_error!(predicted_error_temp::Vector{Array{RGB{Float32},2}},
        truth::BitArray{2},predicted_bool::BitArray{2},j::Int64)
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
    predicted_error_temp[j] = error_img3
    return
end

function do_predicted_color!(predicted_color_temp::Vector{Array{RGB{Float32},2}},
        predicted_bool::BitArray{2},color::Array{Float32,3},j::Int64)
    temp = Float32.(predicted_bool)
    temp = cat3(temp,temp,temp)
    temp = temp.*color
    temp = permutedims(temp,[3,1,2])
    temp2 = convert(Array{Float32,3},temp)
    temp3 = colorview(RGB,temp2)
    temp3 = collect(temp3)
    predicted_color_temp[j] = temp3
    return
end

function compute(validation::Validation,set_part::Array{Float32,4},
        data_array_part::BitArray{3},perm_labels_color::Vector{Array{Float32,3}},
        num2::Int64,num_feat::Int64)
    target_temp = Vector{Array{RGB{Float32},2}}(undef,num2)
    predicted_color_temp = Vector{Array{RGB{Float32},2}}(undef,num2)
    predicted_error_temp = Vector{Array{RGB{Float32},2}}(undef,num2)
    @threads for j = 1:num2
        color = perm_labels_color[j]
        predicted_bool = data_array_part[:,:,j]
        do_predicted_color!(predicted_color_temp,predicted_bool,color,j)
        if validation.use_labels
            if j>num_feat
                target = set_part[:,:,j-num_feat]
            else
                target = set_part[:,:,j]
            end
            do_target!(target_temp,target,color,j)
            truth = target.>0
            do_predicted_error!(predicted_error_temp,truth,predicted_bool,j)
        end
        @everywhere GC.safepoint()
    end
    return target_temp,predicted_color_temp,predicted_error_temp
end

function output_and_error_images(predicted_array::Vector{BitArray{3}},
        actual_array::Array{Array{Float32,4},1},model_data::Model_data,
        validation::Validation,channels::Channels)
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
    data_array = Vector{BitArray{3}}(undef,num)
    if num_border>0
        border_array = map(x->apply_border_data_main(x,model_data),predicted_array)
        data_array .= cat3.(predicted_array,border_array)
    else
        data_array .= predicted_array
    end
    @threads for i=1:num
        data_array_current = data_array[i]
        @threads for j=1:num_border
            min_area = model_data.features[j].min_area
            ind = num_feat + j
            if min_area>1
                temp_array = data_array_current[:,:,ind]
                areaopen!(temp_array,min_area)
                data_array_current[:,:,ind] .= temp_array
            end
        end
        data_array[i] = data_array_current
    end
    predicted_color = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    predicted_error = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    target_color = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    @threads for i = 1:num
        set_part = actual_array[i]
        data_array_part = data_array[i]
        target_temp,predicted_color_temp,predicted_error_temp =
            compute(validation,set_part,data_array_part,perm_labels_color,num2,num_feat)
        predicted_color[i] = predicted_color_temp
        predicted_error[i] = predicted_error_temp
        target_color[i] = target_temp
        put!(channels.validation_progress,1)
        @everywhere GC.safepoint()
    end
    return predicted_color,predicted_error,target_color
end

# Main validation function
function validate_main(settings::Settings,validation_data::Validation_data,
        model_data::Model_data,channels::Channels)
    validation = settings.Validation
    validation_plot_data = validation_data.Plot_data
    validation_results_data = validation_data.Results_data
    use_labels = validation.use_labels
    model = model_data.model
    loss = model_data.loss
    accuracy = get_accuracy_func(settings.Training)
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    reset_validation_data(validation_plot_data,validation_results_data)
    # Preparing set
    set = get_validation_set(validation,validation_plot_data)
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
        predicted = forward(model,input_data,num_parts=num_parts,
            offset=offset,use_GPU=use_GPU)
        predicted_bool = predicted.>0.5
        size_dim4 = size(predicted_bool,4)
        accuracy_array_temp = Vector{Float32}(undef,size_dim4)
        predicted_array_temp = Vector{BitArray{3}}(undef,size_dim4)
        loss_array_temp = Vector{Float32}(undef,size_dim4)
        for j = 1:size_dim4
            predicted_array_temp[j] = predicted_bool[:,:,:,j]
            if use_labels
                predicted_temp = predicted[:,:,:,j:j]
                actual_temp = actual[:,:,:,j:j]
                accuracy_array_temp[j] = accuracy(predicted_temp,actual_temp)
                loss_array_temp[j] = loss(predicted_temp,actual_temp)
            end
        end
        push!(predicted_array,predicted_array_temp...)
        if use_labels
            push!(accuracy_array,accuracy_array_temp...)
            push!(loss_array,loss_array_temp...)
            temp_accuracy = accuracy_array[1:i]
            temp_loss = loss_array[1:i]
            mean_accuracy = mean(temp_accuracy)
            mean_loss = mean(temp_loss)
            accuracy_std = std(temp_accuracy)
            loss_std = std(temp_loss)
            data_out = [mean_accuracy,mean_loss,accuracy_std,loss_std]
        else
            data_out = zeros(Float32,4)
        end
        put!(channels.validation_progress,data_out)
        @everywhere GC.safepoint()
    end
    actual_array = set[2]
    data_predicted,data_error,target = output_and_error_images(
        predicted_array,actual_array,model_data,validation,channels)
    data = (data_predicted,data_error,target,
        accuracy_array,loss_array,std(accuracy_array),std(loss_array))
    put!(channels.validation_results,data)
    return nothing
end
function validate_main2(settings::Settings,validation_data::Validation_data,
        model_data::Model_data,channels::Channels)
    @everywhere settings,validation_data,model_data
    remote_do(validate_main,workers()[end],settings,validation_data,model_data,channels)
end
validate() = validate_main2(settings,validation_data,model_data,channels)
