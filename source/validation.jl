
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

function reset_validation_data(validation_results::Validation_results)
    empty_field!(validation_results,:original)
    empty_field!(validation_results,:predicted_data)
    empty_field!(validation_results,:target_data)
    empty_field!(validation_results,:error_data)
    empty_field!(validation_results,:other_data)
    return nothing
end

function prepare_validation_data(validation::Validation,
        validation_data::Validation_data,features::Array,ind::Int64)
    validation_results = validation_data.Results
    labels_color,labels_incl,border,border_thickness = get_feature_data(features)
    original = load_image(validation_data.url_input[ind])
    data_input = image_to_gray_float(original)[:,:,:,:]
    if validation.use_labels
        label = load_image(validation_data.url_labels[ind])
        label_bool = label_to_bool(label,labels_color,labels_incl,
            border,border_thickness)
        data_label = convert(Array{Float32,3},label_bool)[:,:,:,:]
    else
        data_label = Array{Float32,4}(undef,size(data_input))
    end
    return original,data_input,data_label
end

#---Makes output images
function get_error_image(predicted_bool_feat::BitArray{2},truth::BitArray{2})
    correct = predicted_bool_feat .& truth
    false_pos = copy(predicted_bool_feat)
    false_pos[truth] .= false
    false_neg = copy(truth)
    false_neg[predicted_bool_feat] .= false
    s = (3,size(predicted_bool_feat)...)
    error_bool = BitArray{3}(undef,s)
    error_bool[1,:,:] .= false_pos
    error_bool[2,:,:] .= false_pos
    error_bool[1,:,:] = error_bool[1,:,:] .| false_neg
    error_bool[2,:,:] = error_bool[2,:,:] .| correct
    return error_bool
end

function compute(validation::Validation,predicted_bool::BitArray{3},
        label_bool::BitArray{3},labels_color::Vector{Vector{N0f8}},
        num_feat::Int64)
    num = size(predicted_bool,3)
    predicted_data = Vector{Tuple{BitArray{2},Vector{N0f8}}}(undef,num)
    target_data = Vector{Tuple{BitArray{2},Vector{N0f8}}}(undef,num)
    error_data = Vector{Tuple{BitArray{3},Vector{N0f8}}}(undef,num)
    color_error = ones(N0f8,3)
    for i = 1:num
        color = labels_color[i]
        predicted_bool_feat = predicted_bool[:,:,i]
        predicted_data[i] = (predicted_bool_feat,color)
        if validation.use_labels
            if i>num_feat
                target_bool = label_bool[:,:,i-num_feat]
            else
                target_bool = label_bool[:,:,i]
            end
            target_data[i] = (target_bool,color)
            error_bool = get_error_image(predicted_bool_feat,target_bool)
            error_data[i] = (error_bool,color_error)
        end
    end
    return predicted_data,target_data,error_data
end

function output_images(predicted_bool::BitArray{3},label_bool::BitArray{3},
        model_data::Model_data,validation::Validation)
    labels_color,labels_incl,border = get_feature_data(model_data.features)
    labels_color_uint = convert(Vector{Vector{N0f8}},labels_color/255)
    inds_border = findall(border)
    border_colors = labels_color_uint[findall(border)]
    labels_color_uint = vcat(labels_color_uint,border_colors,border_colors)
    array_size = size(label_bool)
    array_size12 = array_size[1:2]
    num_feat = array_size[3]
    num = length(labels_color_uint)
    num_border = sum(border)
    if num_border>0
        border_bool = apply_border_data_main(predicted_bool,model_data)
        predicted_bool = cat3(predicted_bool,border_bool)
    end
    predicted_bool_final = predicted_bool
    @threads for i=1:num_border
        min_area = model_data.features[inds_border[i]].min_area
        ind = num_feat + i
        if min_area>1
            temp_array = predicted_bool_final[:,:,ind]
            areaopen!(temp_array,min_area)
            predicted_bool_final[:,:,ind] .= temp_array
        end
    end
    predicted_data,error_data,target_data = compute(validation,
        predicted_bool_final,label_bool,labels_color_uint,num_feat)
    return predicted_data,error_data,target_data
end

# Main validation function
function validate_main(settings::Settings,validation_data::Validation_data,
        model_data::Model_data,channels::Channels)
    # Initialisation
    validation = settings.Validation
    validation_results = validation_data.Results
    reset_validation_data(validation_results)
    num = length(validation_data.url_input)
    put!(channels.validation_progress,num)
    use_labels = validation.use_labels
    features = model_data.features
    if isempty(features)
        @info "empty features"
        return nothing
    end
    model = model_data.model
    loss = model_data.loss
    accuracy = get_accuracy_func(settings.Training)
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    accuracy_array = Vector{Float32}(undef,num)
    loss_array = Vector{Float32}(undef,num)
    @everywhere GC.gc()
    for i = 1:num
        if isready(channels.validation_modifiers)
            stop_cond::String = fetch(channels.validation_modifiers)[1]
            if stop_cond=="stop"
                take!(channels.validation_modifiers)
                break
            end
        end
        # Preparing data
        original,data_input,data_label = prepare_validation_data(validation,
            validation_data,features,i)
        predicted = forward(model,data_input,use_GPU=use_GPU)
        accuracy_array[i] = accuracy(predicted,data_label)
        loss_array[i] = loss(predicted,data_label)
        if use_labels
            other_data = (accuracy_array[i],loss_array[i])
        else
            other_data = (0.f0,0.f0)
        end
        predicted_bool = predicted[:,:,:,1].>0.5
        label_bool = data_label[:,:,:,1].>0.5
        # Clean up
        data_input = nothing
        data_label = nothing
        predicted = nothing
        @everywhere GC.gc()
        # Get images
        predicted_data,target_data,error_data = 
            output_images(predicted_bool,label_bool,model_data,validation)
        image_data = (predicted_data,target_data,error_data)
        data = (original,image_data,other_data)
        # Return data
        put!(channels.validation_results,data)
        put!(channels.validation_progress,1)
    end
    return nothing
end
function validate_main2(settings::Settings,validation_data::Validation_data,
        model_data::Model_data,channels::Channels)
    @everywhere settings,validation_data,model_data
    remote_do(validate_main,workers()[end],settings,validation_data,model_data,channels)
end
validate() = validate_main2(settings,validation_data,model_data,channels)