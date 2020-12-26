
function get_urls_training_main(training::Training,training_data::Training_data)
    # Get reference to url accumulators
    url_imgs = training_data.url_imgs
    url_labels = training_data.url_labels
    # Empty url accumulators
    empty!(url_imgs)
    empty!(url_labels)
    # Get directories containing images and labels
    dir_imgs = training.images
    dir_labels = training.labels
    # Return if no directories
    if isempty(dir_imgs) || isempty(dir_labels)
        @info "empty urls"
        return nothing
    end
    # Get directories containing our images and labels
    dirs_imgs = getdirs(dir_imgs)
    dirs_labels = getdirs(dir_labels)
    # Keep only those present for both images and labels
    dirs = intersect(dirs_imgs,dirs_labels)
    # If no directories, then set empty string
    if length(dirs)==0
        dirs = [""]
    end
    # Collect urls to files
    for k = 1:length(dirs)
        # Get files in a directory
        files_imgs = getfiles(string(dir_imgs,"/",dirs[k]))
        files_labels = getfiles(string(dir_labels,"/",dirs[k]))
        # Remove extensions from files
        filenames_imgs = remove_ext(files_imgs)
        filenames_labels = remove_ext(files_labels)
        # Intersect file names
        inds1, inds2 = intersect_inds(filenames_labels, filenames_imgs)
        # Keep files present for both images and labels
        files_imgs = files_imgs[inds1]
        files_labels = files_labels[inds2]
        # Push urls into accumulators
        for l = 1:length(files_imgs)
            push!(url_imgs,string(dir_imgs,"/",files_imgs[l]))
            push!(url_labels,string(dir_labels,"/",files_labels[l]))
        end
    end
    return nothing
end
get_urls_training() =
    get_urls_training_main(training,training_data)

function get_image(url_img::String)
    img::Array{RGB{N0f8},2} = load(url_img)
    return img
end

function get_label(url_label::String)
    label::Array{RGB{N0f8},2} = load(url_label)
    return label
end

function load_images(source::Union{Training_data,Analysis_data})
    url_imgs = source.url_imgs
    num = length(url_imgs)
    imgs = Vector{Array{RGB{N0f8},2}}(undef,num)
    for i = 1:num
        imgs[i] = get_image(url_imgs[i])
    end
    return imgs
end

function load_labels(training_data::Training_data)
    url_labels = training_data.url_labels
    num = length(url_labels)
    labels = Vector{Array{RGB{N0f8},2}}(undef,num)
    for i = 1:num
        labels[i] = get_label(url_labels[i])
    end
    return labels
end

# Convert images to grayscale Array{Float32,2}
function image_to_gray_float(image::Array{RGB{Normed{UInt8,8}},2})
    return collect(channelview(float.(Gray.(image))))
end

# Convert images to RGB Array{Float32,3}
function image_to_rgb_float(image::Array{RGB{Normed{UInt8,8}},2})
    return collect(channelview(float.(image)))
end

# Convert images to BitArray{3}
function label_to_bool(labelimg::Array{RGB{Normed{UInt8,8}},2},
        labels_color::Vector{Vector{Float64}},labels_incl::Vector{Vector{Int64}},
        border::Vector{Bool})
    colors = map(x->RGB((n0f8.(./(x,255)))...),labels_color)
    num = length(colors)
    num_borders = sum(border)
    inds_borders = findall(border)
    label = fill!(BitArray{3}(undef, size(labelimg)...,
        num + num_borders),0)
    for i=1:num
        label[:,:,i] = .==(labelimg,colors[i])
    end
    for i=1:num
        for j=1:length(labels_incl[i])
            label[:,:,i] = .|(label[:,:,i],
                label[:,:,labels_incl[i][j]])
        end
    end
    for j=1:length(inds_borders)
        dil = dilate(perim(label[:,:,inds_borders[j]]),5)
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
        inds = findall(feature_names[i].==feature_parents)
        labels_incl[i] = inds
    end
    return labels_color,labels_incl,border
end

function correct_view(img::Array{Float32,2},label::Array{RGB{Normed{UInt8,8}},2})
    field = dilate(imfilter(img.<0.3, Kernel.gaussian(4)).>0.5,20)
    areaopen!(field,30000)
    field = .!(field)
    field_area = sum(field)
    field_perim = sum(perim(field))/1.25
    circularity = (4*pi*field_area)/(field_perim^2)
    if circularity>0.9
        row_bool = any(field,1)
        col_bool = any(field,2)
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

# Rotate Array{Float32}
function rotate_img(img::Array{Float32,2},angle_val::Float64)
    if angle!=0
        img_out = imrotate(img,angle_val,axes(img))
        replace_nan!(img_out)
        return(img_out)
    else
        return(img)
    end
end

# Rotate BitArray
function rotate_img(img::BitArray{3},angle_val::Float64)
    if angle!=0
        img_out = copy(img)
        for i = 1:size(img,3)
            temp = imrotate(img[:,:,i],angle_val,axes(img[:,:,i]))
            replace_nan!(temp)
            img_out[:,:,i] = temp.>0
        end
        return(img_out)
    else
        return(img)
    end
end

# Augments images using rotation and mirroring
function augment(k::Int64,img::Array{Float32,2},label::BitArray{3},
        num_angles::Int64,pix_num::Tuple{Int64,Int64},min_fr_pix::Float64)
    lim = prod(pix_num)*min_fr_pix
    angles = range(0,stop=2*pi,length=num_angles+1)
    angles = angles[1:end-1]
    num = length(angles)
    imgs_out = Vector{Vector{Array{Float32,3}}}(undef,num)
    labels_out = Vector{Vector{BitArray{3}}}(undef,num)
    for g = 1:num
        angle_val = angles[g]
        img2 = rotate_img(img,angle_val)
        label2 = rotate_img(label,angle_val)
        num1 = Int64(floor(size(label2,1)/(pix_num[1]*0.9)))
        num2 = Int64(floor(size(label2,2)/(pix_num[2]*0.9)))
        step1 = Int64(floor(size(label2,1)/num1))
        step2 = Int64(floor(size(label2,2)/num2))
        num_batch = 2*(num1-1)*(num2-1)
        img_temp = Vector{Array{Float32}}(undef,0)
        label_temp = Vector{BitArray{3}}(undef,0)
        for h = 1:2
            if h==1
                img3 = img2
                label3 = label2
            elseif h==2
                img3 = reverse(img2, dims = 2)
                label3 = reverse(label2, dims = 2)
            end
            for i = 1:num1-1
                for j = 1:num2-1
                    ymin = (i-1)*step1+1;
                    xmin = (j-1)*step2+1;
                    I1 = label3[ymin:ymin+pix_num[1]-1,xmin:xmin+pix_num[2]-1,:]
                    if sum(I1)<lim
                        continue
                    end
                    I2 = img3[ymin:ymin+pix_num[1]-1,xmin:xmin+pix_num[2]-1,:]
                    push!(label_temp,I1)
                    push!(img_temp,I2)
                end
            end
        end
        imgs_out[g] = img_temp
        labels_out[g] = label_temp
    end
    imgs_out_flat = reduce(vcat,imgs_out)
    labels_out_flat = reduce(vcat,labels_out)
    data_out = (imgs_out_flat,labels_out_flat)
    return data_out
end

# Use border data to better separate objects
function apply_border_data_main(data_in::BitArray{3},model_data::Model_data)
    labels_color,labels_incl,border = get_feature_data(model_data.features)
    inds_border = findall(border)
    if inds_border==nothing
        return data_in
    end
    num_border = length(inds_border)
    num_feat = length(model_data.features)
    data = BitArray{3}(undef,size(data_in)[1:2]...,num_border)
    for i = 1:num_border
        ind_feat = inds_border[i]
        ind_border = num_feat + ind_feat
        data_feat_bool = data_in[:,:,ind_feat]
        data_feat = convert(Array{Float32},data_feat_bool)
        data_border = data_in[:,:,ind_border]
        border_bool = data_border
        skel = thinning(border_bool)
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
    end
    return data
end
apply_border_data(data_in) = apply_border_data_main(data_in,model_data)
