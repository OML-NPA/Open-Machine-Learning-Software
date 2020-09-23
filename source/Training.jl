using ImageCore, LocalFilters, ImageFiltering, ImageTransformations
using FileIO
import Base.any
import ImageSegmentation.label_components

function areaopen(im::BitArray,area::Real)
    im_segm = label_components(im).+1
    im_segm[im] .= 0
    labels = unique(im_segm)
    labels = labels[labels.!=0]
    for i=1:length(labels)
        if sum(.==(im,labels[i]))<area
            im[im_segm==labels(i)] = false
        end
    end
    return im
end

function perim(array::BitArray)
    er = erode(array,3)
    return xor.(array,er)
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
    return filter(x -> isdir(joinpath(dir, x)),
        readdir(dir))
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

pix_fr_lim = 0.1
pix_num = 160
labels = [(0,256,0),(256,256,0)]
labels_incl = [[2],[]]
border = [true,false]
parent_imgs = "Batch/Images"
parent_labels = "Batch/Labels"

function process_images_labels(parent_imgs,parent_labels,labels,
    labels_incls,border,pix_fr_lim,pix_num,num_angles)

    dirs_imgs = getdirs(parent_imgs)
    dirs_labels = getdirs(parent_labels)
    dirs = intersect(dirs_imgs,dirs_labels)
    if length(dirs)==0
        dirs = [""]
    end
    data_imgs = Array{Float32}(undef,0)
    data_labels = Array{BitArray}(undef,0)
    for k = 1:length(dirs)
        files_imgs,files_labels = get_files_imgs_labels(parent_imgs,
            parent_labels,dirs[k])
        for l = 1:length(files_imgs)
            url_imgs = string(parent_imgs,"/",files_imgs[l])
            url_labels = string(parent_labels,"/",files_labels[l])
            img,labels_bool = get_images_labels(url_imgs,url_labels,cnt)
            angles = range(0,stop=2*pi,length=num_angles+1)
            angles = angles[1:end-1]
            lim = pix_num^2*size(labels_bool,3)*pix_fr_lim
            imgs_out = Array{Float32}(undef,0)
            labels_out = Array{BitArray}(undef,0)
            augment(imgs_out,labels_out,img,labels,angles)
        end
        push!(data_imgs,imgs_out)
        push!(data_labels,labels_out)
    end
    data_imgs = cat(data_imgs...,dims=4)
    data_labels = cat(data_labels...,dims=4)

    # Functions
    function rotate_images_labels(img,labels,angle)
        if angle!=0
            img2 = imrotate(img,angle, axes(labels[:,:,i]))
            replace_nan!(img2)
            labels2 = BitArray(undef,size(img2)...,size(labels,3))
            for i = 1:size(labels_bool,3)
                temp = imrotate(labels[:,:,i],angle,
                    axes(labels[:,:,i]))
                labels2[:,:,i] = temp.>0
            end
            return(img2,labels2)
        else
            return(img,labels)
        end
    end

    function get_images_labels(url_imgs,url_labels,cnt)
        img = channelview(float.(Gray.(load(url_imgs))))
        labelimg = RGB.(load(url_labels))
        field = dilate(imfilter(img.<0.3, Kernel.gaussian(4)).>0.5,20)
        field = .!(areaopen(field,30000))
        field_area = sum(field)
        field_perim = perim(field)
        circularity = (4*pi*field_area)/(field_perim^2)
        if circularity<0.7
            row_bool = any(field,1)
            col_bool = any(field,2)
            col1 = findfirst(col_bool)[1]
            col2 = findlast(col_bool)[1]
            row1 = findfirst(row_bool)[1]
            row2 = findlast(row_bool)[1]
            img = img[row1:row2,col1:col2]
            labelimg = labelimg[row1:row2,col1:col2]
        end
        img = rescale(img,(0,1))

        labels = map(x->RGB((n0f8.(./(x,256)))...),labels)
        labels_bool = fill!(BitArray(undef, size(labelimg)...,
            length(labels)+sum(border)),0)
        num = size(labels,1)
        for i=1:num
            labels_bool[:,:,i] = .==(labelimg,labels[i])
        end
        for i=1:num
            for j=1:length(labels_incl[i])
                labels_bool[:,:,i] = .|(labels_bool[:,:,i],
                    labels_bool[:,:,labels_incl[i][j]])
            end
        end
        for i=1:num
            if border[i]
                labels_bool[:,:,num] = dilate(perim(labels_bool[:,:,i]),5)
            end
        end
        return(img,labels_bool)
    end

    function get_files_imgs_labels(parent_imgs,parent_labels,dir)
        files_imgs = getfiles(string(parent_imgs,"/",dir))
        files_labels = getfiles(string(parent_labels,"/",dir))
        filenames_imgs = remove_ext(files_imgs)
        filenames_labels = remove_ext(files_labels)
        inds1, inds2 = intersect_inds(filenames_labels, filenames_imgs)
        files_imgs = files_imgs[inds1]
        files_labels = files_labels[inds2]
        return (files_imgs,files_labels)
    end

    function augment(imgs_out,labels_out,img,labels,angles)
        for g = 1:length(angles)
            img2,labels2 = rotate_images_labels(img,labels,angles[g])
            num1 = Int64(floor(size(labels2,1)/(pix_num*0.9)))
            num2 = Int64(floor(size(labels2,2)/(pix_num*0.9)))
            step1 = Int64(floor(size(labels2,1)/num1))
            step2 = Int64(floor(size(labels2,2)/num2))
            num_batch = 2*(num1-1)*(num2-1)
            imgs_temp = Array{Float32}(undef,pix_num,pix_num,1,num_batch)
            labels_temp = BitArray(undef,pix_num,pix_num,size(labels,3),
                num_batch)
            cnt = 1
            for h = 1:2
                if h==1
                    img3 = img2
                    labels3 = labels2
                elseif h==2
                    img3 = reverse(img2, dims = 2)
                    labels3 = reverse(labels2, dims = 2)
                end
                for i = 1:num1-1
                    for j = 1:num2-1
                        ymin = (i-1)*step1+1;
                        xmin = (j-1)*step2+1;
                        I1 = labels3[ymin:ymin+pix_num-1,xmin:xmin+pix_num-1,:]
                        if sum(I1)<lim
                            continue
                        end
                        I2 = img3[ymin:ymin+pix_num-1,xmin:xmin+pix_num-1,:]
                        labels_temp[:,:,:,cnt] = I1
                        imgs_temp[:,:,:,cnt] = I2
                        cnt = cnt + 1
                    end
                end
            end
            push!(imgs_out,imgs_temp[:,:,:,1:cnt-1])
            push!(labels_out,labels_temp[:,:,:,1:cnt-1])
        end
        push!(imgs_out,cat(imgs_out...,dims=4))
        push!(labels_out,cat(labels_out...,dims=4))
    end
end
