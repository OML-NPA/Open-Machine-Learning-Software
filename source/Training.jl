
# Helper functions
function areaopen(im::BitArray,area::Real)
    im_segm = label_components(im).+1
    im_segm[im] .= 0
    labels_color = unique(im_segm)
    labels_color = labels_color[labels_color.!=0]
    for i=1:length(labels_color)
        if sum(.==(im,labels_color[i]))<area
            im[im_segm==labels_color(i)] = false
        end
    end
    return im
end

function erode(array::BitArray,num::Int64)
    array2 = copy(array)
    for i=1:num
        erode!(array2)
    end
    return(array2)
end

function dilate(array::BitArray,num::Int64)
    array2 = copy(array)
    for i=1:num
        dilate!(array2)
    end
    return(array2)
end

function arsplit(ar,dim)
    type = typeof(ar[1])
    dim2 = dim==1 ? 2 : 1
    ar_out = []
    if dim==1
        for i=1:size(ar,dim)
            push!(ar_out,ar[i,:])
        end
    else
        for i=1:size(ar,dim)
            push!(ar_out,ar[:,i])
        end
    end
    return ar_out
end

function perim(array::BitArray)
    array2 = copy(array)
    array2[1:end,1] .= 0
    array2[1:end,end] .= 0
    array2[1,1:end] .= 0
    array2[end,1:end] .= 0
    er = erode(array2,1)
    return xor.(array2,er)
end

function any(array::BitArray,dim)
    vec = BitArray(undef, size(array,dim), 1)
    if dim==1
        for i=1:length(vec)
            vec[i] = any(array[i,:])
        end
    elseif dim==2
        for i=1:length(vec)
            vec[i] = any(array[:,i])
        end
    elseif dim==3
        for i=1:length(vec)
            vec[i] = any(array[:,:,i])
        end
    end
    return vec
end

function rescale(array,r::Tuple)
    r = Float32.(r)
    min_val = minimum(array)
    max_val = maximum(array)
    array = array.*((r[2]-r[1])/(max_val-min_val)).-min_val.+r[1]
end

function replace_nan!(x)
    type = typeof(x[1])
    for i = eachindex(x)
        if isnan(x[i])
            x[i] = zero(type)
        end
    end
end

function getdirs(dir)
    return filter(x -> isdir(joinpath(dir, x)),readdir(dir))
end

function getfiles(dir)
    return filter(x -> !isdir(joinpath(dir, x)),
        readdir(dir))
end

function remove_ext(files)
    filenames = copy(files)
    for i=1:length(files)
        chars = collect(files[i])
        ind = findfirst(chars.=='.')
        filenames[i] = String(chars[1:ind-1])
    end
    return filenames
end

function intersect_inds(ar1,ar2)
    inds1 = Array{Int64,1}(undef, 0)
    inds2 = Array{Int64,1}(undef, 0)
    for i=1:length(ar1)
        inds_log = ar2.==ar1[i]
        if any(inds_log)
            push!(inds1,i)
            push!(inds2,findfirst(inds_log))
        end
    end
    return (inds1, inds2)
end

# QML functions
function get_urls_imgs_labels_main(url_imgs,url_labels,
        parent_imgs,parent_labels,type)
    dirs_imgs = getdirs(parent_imgs)
    dirs_labels = getdirs(parent_labels)
    dirs = intersect(dirs_imgs,dirs_labels)
    if length(dirs)==0
        dirs = [""]
    end
    for k = 1:length(dirs)
        if type=="segmentation"
            files_imgs = getfiles(string(parent_imgs,"/",dirs[k]))
            files_labels = getfiles(string(parent_labels,"/",dirs[k]))
            filenames_imgs = remove_ext(files_imgs)
            filenames_labels = remove_ext(files_labels)
            inds1, inds2 = intersect_inds(filenames_labels, filenames_imgs)
            files_imgs = files_imgs[inds1]
            files_labels = files_labels[inds2]
            for l = 1:length(files_imgs)
                push!(url_imgs,string(parent_imgs,"/",files_imgs[l]))
                push!(url_labels,string(parent_labels,"/",files_labels[l]))
            end
        else
            files_imgs = getfiles(string(parent_imgs,"/",dirs[k]))
            filenames_imgs = remove_ext(files_imgs)
            for l = 1:length(files_imgs)
                push!(url_imgs,string(parent_imgs,"/",files_imgs[l]))
            end
        end
    end
end
get_urls_imgs_labels(parent_imgs,parent_labels,type) =
    get_urls_imgs_labels_main(url_imgs,url_labels,
    parent_imgs,parent_labels,type)

function process_images_labels_main(data_imgs,data_labels,url_imgs,
        url_labels,labels_color,labels_incl,border,
        min_fr_pix,pix_num,num_angles,type)

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

        lim = pix_num^2*min_fr_pix
        angles = range(0,stop=2*pi,length=num_angles+1)
        angles = angles[1:end-1]
        imgs_out = []
        labels_out = []
        for g = 1:length(angles)
            img2 = rotate_img(img,angles[g])
            label2 = rotate_img(label,angles[g])
            num1 = Int64(floor(size(label2,1)/(pix_num*0.9)))
            num2 = Int64(floor(size(label2,2)/(pix_num*0.9)))
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
                        I1 = label3[ymin:ymin+pix_num-1,xmin:xmin+pix_num-1,:]
                        if sum(I1)<lim
                            continue
                        end
                        I2 = img3[ymin:ymin+pix_num-1,xmin:xmin+pix_num-1,:]
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
    resize!(data_imgs,length(temp_imgs))
    resize!(data_labels,length(temp_labels))
    data_imgs .= temp_imgs
    data_labels .= temp_labels
    return nothing
end
process_images_labels(labels_color,labels_incl,border,
        min_fr_pix,pix_num,num_angles,type) =
    process_images_labels_main(data_imgs,data_labels,url_imgs,
            url_labels,labels_color,labels_incl,border,
            min_fr_pix,pix_num,num_angles,type)


function get_labels_colors_main(url_labels::Array{String})
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
get_labels_colors() = get_labels_colors_main(url_labels)

function get_labels_colors_main(url_labels::Array{String})
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
get_labels_colors() = get_labels_colors_main(url_labels)

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

function update_layers_main(layers,dict,keys,values,ext...)
    dict = Dict{String,Any}()
    keys = QML.value.(keys)
    values = QML.value.(values)
    sizehint!(dict, length(keys))
    for i = 1:length(keys)
        var = values[i]
        if var isa QML.QListAllocated
            temp = QML.value.(var)
            dict[keys[i]] = temp
        elseif var isa Number
            dict[keys[i]] = var
        else
            var = String(var)
            var_num = tryparse(Float64, var)
            if var_num == nothing
              dict[keys[i]] = var
              if occursin(",", var) && !occursin("[", var)
                 dict[keys[i]] = str2tuple(Int64,var)
              end
            else
              dict[keys[i]] = var_num
            end
        end
    end
    if length(ext) != 0
        for i = 1:2:length(ext)
            if ext[i+1] isa Float64 || ext[i+1] isa Float32 ||
                    ext[i+1] isa String
                dict[ext[i]] = ext[i+1]
            else
                dict[ext[i]] = QML.value.(ext[i+1])
                if isa(dict[ext[i]],Array) && !isempty(dict[ext[i]]) &&
                        !isa(dict[ext[i]][1], Real)
                    ar = []
                    for j = 1:length(dict[ext[i]])
                        push!(ar,QML.value.(dict[ext[i]][j]))
                    end
                    dict[ext[i]] = ar
                end
            end
        end
    end
    dict = fixtypes(dict)
    push!(layers, copy(dict))
end
function fixtypes(dict::Dict)
    for key in [
        "filters",
        "dilationfactor",
        "stride",
        "inputs",
        "outputs",
        "dimension"]
        if haskey(dict, key)
            dict[key] = Int64(dict[key])
        end
    end
    if haskey(dict, "size")
        if length(dict["size"])==2
            dict["size"] = (dict["size"]...,1)
        end
    end
    for key in ["filtersize", "poolsize","newsize"]
        if haskey(dict, key)
            if length(dict[key])==1 && !(dict[key] isa Array)
                dict[key] = Int64(dict[key])
                dict[key] = (dict[key], dict[key])
            else
                dict[key] = (dict[key]...,)
            end
        end
    end
    return dict
end
update_layers(keys,values,ext...) = update_layers_main(layers,
    dict,keys,values,ext...)

function str2tuple(type::Type,str::String)
    if occursin("[",str)
        str2 = split(str,"")
        str2 = join(str2[2:end-1])
        ar = parse.(Int64, split(str2, ","))
    else
        ar = parse.(type, split(str, ","))
    end
    return (ar...,)
end

function reset_layers_main(layers)
    layers = empty!(layers)
end
reset_layers() = reset_layers_main(layers)

function save_model_main(name,layers)
  #=function fix_jlqml_error(layers)
      istuple = []
      for i = 1:length(layers)
        vals = collect(values(layers[1]))
        push!(istuple,findall(isa.(vals,Tuple)))
      end
      layers = JSON.parse(JSON.json(layers))
      for i = 1:length(layers)
        k = collect(keys(layers[i]))
        inds = istuple[i]
        for j = 1:length(inds)
            layers[i][k[inds[j]]] = (layers[i][k[inds[j]]]...,)
        end
      end
  end=#
  #fix_jlqml_error(layers)
  istuple = []
  for i = 1:length(layers)
    vals = collect(values(layers[i]))
    push!(istuple,findall(isa.(vals,Tuple)))
  end
  open(string(name,".model"),"w") do f
    JSON.print(f,(layers,istuple))
  end
  #BSON.@save(string(name,".bson"),layers)
end
save_model(name) = save_model_main(name,layers)

function load_model_main(layers,url)
    layers = empty!(layers)
    try
      temp = []
      open(string(url), "r") do f
        temp = JSON.parse(f)  # parse and transform data
      end
      for i =1:length(temp[1])
        push!(layers,copy(temp[1][i]))
      end
      istuple = temp[2]
      for i = 1:length(layers)
        k = collect(keys(layers[i]))
        inds = istuple[i]
        for j = 1:length(inds)
            layers[i][k[inds[j]]] = (layers[i][k[inds[j]]]...,)
        end
      end
      return true
    catch
      return false
    end
  #=data = BSON.load(String(url))
  if haskey(data,:layers)
      push!(layers,data[:layers]...)
      return true
  else
      return false
  end=#
end
load_model(url) = load_model_main(layers,url)
