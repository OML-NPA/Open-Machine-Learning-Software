
function get_urls_imgs_labels_main(master)
    url_imgs = master.Training.url_imgs
    url_labels = master.Training.url_labels
    dir_imgs = master.Training.images
    dir_labels = master.Training.labels
    type = master.Training.type
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
end
get_urls_imgs_labels() =
    get_urls_imgs_labels_main(master)

function process_images_labels_main(master,features,model_data)
    url_imgs = master.Training.url_imgs
    url_labels = master.Training.url_labels
    data_input = master.Training.data_input
    data_labels = master.Training.data_labels
    # Functions
    function get_image(url_img)
        img = channelview(float.(Gray.(load(url_img))))
        return img
    end

    function get_label(url_label)
        label = RGB.(load(url_label))
        return label
    end

    function correct_label(labelimg,labels_color,labels_incl,border)
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
        for i=1:length(inds_borders)
            label[:,:,num+i] = dilate(perim(label[:,:,inds_borders[i]]),5)
        end
        return label
    end

    function correct_view(img,label)
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

    function augment(img,label,angles_num,pix_num,min_fr_pix)

        function rotate_img(img,angle)
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
        for g = 1:length(angles)
            img2 = rotate_img(img,angles[g])
            label2 = rotate_img(label,angles[g])
            num1 = Int64(floor(size(label2,1)/(pix_num[1]*0.9)))
            num2 = Int64(floor(size(label2,2)/(pix_num[2]*0.9)))
            #@info(num1)
            step1 = Int64(floor(size(label2,1)/num1))
            step2 = Int64(floor(size(label2,2)/num2))
            num_batch = 2*(num1-1)*(num2-1)
            img_temp = Vector{Array}(undef,0)
            label_temp = Vector{BitArray}(undef,0)
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
    type = master.Training.type
    options = master.Training.Options
    min_fr_pix = options.Processing.min_fr_pix
    num_angles = options.Processing.num_angles
    pix_num = model_data.input_size[1:2]
    labels_color = []
    border = []
    labels_incl = []
    names = []
    for i = 1:length(features)
        push!(names,features[i].name)
    end
    for i = 1:length(features)
        feature = features[i]
        push!(labels_color,feature.color)
        push!(border,feature.border)
        if isempty(feature.parent)
            push!(labels_incl,[])
        else
            push!(labels_incl,findfirst(feature.name.==names))
        end
    end
    # Code
    temp_imgs = []
    temp_labels = []
    for i = 1:length(url_imgs)
        img = get_image(url_imgs[i])
        label = get_label(url_labels[i])
        if type=="segmentation"
            img,label = correct_view(img,label)
            label = correct_label(label,labels_color,labels_incl,border)
            img,label = augment(img,label,num_angles,pix_num,min_fr_pix)
        end
        push!(temp_imgs,img)
        push!(temp_labels,label)
    end
    if type=="segmentation"
        temp_imgs = vcat(temp_imgs...)
        temp_labels = vcat(temp_labels...)
    end
    resize!(data_input,length(temp_imgs))
    resize!(data_labels,length(temp_labels))
    data_input .= temp_imgs
    data_labels .= temp_labels
    return nothing
end
process_images_labels() =
    process_images_labels_main(master,features,model_data)

function get_labels_colors_main(master)
    url_labels = master.Training.url_labels
    colors_out = []
    for i=1:length(url_labels)
        labelimg = RGB.(load(url_labels[i]))
        unique_colors = unique(labelimg)
        ind = findfirst(unique_colors.==RGB.(0,0,0))
        deleteat!(unique_colors,ind)
        colors = channelview(float.(unique_colors))*255
        if i==1
            colors_out = arsplit(colors,2)
        else
            colors_out = union(colors_out,arsplit(colors,2))
        end
    end
    return colors_out
end
get_labels_colors() = get_labels_colors_main(master)

model_count() = length(layers)
model_properties(index) = [keys(layers[index])...]
function model_get_property(index,property_name)
    layer = layers[index]
    property = layer[property_name]
    if  isa(property,Tuple)
        property = join(property,',')
    end
    return property
end

function reset_layers_main(layers)
    layers = empty!(layers)
end
reset_layers() = reset_layers_main(layers)

function update_layers_main(layers,keys,values,ext...)
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
update_layers(keys,values,ext...) = update_layers_main(layers,
    keys,values,ext...)

function reset_features_main(features)
    empty!(features)
end
reset_features() = reset_features_main(features)

function append_features_main(features,name,colorR,colorG,colorB,border,parent)
    push!(features,Features(String(name),Int64.([colorR,colorG,colorB]),
        Bool(border),String(parent)))
end
append_features(name,colorR,colorG,colorB,border,parent) =
    append_features_main(features,name,colorR,colorG,colorB,border,parent)

function update_features_main(features,index,name,colorR,colorG,colorB,border,parent)
    features[index] = Features(String(name),Int64.([colorR,colorG,colorB]),
        Bool(border),String(parent))
end
update_features(index,name,colorR,colorG,colorB,border,parent) =
    update_features_main(features,index,name,colorR,colorG,colorB,border,parent)

function num_features_main(features)
    return length(features)
end
num_features() = num_features_main(features)

function get_feature_main(features,index,fieldname)
    return getfield(features[index], Symbol(String(fieldname)))
end
get_feature_field(index,fieldname) = get_feature_main(features,index,fieldname)

function save_model_main(layers,features,model,model_data,url)
  BSON.@save(String(url),layers,features,model,model_data,model_data)
end
save_model(url) = save_model_main(layers,features,model,model_data,url)

function load_model_main(layers,features,url)
  global model, model_data
  layers = empty!(layers)
  data = BSON.load(String(url))
  if haskey(data,:layers)
      copy!(layers,data[:layers])
      copy!(features,data[:features])
      model = data[:model]
      model_data = data[:model_data]
      return true
  else
      return false
  end
end
load_model(url) = load_model_main(layers,features,url)
