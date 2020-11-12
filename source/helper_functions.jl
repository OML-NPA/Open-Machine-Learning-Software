
function dict_to_struct!(settings,dict::Dict;skip=[])
  ks = [keys(dict)...]
  for i = 1:length(ks)
    value = dict[ks[i]]
    if value isa Dict
      dict_to_struct!(getproperty(settings,Symbol(ks[i])),value;skip=skip)
    else
      if !(ks[i] in skip)
          setproperty!(settings,Symbol(ks[i]),value)
      end
    end
  end
end

function copy_struct!(struct1,struct2,skip_fields::Vector{Symbol})
  ks = fieldnames(typeof(struct1))
  for i = 1:length(ks)
    if ks[i] in skip_fields
        resetproperty!(struct1,ks[i])
        continue
    end
    value = getproperty(struct2,ks[i])
    if isstructtype(typeof(settings))
        copy_struct!(getproperty(struct1,ks[i]),
            getproperty(struct2,ks[i]),skip_fields)
    else
        setproperty!(struct1,ks[i],value)
    end
  end
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
    for key in ["filtersize", "poolsize"]
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

function copystruct!(struct1,struct2)
    fields = fieldnames(typeof(struct1))
    for i = 1:length(fields)
        setfield!(struct1,fields[i],getfield(struct2,fields[i]))
    end
end

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

anynan(x) = any(isnan.(x))

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

function num_cores()
    return Threads.nthreads()
end

function source_dir()
    return replace(pwd(), "\\" => "/")
end

function time()
      date = string(now())
      date = date[1:19]
      date = replace(date,"T"=>" ")
      return date
end
