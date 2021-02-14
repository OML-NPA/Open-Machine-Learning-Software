
# Get urls of files in selected folders. Requires only data
function get_urls1(settings::Union{Training,Validation},
        data::Union{Training_data,Validation_data},allowed_ext::Vector{String})
    # Get a reference to url accumulators
    url_input = data.url_input
    # Empty a url accumulator
    empty!(url_input)
    # Get directories containing data and labels
    dir_input = settings.input
    # Return if no directories
    if isempty(dir_input)
        @info settings
        @info "empty urls"
        return nothing
    end
    # Get directories containing our images and labels
    dirs = getdirs(dir_input)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls to files
    for k = 1:length(dirs)
        # Get files in a directory
        files_input = getfiles(string(dir_input,"/",dirs[k]))
        files_input = filter_ext(files_input,allowed_ext)
        # Push urls into an accumulator
        for l = 1:length(files_input)
            push!(url_input,string(dir_input,"/",files_input[l]))
        end
    end
    return nothing
end

# Get urls of files in selected folders. Requires data and labels
function get_urls2(settings::Union{Training,Validation},
        data::Union{Training_data,Validation_data},allowed_ext::Vector{String})
    # Get a reference to url accumulators
    url_input = data.url_input
    url_labels = data.url_labels
    # Empty url accumulators
    empty!(url_input)
    empty!(url_labels)
    # Get directories containing images and labels
    dir_input = settings.input
    dir_labels = settings.labels
    # Return if no directories
    if isempty(dir_input) || isempty(dir_labels)
        @info "empty urls"
        return nothing
    end
    # Get directories containing our images and labels
    dirs_input= getdirs(dir_input)
    dirs_labels = getdirs(dir_labels)
    # Keep only those present for both images and labels
    dirs = intersect(dirs_input,dirs_labels)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls to files
    for k = 1:length(dirs)
        # Get files in a directory
        files_input = getfiles(string(dir_input,"/",dirs[k]))
        files_labels = getfiles(string(dir_labels,"/",dirs[k]))
        # Filter files
        files_input = filter_ext(files_input,allowed_ext)
        files_labels = filter_ext(files_labels,allowed_ext)
        # Remove extensions from files
        filenames_input = remove_ext(files_input)
        filenames_labels = remove_ext(files_labels)
        # Intersect file names
        inds1, inds2 = intersect_inds(filenames_labels, filenames_input)
        # Keep files present for both images and labels
        files_input = files_input[inds2]
        files_labels = files_labels[inds1]
        # Push urls into accumulators
        for l = 1:length(files_input)
            push!(url_input,string(dir_input,"/",files_input[l]))
            push!(url_labels,string(dir_labels,"/",files_labels[l]))
        end
    end
    return nothing
end

# Imports images using urls
function load_images(urls::Vector{String})
    num = length(urls)
    imgs = Vector{Array{RGB{N0f8},2}}(undef,num)
    for i = 1:num
        imgs[i] = load_image(urls[i])
    end
    return imgs
end

# Imports image
function load_image(url::String)
    img::Array{RGB{N0f8},2} = load(url)
    return img
end

# Convert images to grayscale Array{Float32,2}
function image_to_gray_float(image::Array{RGB{Normed{UInt8,8}},2})
    return collect(channelview(float.(Gray.(image))))[:,:,:]
end

# Convert images to RGB Array{Float32,3}
function image_to_rgb_float(image::Array{RGB{Normed{UInt8,8}},2})
    return collect(channelview(float.(image)))
end

# Convert images to BitArray{3}
function label_to_bool(labelimg::Array{RGB{Normed{UInt8,8}},2},
        labels_color::Vector{Vector{Float64}},labels_incl::Vector{Vector{Int64}},
        border::Vector{Bool},border_thickness::Vector{Int64})
    colors = map(x->RGB((n0f8.(./(x,255)))...),labels_color)
    num = length(colors)
    num_borders = sum(border)
    inds_borders = findall(border)
    label = fill!(BitArray{3}(undef, size(labelimg)...,
        num + num_borders),0)
    # Find features based on colors
    for i=1:num
        label[:,:,i] = .==(labelimg,colors[i])
    end
    # Combine feature marked for that
    for i=1:num
        for j=1:length(labels_incl[i])
            label[:,:,i] = .|(label[:,:,i],
                label[:,:,labels_incl[i][j]])
        end
    end
    # Make features outlining object borders
    for j=1:length(inds_borders)
        ind = inds_borders[j]
        dil = dilate(outer_perim(label[:,:,ind]),border_thickness[ind])
        label[:,:,length(colors)+j] = dil
    end
    return label
end

# Returns color for labels, whether should be combined with other
# labels and whether border data should be obtained
function get_feature_data(features::Vector{Feature})
    num = length(features)
    labels_color = Vector{Vector{Float64}}(undef,num)
    labels_incl = Vector{Vector{Int64}}(undef,num)
    border = Vector{Bool}(undef,num)
    border_thickness = Vector{Int64}(undef,num)
    feature_names = Vector{String}(undef,num)
    feature_parents = Vector{String}(undef,num)
    for i = 1:num
        feature_names[i] = features[i].name
        feature_parents[i] = features[i].parent
    end
    for i = 1:num
        feature = features[i]
        labels_color[i] = feature.color
        border[i] = feature.border
        border_thickness[i] = feature.border_thickness
        inds = findall(feature_names[i].==feature_parents)
        labels_incl[i] = inds
    end
    return labels_color,labels_incl,border,border_thickness
end

# Removes rows and columns from image sides if they are uniformly black.
function correct_view(img::Array{Float32,2},label::Array{RGB{Normed{UInt8,8}},2})
    field = dilate(imfilter(img.<0.3, Kernel.gaussian(4)).>0.5,20)
    areaopen!(field,30000)
    field = .!(field)
    field_area = sum(field)
    field_outer_perim = sum(outer_perim(field))/1.25
    circularity = (4*pi*field_area)/(field_outer_perim^2)
    if circularity>0.9
        row_bool = anydim(field,1)
        col_bool = anydim(field,2)
        col1 = findfirst(col_bool)[1]
        col2 = findlast(col_bool)[1]
        row1 = findfirst(row_bool)[1]
        row2 = findlast(row_bool)[1]
        img = img[row1:row2,col1:col2]
        label = label[row1:row2,col1:col2]
    end
    img = rescale(img,(0,1))
    return img,label
end

# Rotate Array
function rotate_img(img::AbstractArray{Real,2},angle_val::Float64)
    if angle!=0
        img_out = imrotate(img,angle_val,axes(img))
        replace_nan!(img_out)
        return(img_out)
    else
        return(img)
    end
end

function rotate_img(img::AbstractArray{T,3},angle_val::Float64) where T<:AbstractFloat
    if angle!=0
        img_out = copy(img)
        for i = 1:size(img,3)
            slice = img[:,:,i]
            temp = imrotate(slice,angle_val,axes(slice))
            replace_nan!(temp)
            img_out[:,:,i] = convert.(T,temp)
        end
        return(img_out)
    else
        return(img)
    end
end

function rotate_img(img::BitArray{3},angle_val::Float64)
    if angle!=0
        img_out = copy(img)
        for i = 1:size(img,3)
            slice = img[:,:,i]
            temp = imrotate(slice,angle_val,axes(slice))
            replace_nan!(temp)
            img_out[:,:,i] = temp.>0
        end
        return(img_out)
    else
        return(img)
    end
end

# Use border data to better separate objects
function apply_border_data_main(data_in::BitArray{3},
        model_data::Model_data)
    labels_color,labels_incl,border,border_thickness = get_feature_data(model_data.features)
    inds_border = findall(border)
    if isnothing(inds_border)
        return data_in
    end
    num_border = length(inds_border)
    num_feat = length(model_data.features)
    data = BitArray{3}(undef,size(data_in)[1:2]...,num_border)
    Threads.@threads for i = 1:num_border
        border_num_pixels = border_thickness[i]
        ind_feat = inds_border[i]
        ind_border = num_feat + ind_feat
        data_feat_bool = data_in[:,:,ind_feat]
        data_feat = convert(Array{Float32},data_feat_bool)
        data_border = data_in[:,:,ind_border]
        border_bool = data_border
        background1 = erode(data_feat_bool .& border_bool,border_num_pixels)
        background2 = outer_perim(border_bool)
        background2[data_feat_bool] .= false
        background2 = dilate(background2,border_num_pixels+1)
        background = background1 .| background2
        skel = thinning(border_bool)
        background[skel] .= true
        if model_data.features[i].border_remove_objs
            components = label_components((!).(border_bool),conn(4))
            centroids = component_centroids(components)
            intensities = component_intensity(components,data_feat)
            bad_components = findall(intensities.<0.7)
            for i = 1:length(bad_components)
                components[components.==bad_components[i]] .= 0
            end
            objects = data_feat.!=0
            objects[skel] .= false
            segmented = segment_objects(components,objects)
            borders = mapwindow(x->!allequal(x), segmented, (3,3))
            segmented[borders] .= 0
            data[:,:,ind_feat] = segmented.>0
        else
            data_feat_bool[background] .= false
            data[:,:,i] = data_feat_bool
        end
    end
    return data
end
apply_border_data(data_in) = apply_border_data_main(data_in,model_data)

#---
# Accuracy based on RMSE
function accuracy_regular(predicted::Union{Array,CuArray},actual::Union{Array,CuArray})
    dif = predicted - actual
    acc = 1-mean(mean.(map(x->abs.(x),dif)))
    return acc
end

# Weight accuracy using inverse frequency (CPU)
function accuracy_weighted(predicted::Array{Float32,4},actual::Array{Float32,4})
    # Get input dimensions
    array_size = size(actual)
    array_size12 = array_size[1:2]
    num_feat = array_size[3]
    num_batch = array_size[4]
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate correct and incorrect feature pixels as a BitArray
    correct_bool = predicted_bool .& actual_bool
    dif_bool = xor.(predicted_bool,actual_bool)
    # Calculate correct and incorrect background pixels as a BitArray
    correct_background_bool = (!).(dif_bool .| actual_bool)
    dif_background_bool = dif_bool-actual_bool
    # Number of elements
    numel = prod(array_size12)
    # Count number of feature pixels
    pix_sum = sum(actual_bool,dims=(1,2,4))
    pix_sum_perm = permutedims(pix_sum,[3,1,2,4])
    feature_counts = pix_sum_perm[:,1,1,1]
    # Calculate weight for each pixel
    fr = feature_counts./numel./num_batch
    w = 1 ./fr
    w2 = 1 ./(1 .- fr)
    w_sum = w + w2
    w = w./w_sum
    w2 = w2./w_sum
    w_adj = w./feature_counts
    w2_adj = w2./(numel*num_batch .- feature_counts)
    # Initialize vectors for storing accuracies
    features_accuracy = Vector{Float32}(undef,num_feat)
    background_accuracy = Vector{Float32}(undef,num_feat)
    # Calculate accuracies
    for i = 1:num_feat
        # Calculate accuracy for a feature
        sum_correct = sum(correct_bool[:,:,i,:])
        sum_dif = sum(dif_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        features_accuracy[i] = w_adj[i]*sum_comb
        # Calculate accuracy for a background
        sum_correct = sum(correct_background_bool[:,:,i,:])
        sum_dif = sum(dif_background_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        background_accuracy[i] = w2_adj[i]*sum_comb
    end
    # Calculate final accuracy
    acc = mean(features_accuracy+background_accuracy)
    if acc>1.0
        acc = 1.0f0
    end
    return acc
end

# Weight accuracy using inverse frequency (GPU)
function accuracy_weighted(predicted::CuArray{Float32,4},actual::CuArray{Float32,4})
    # Get input dimensions
    array_size = size(actual)
    array_size12 = array_size[1:2]
    num_feat = array_size[3]
    num_batch = array_size[4]
    # Convert to BitArray
    actual_bool = actual.>0
    predicted_bool = predicted.>0.5
    # Calculate correct and incorrect feature pixels as a BitArray
    correct_bool = predicted_bool .& actual_bool
    dif_bool = xor.(predicted_bool,actual_bool)
    # Calculate correct and incorrect background pixels as a BitArray
    correct_background_bool = (!).(dif_bool .| actual_bool)
    dif_background_bool = dif_bool-actual_bool
    # Number of elements
    numel = prod(array_size12)
    # Count number of feature pixels
    pix_sum::Array{Float32,4} = collect(sum(actual_bool,dims=(1,2,4)))
    pix_sum_perm = permutedims(pix_sum,[3,1,2,4])
    feature_counts = pix_sum_perm[:,1,1,1]
    # Calculate weight for each pixel
    fr = feature_counts./numel./num_batch
    w = 1 ./fr
    w2 = 1 ./(1 .- fr)
    w_sum = w + w2
    w = w./w_sum
    w2 = w2./w_sum
    w_adj = w./feature_counts
    w2_adj = w2./(numel*num_batch .- feature_counts)
    # Initialize vectors for storing accuracies
    features_accuracy = Vector{Float32}(undef,num_feat)
    background_accuracy = Vector{Float32}(undef,num_feat)
    # Calculate accuracies
    for i = 1:num_feat
        # Calculate accuracy for a feature
        sum_correct = sum(correct_bool[:,:,i,:])
        sum_dif = sum(dif_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        features_accuracy[i] = w_adj[i]*sum_comb
        # Calculate accuracy for a background
        sum_correct = sum(correct_background_bool[:,:,i,:])
        sum_dif = sum(dif_background_bool[:,:,i,:])
        sum_comb = sum_correct*sum_correct/(sum_correct+sum_dif)
        background_accuracy[i] = w2_adj[i]*sum_comb
    end
    # Calculate final accuracy
    acc = mean(features_accuracy+background_accuracy)
    if acc>1.0
        acc = 1.0f0
    end
    return acc
end

# Returns an accuracy function
function get_accuracy_func(training::Training)
    if training.Options.General.weight_accuracy
        return accuracy_weighted
    else
        return accuracy_regular
    end
end

#--- Applying a neural network
# Getting a slice and its information
function prepare_data(input_data::Union{Array{Float32,4},CuArray{Float32,4}},ind_max::Int64,
        max_value::Int64,offset::Int64,num_parts::Int64,ind_split::Int64,j::Int64)
    start_ind = 1 + (j-1)*ind_split
    if j==num_parts
        end_ind = max_value
    else
        end_ind = start_ind + ind_split-1
    end
    correct_size = end_ind-start_ind+1
    start_ind = start_ind - offset
    start_ind = start_ind<1 ? 1 : start_ind
    end_ind = end_ind + offset
    end_ind = end_ind>max_value ? max_value : end_ind
    temp_data = input_data[:,start_ind:end_ind,:,:]
    max_dim_size = size(temp_data,ind_max)
    offset_add = Int64(ceil(max_dim_size/16)*16) - max_dim_size
    temp_data = pad(temp_data,[0,offset_add],same)
    output_data = (temp_data,correct_size,offset_add)
    return output_data
end

# Makes output mask to have a correct size for stiching
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
        throw(DomainError("offset_temp should be greater or equal to zero"))
    end
end

# Accumulates and stiches slices (CPU)
function accum_parts(model::Chain,input_data::Array{Float32,4},
        num_parts::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_parts))
    predicted = Vector{Array{Float32,4}}(undef,0)
    for j = 1:num_parts
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,num_parts,offset,ind_split,j)
        temp_predicted::Array{Float32,4} = model(temp_data)
        temp_predicted =
            fix_size(temp_predicted,num_parts,correct_size,ind_max,offset_add,j)
        push!(predicted,temp_predicted)
    end
    if ind_max==1
        predicted_out = reduce(vcat,predicted)
    else
        predicted_out = reduce(hcat,predicted)
    end
    return predicted_out
end

# Accumulates and stiches slices (GPU)
function accum_parts(model::Chain,input_data::CuArray{Float32,4},
        num_parts::Int64,offset::Int64)
    input_size = size(input_data)
    max_value = maximum(input_size)
    ind_max = findfirst(max_value.==input_size)
    ind_split = convert(Int64,floor(max_value/num_parts))
    predicted = Vector{CuArray{Float32,4}}(undef,0)
    for j = 1:num_parts
        temp_data,correct_size,offset_add =
            prepare_data(input_data,ind_max,max_value,offset,num_parts,ind_split,j)
        temp_predicted = model(temp_data)
        temp_predicted =
            fix_size(temp_predicted,num_parts,correct_size,ind_max,offset_add,j)
        push!(predicted,collect(temp_predicted))
        CUDA.unsafe_free!(temp_predicted)
    end
    if ind_max==1
        predicted_out = reduce(vcat,predicted)
    else
        predicted_out = reduce(hcat,predicted)
    end
    return predicted_out
end

# Runs data thorugh a neural network
function forward(model::Chain,input_data::Array{Float32};
        num_parts::Int64=1,offset::Int64=0,use_GPU::Bool=true)
    if use_GPU
        input_data_gpu = CuArray(input_data)
        model = move(model,gpu)
        if num_parts==1
            predicted = collect(model(input_data_gpu))
        else
            predicted = collect(accum_parts(model,input_data_gpu,num_parts,offset))
        end
    else
        if num_parts==1
            predicted = model(input_data)
        else
            predicted = accum_parts(model,input_data,num_parts,offset)
        end
    end
    return predicted::Array{Float32,4}
end