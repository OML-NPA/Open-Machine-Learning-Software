
#---Struct related functions
function dict_to_struct!(obj,dict::Dict;skip=[])
    ks = [keys(dict)...]
    for i = 1:length(ks)
        ks_cur = ks[i]
        sym = Symbol(ks_cur)
        value = dict[ks_cur]
        if value isa Dict
            dict_to_struct!(getproperty(obj,sym),value;skip=skip)
        else
            if !(ks_cur in skip) && hasfield(typeof(obj),sym)
                setproperty!(obj,sym,value)
            end
        end
    end
end

function copystruct!(struct1,struct2)
  ks = fieldnames(typeof(struct1))
  for i = 1:length(ks)
    value = getproperty(struct2,ks[i])
    if value isa AbstractArray || value isa Tuple ||
            value isa Number || value isa AbstractString
        setproperty!(struct1,ks[i],value)
    else
        copystruct!(getproperty(struct1,ks[i]),
            getproperty(struct2,ks[i]))
    end
  end
end

#---Image processing related functions
function areaopen!(im::BitArray{2},area::Int64)
    im_segm = label_components(im)
    num = maximum(im_segm)
    for i=1:num
        mask = im_segm.==i
        if sum(mask)<area
            im[mask] .= false
        end
    end
    return
end

function remove_spurs!(img::BitArray{2})
    img_float = convert(Array{Float32,2},img)
    kernel = centered(ones(Float32,3,3))
    spurs = imfilter(img_float,kernel)
    spurs = (spurs.<2) .& (img.!=0)
    inds = findall(spurs)
    for i=1:length(inds)
        ind = inds[i]
        while true
            img[ind] = false
            ind_tuple = Tuple(ind)
            neighbors = img[ind_tuple[1]-1:ind_tuple[1]+1,
                            ind_tuple[2]-1:ind_tuple[2]+1]
            inds_temp = findall(neighbors)
            if length(inds_temp)==0 || length(inds_temp)>1
                break
            else
                inds_temp = Tuple(inds_temp[1]) .-2
                ind = CartesianIndex(ind_tuple .+ inds_temp)
            end
        end
    end
end

function component_intensity(components::Array{Int64},image::Array{Float32})
    num = maximum(components)
    intensities = Vector{Float32}(undef,num)
    for i = 1:num
        intensities[i] = mean(image[components.==i])
    end
    return intensities
end

function erode(array::BitArray{2},num::Int64)
    array2 = copy(array)
    for i=1:num
        erode!(array2)
    end
    return(array2)
end

function dilate(array::BitArray{2},num::Int64)
    array2 = copy(array)
    for i=1:num
        dilate!(array2)
    end
    return(array2)
end

function perim(array::BitArray{2})
    array2 = copy(array)
    array2[1:end,1] .= 0
    array2[1:end,end] .= 0
    array2[1,1:end] .= 0
    array2[end,1:end] .= 0
    er = erode(array2,1)
    return xor.(array2,er)
end

function rescale(array,r::Tuple)
    r = convert(Float32,r)
    min_val = minimum(array)
    max_val = maximum(array)
    array = array.*((r[2]-r[1])/(max_val-min_val)).-min_val.+r[1]
end

function segment_objects(components::Array{Int64,2},objects::BitArray{2})
    img_size = size(components)[1:2]
    initial_indices = findall(components.!=0)
    operations = [(0,1),(1,0),(0,-1),(-1,0),(1,-1),(-1,1),(-1,-1),(1,1)]
    new_components = copy(components)
    indices_out = initial_indices

    while length(indices_out)!=0
        indices_in = indices_out
        indices_accum = Vector{Vector{CartesianIndex{2}}}(undef,0)
        for i = 1:4
            target = repeat([operations[i]],length(indices_in))
            new_indices = broadcast((x,y) -> x .+ y,
                Tuple.(indices_in),target)
            objects_values = objects[indices_in]
            target = repeat([(0,0)],length(new_indices))
            nonzero_bool = broadcast((x,y) -> all(x .> y),
                new_indices,target)
            target = repeat([img_size],length(new_indices))
            correct_size_bool = broadcast((x,y) -> all(x.<img_size),
                new_indices,target)
            remove_incorrect = nonzero_bool .&
                correct_size_bool .& objects_values
            new_indices = new_indices[remove_incorrect]
            values = new_components[CartesianIndex.(new_indices)]
            new_indices_0_bool = values.==0
            new_indices_0 = map(x-> CartesianIndex(x),
                new_indices[new_indices_0_bool])
            indices_prev = indices_in[remove_incorrect][new_indices_0_bool]
            prev_values = new_components[CartesianIndex.(indices_prev)]
            new_components[new_indices_0] .= prev_values
            push!(indices_accum,new_indices_0)
        end
        indices_out = reduce(vcat,indices_accum)
    end
    return new_components
end

#---Padding
same(el_type::Type,row::Int64,col::Int64,vect::Array) = ones(el_type,row,col).*vect
same(el_type::Type,row::Int64,col::Int64,vect::CUDA.CuArray) =
    CUDA.ones(el_type,row,col).*vect
function pad(array::Array,padding::Vector,fun::Union{typeof(zeros),typeof(ones)})
    el_type = eltype(array)
    div_result = padding./2
    leftpad = Int64.(floor.(div_result))
    rightpad = Int64.(ceil.(div_result))
    if padding[1]!=0
        array = vcat(fun(el_type,leftpad[1],size(array,2)),
            array,fun(el_type,rightpad[1],size(array,2)))
    end
    if padding[2]!=0
        array = hcat(fun(el_type,size(array,1),leftpad[2]),
            array,fun(el_type,size(array,1),rightpad[2]))
    end
end
function pad(array::Union{AbstractArray{Float32},AbstractArray{Float64}},
        padding::Vector{Int64},fun::Union{typeof(same),typeof(zeros),typeof(ones)})
    el_type = eltype(array)
    div_result = padding./2
    leftpad = Int64.(floor.(div_result))
    rightpad = Int64.(ceil.(div_result))
    if padding[1]!=0
        vec1 = array[1,:]'
        vec2 = array[end,:]'
        array = vcat(fun(el_type,leftpad[1],size(array,2),vec1),
            array,fun(el_type,rightpad[1],size(array,2),vec2))
    else
        vec1 = array[:,1]
        vec2 = array[:,end]
        array = hcat(fun(el_type,size(array,1),leftpad[2],vec1),
            array,fun(el_type,size(array,1),rightpad[2],vec2))
    end
    return array
end

function conn(num::Int64)
    if num==4
        kernel = [false true false
                  true true true
                  false true false]
    else
        kernel = [true true true
                  true true true
                  true true true]
    end
    return kernel
end


#---Other boolean things
function allequal(itr::Union{Array,Tuple})
    return length(itr)==0 || all( ==(itr[1]), itr)
end

function allcmp(inds)
    for i = 1:length(inds)
        if inds[1][1] != inds[i][1]
            return false
        end
    end
    return true
end

function any(array::BitArray,dim::Int64)
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

anynan(x) = any(isnan.(x))

#---Other
function arsplit(ar::AbstractArray,dim::Int64)
    type = typeof(ar[1])
    dim2 = dim==1 ? 2 : 1
    ar_out = Vector{Vector{typeof(ar[1])}}(undef,size(ar,dim))
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

# Text of form "[n,n,...,n]", where n is a number to a tuple (n,n...,n)
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

# Tuple from array
function make_tuple(array::AbstractArray)
    return (array...,)
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

function remove_ext(files::Vector{String})
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

function time()
      date = string(now())
      date = date[1:19]
      date = replace(date,"T"=>" ")
      return date
end

function get_random_color(seed)
    Random.seed!(seed)
    rand(RGB{N0f8})
end

# Allows to use @info from GUI
function info(fields)
    @info get_data(fields)
end

cat3(A::AbstractArray) = cat(A; dims=Val(3))
cat3(A::AbstractArray, B::AbstractArray) = cat(A, B; dims=Val(3))
cat3(A::AbstractArray...) = cat(A...; dims=Val(3))

cat4(A::AbstractArray) = cat(A; dims=Val(4))
cat4(A::AbstractArray, B::AbstractArray) = cat(A, B; dims=Val(4))
cat4(A::AbstractArray...) = cat(A...; dims=Val(4))

gc() = GC.gc()
