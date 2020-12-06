
function get_urls_imgs_labels_main(training::Training,training_data::Training_data)
    url_imgs = training_data.url_imgs
    url_labels = training_data.url_labels
    empty!(url_imgs)
    empty!(url_labels)
    dir_imgs = training.images
    dir_labels = training.labels
    if isempty(dir_imgs) || isempty(dir_labels)
        @info "empty urls"
    end
    type = settings.Training.type
    dirs_imgs = getdirs(dir_imgs)
    dirs_labels = getdirs(dir_labels)
    dirs = intersect(dirs_imgs,dirs_labels)
    if length(dirs)==0
        dirs = [""]
    end
    for k = 1:length(dirs)
        if type=="segmentation"
            files_imgs = getfiles(string(dir_imgs,"/",dirs[k]))
            files_labels = getfiles(string(dir_labels,"/",dirs[k]))
            filenames_imgs = remove_ext(files_imgs)
            filenames_labels = remove_ext(files_labels)
            inds1, inds2 = intersect_inds(filenames_labels, filenames_imgs)
            files_imgs = files_imgs[inds1]
            files_labels = files_labels[inds2]
            for l = 1:length(files_imgs)
                push!(url_imgs,string(dir_imgs,"/",files_imgs[l]))
                push!(url_labels,string(dir_labels,"/",files_labels[l]))
            end
        else
            files_imgs = getfiles(string(dir_imgs,"/",dirs[k]))
            filenames_imgs = remove_ext(files_imgs)
            for l = 1:length(files_imgs)
                push!(url_imgs,string(dir_imgs,"/",files_imgs[l]))
            end
        end
    end
    return nothing
end
get_urls_imgs_labels() =
    get_urls_imgs_labels_main(training,training_data)

function get_image(url_img::String)
    img = RGB.(load(url_img))
    return img
end

function get_label(url_label::String)
    label = RGB.(load(url_label))
    return label
end

function load_images(training_data::Training_data)
    url_imgs = training_data.url_imgs
    num = length(url_imgs)
    imgs = Array{Any}(undef,num)
    for i = 1:num
        imgs[i] = get_image(url_imgs[i])
    end
    return imgs
end

function load_labels(training_data::Training_data)
    url_labels = training_data.url_labels
    num = length(url_labels)
    labels = Array{Any}(undef,num)
    for i = 1:num
        labels[i] = get_label(url_labels[i])
    end
    return labels
end

function image_to_float(image::Array{RGB{Normed{UInt8,8}},2};gray=true)
    if gray
        return collect(channelview(float.(Gray.(image))))
    else
        return collect(channelview(float.(image)))
    end
end

function label_to_float(labelimg::Array{RGB{Normed{UInt8,8}},2},
        labels_color::Vector{Vector{Float64}},labels_incl::Vector{Vector{Int64}},
        border::Vector{Bool})
    colors = map(x->RGB((n0f8.(./(x,255)))...),labels_color)
    num = length(colors)
    num_borders = sum(border)
    inds_borders = findall(border)
    label = fill!(BitArray(undef, size(labelimg)...,
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

function prepare_training_data_main(training::Training,training_data::Training_data,
    model_data::Model_data,progress::RemoteChannel,results::RemoteChannel)
    # Functions
    function correct_view(img::Array{Float32,2},label::Array{RGB{Normed{UInt8,8}},2})
        field = dilate(imfilter(img.<0.3, Kernel.gaussian(4)).>0.5,20)
        field = .!(areaopen(field,30000))
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

    function augment(k::Int64,img::Array{Float32,2},label::BitArray{3},
        num_angles::Int64,pix_num::Tuple{Int64,Int64},min_fr_pix::Float64)

        function rotate_img(img::Union{Array{Float32,2},BitArray},angle::Float64)
            if angle!=0
                img2 = copy(img)
                for i = 1:size(img,3)
                    temp = imrotate(img[:,:,i],angle,
                        axes(img[:,:,i]))
                    replace_nan!(temp)
                    if img2 isa BitArray
                        img[:,:,i] = temp.>0
                    end
                end
                return(img2)
            else
                return(img)
            end
        end

        lim = prod(pix_num)*min_fr_pix
        angles = range(0,stop=2*pi,length=num_angles+1)
        angles = angles[1:end-1]
        imgs_out = []
        labels_out = []
        num = length(angles)
        for g = 1:num
            img2 = rotate_img(img,angles[g])
            label2 = rotate_img(label,angles[g])
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
            push!(imgs_out,img_temp...)
            push!(labels_out,label_temp...)
        end
        return (imgs_out,labels_out)
    end

    # Code
    if isempty(model_data.features)
        put!(results, "Empty features")
    end
    data_input = []
    data_labels = []
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
    temp_imgs = Vector{Vector{Array{Float32,3}}}(undef,num)
    temp_labels = Vector{Vector{BitArray{3}}}(undef,num)
    put!(progress, num+1)
    type_segmentation = type=="segmentation"
    Threads.@threads for k = 1:num
        if isready(channels.training_data_modifiers)
            if fetch(channels.training_data_modifiers)[1]=="stop"
                take!(channels.training_data_modifiers)
                return nothing
            end
        end
        img = imgs[k]
        img = image_to_float(img,gray=true)
        label = labels[k]
        if type_segmentation
            #img,label = correct_view(img,label)
            label = label_to_float(label,labels_color,labels_incl,border)
            img,label = augment(k,img,label,num_angles,pix_num,min_fr_pix)
        end
        temp_imgs[k] = img
        temp_labels[k] = label
        put!(progress, 1)
    end
    if type_segmentation
        temp_imgs = vcat(temp_imgs...)
        temp_labels = vcat(temp_labels...)
    end
    resize!(data_input,length(temp_imgs))
    resize!(data_labels,length(temp_labels))
    data_input .= temp_imgs
    data_labels .= temp_labels
    put!(results, (data_input,data_labels))
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

    function prepare_validation_data_main(training_data::Training_data,
            features::Array,progress::RemoteChannel,results::RemoteChannel)
        put!(progress,3)
        images = load_images(training_data)
        put!(progress,1)
        labels = load_labels(training_data)
        put!(progress,1)
        if isempty(features)
            @info "empty features"
            return false
        end
        labels_color,labels_incl,border = get_feature_data(features)
        data_input = map(x->image_to_float(x,gray=true),images)
        data_labels = map(x->label_to_float(x,labels_color,labels_incl,border),labels)
        data = (images,labels,data_input,data_labels)
        put!(results,data)
        put!(progress,1)
        return nothing
    end
    function  prepare_validation_data_main2(training_data::Training_data,
            features::Array,progress::RemoteChannel,results::RemoteChannel)
        @everywhere training_data
        remote_do(prepare_validation_data_main,workers()[end],training_data,
        features,progress,results)
    end
    prepare_validation_data() = prepare_validation_data_main2(training_data,
        model_data.features,channels.validation_data_progress,
        channels.validation_data_results)

function apply_border_data_main(data_in::Array{Float32},model_data::Model_data)
    labels_color,labels_incl,border = get_feature_data(model_data.features)
    inds_border = findall(border)
    num_border = length(inds_border)
    num_feat = length(model_data.features)
    data = zeros(typeof(data_in[1]),size(data_in)[1:2]...,num_border)
    for i = 1:num_border
        ind_feat = inds_border[i]
        ind_border = num_feat + ind_feat
        data_feat_bool = data_in[:,:,ind_feat].>0.5
        data_feat = convert(Array{Float32},data_feat_bool)
        data_border = data_in[:,:,ind_border]
        border_bool = data_border.>0.5
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
        data[:,:,ind_feat] = convert(Array{Float32},segmented.>0)
    end
    return data
end
apply_border_data(data_in) = apply_border_data_main(data_in,model_data)

function get_labels_colors_main(training_data::Training_data,channels::Channels)
    url_labels = training_data.url_labels
    num = length(url_labels)
    put!(channels.training_labels_colors,num)
    colors_out = Vector{Vector{Vector{Float32}}}(undef,num)
    labelimgs = Vector{Array{RGB{Normed{UInt8,8}},2}}(undef,0)
    for i=1:num
        push!(labelimgs,RGB.(load(url_labels[i])))
    end
    Threads.@threads for i=1:num
            labelimg = labelimgs[i]
            unique_colors = unique(labelimg)
            ind = findfirst(unique_colors.==RGB.(0,0,0))
            deleteat!(unique_colors,ind)
            colors = channelview(float.(unique_colors))*255
            colors_out[i] = arsplit(colors,2)
            put!(channels.training_labels_colors,1)
    end
    colors_out = vcat(colors_out...)
    colors_out = unique(colors_out)
    put!(channels.training_labels_colors,colors_out)
    return
end
function get_labels_colors_main2(training_data::Training_data,channels::Channels)
    @everywhere training_data
    remote_do(get_labels_colors_main,workers()[end],training_data,channels)
end
get_labels_colors() = get_labels_colors_main2(training_data,channels)

model_count() = length(model_data.layers)
model_properties(index) = [keys(model_data.layers[index])...]
function model_get_property_main(model_data::Model_data,index,property_name)
    layer = model_data.layers[index]
    property = layer[property_name]
    if  isa(property,Tuple)
        property = join(property,',')
    end
    return property
end
model_get_property(index,property_name) =
    model_get_property_main(model_data,index,property_name)

function reset_layers_main(model_data::Model_data)
    empty!(model_data.layers)
end
reset_layers() = reset_layers_main(model_data::Model_data)

function update_layers_main(model_data::Model_data,keys,values,ext...)
    layers = model_data.layers
    keys = fix_QML_types(keys)
    values = fix_QML_types(values)
    ext = fix_QML_types(ext)
    dict = Dict{String,Any}()
    sizehint!(dict, length(keys))
    for i = 1:length(keys)
        var = values[i]
        if var isa String
            var_num = tryparse(Float64, var)
            if var_num == nothing
              if occursin(",", var) && !occursin("[", var)
                 dict[keys[i]] = str2tuple(Int64,var)
              else
                 dict[keys[i]] = var
              end
            else
              dict[keys[i]] = var_num
            end
        else
            dict[keys[i]] = var
        end
    end
    if length(ext)!=0
        for i = 1:2:length(ext)
            dict[ext[i]] = ext[i+1]
        end
    end
    dict = fixtypes(dict)
    push!(layers, copy(dict))
end
update_layers(keys,values,ext...) = update_layers_main(model_data::Model_data,
    keys,values,ext...)

function reset_features_main(model_data)
    empty!(model_data.features)
end
reset_features() = reset_features_main(model_data::Model_data)

function append_features_main(model_data::Model_data,name,colorR,colorG,colorB,border,parent)
    push!(model_data.features,Feature(String(name),
        Int64.([colorR,colorG,colorB]),Bool(border),String(parent)))
end
append_features(name,colorR,colorG,colorB,border,parent) =
    append_features_main(model_data,name,colorR,colorG,colorB,border,parent)

function update_features_main(model_data,index,name,colorR,colorG,colorB,border,parent)
    model_data.features[index] = Feature(String(name),Int64.([colorR,colorG,colorB]),
        Bool(border),String(parent))
end
update_features(index,name,colorR,colorG,colorB,border,parent) =
    update_features_main(model_data,index,name,colorR,colorG,colorB,border,parent)

function num_features_main(model_data::Model_data)
    return length(model_data.features)
end
num_features() = num_features_main(model_data::Model_data)

function get_feature_main(model_data::Model_data,index,fieldname)
    return getfield(model_data.features[index], Symbol(String(fieldname)))
end
get_feature_field(index,fieldname) = get_feature_main(model_data,index,fieldname)
