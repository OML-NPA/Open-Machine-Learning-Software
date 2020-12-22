
function get_data_main(data::Master_data,fields,inds...)
    fields = fix_QML_types(fields)
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if !(isempty(inds))
        inds = fix_QML_types(inds[1])
        for i = 1:length(inds)
            data = data[inds[i]]
        end
    end
    return data
end
get_data(fields,inds...) = get_data_main(master_data,fields,inds...)

function set_data_main(master_data::Master_data,fields::QML.QListAllocated,args...)
    data = settings
    fields = fix_QML_types(fields)
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    values = Array{Any}(undef,length(args))
    for i=1:length(args)
        values[i] = fix_QML_types(args[i])
    end
    if length(args)==1
        value = fix_QML_types(args[1])
    elseif length(args)==2
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]] = args[2]
    elseif length(args)==3
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]][args[2]] = args[3]
    end
    setproperty!(data, Symbol(fields[end]), value)
    return
end
set_data(fields,value,args...) = set_data_main(master_data,fields,value,args...)

function get_settings_main(settings::Settings,fields,inds...)
    data = settings
    fields = fix_QML_types(fields)
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if !(isempty(inds))
        inds = fix_QML_types(inds[1])
        for i = 1:length(inds)
            data = data[inds[i]]
        end
    end
    return data
end
get_settings(fields,inds...) = get_settings_main(settings,fields,inds...)

function set_settings_main(settings::Settings,fields::QML.QListAllocated,args...)
    data = settings
    fields = String.(QML.value.(fields))
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    values = Array{Any}(undef,length(args))
    for i=1:length(args)
        values[i] = fix_QML_types(args[i])
    end
    if length(args)==1
        value = fix_QML_types(args[1])
    elseif length(args)==2
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]] = args[2]
    elseif length(args)==3
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]][args[2]] = args[3]
    end
    setproperty!(data, Symbol(fields[end]), value)
    return
end
set_settings(fields,value,args...) = set_settings_main(settings,fields,value,args...)

function save_settings_main(settings::Settings)
    BSON.@save("config.bson",settings)
end
save_settings() = save_settings_main(settings)

function load_settings!(settings)
    settings = BSON.load("config.bson")[:settings]
end
load_settings() = load_settings!(settings)

function reset(field)
    var = get_data(field)
    if var isa Array
        var = similar(var,0)
    elseif var isa Number
        var = zero(typeof(var))
    elseif var isa String
        var = ""
    end
end

function resetproperty!(datatype,field)
    var = getproperty(datatype,field)
    if var isa Array
        var = similar(var,0)
    elseif var isa Number
        var = zero(typeof(var))
    elseif var isa String
        var = ""
    end
    setproperty!(datatype,field,var)
end

function info(fields)
    @info get_data(fields)
end

function fix_QML_types(var)
    if var isa AbstractString
        return String(var)
    elseif var isa Integer
        return Int64(var)
    elseif var isa AbstractFloat
        return Float64(var)
    elseif var isa QML.QListAllocated
        return fix_QML_types.(QML.value.(var))
    elseif var isa Tuple
        return fix_QML_types.(var)
    else
        return var
    end
end

function set_output_main(model_data::Model_data,fields::QML.QListAllocated,ind,value)
    ind = fix_QML_types(ind)
    value = fix_QML_types(value)
    fields = fix_QML_types(fields)
    data = model_data.features[ind].Output
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    setproperty!(data, Symbol(fields[end]), value)
    return
end
set_output(fields,ind,value) = set_output_main(model_data,fields,ind,value)

function get_output_main(model_data::Model_data,fields::QML.QListAllocated,ind)
    ind = fix_QML_types(ind)
    fields = fix_QML_types(fields)
    data = model_data.features[ind].Output
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    return data
end
get_output(fields,ind) = get_output_main(model_data,fields,ind)

function get_image_main(master_data::Master_data,model_data,fields,
        img_size,inds...)
    image = collect(get_data(fields,inds...))
    if isempty(image)
        master_data.image = ARGB32.(image)
        return [0,0]
    end
    img_size = fix_QML_types(img_size)
    inds = findall(img_size.!=0)
    if !isempty(inds)
        r = minimum(map(x-> img_size[x]/size(image,x),inds))
        image = imresize(image, ratio=r)
    end
    master_data.image = ARGB32.(image)
    return [size(image)...]
end
get_image(fields,img_size,inds...) =
    get_image_main(master_data,model_data,fields,img_size,inds...)

function display_image(buffer::Array{UInt32, 1},
                      width32::Int32,
                      height32::Int32)
    width = width32
    height = height32
    buffer = reshape(buffer, width, height)
    buffer = reinterpret(ARGB32, buffer)
    image = master_data.image
    if size(buffer)==reverse(size(image))
        buffer .= transpose(ARGB32.(image))
    end
    return
end

function save_model_main(model_data,url)
  BSON.@save(String(url),model_data)
end
save_model(url) = save_model_main(model_data,url)

function load_model_main(model_data,url)
  data = BSON.load(String(url))
  if haskey(data,:model_data)
      copystruct!(model_data,data[:model_data])
      return true
  else
      return false
  end
end
load_model(url) = load_model_main(model_data,url)
