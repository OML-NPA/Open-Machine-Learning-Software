
using QML, JSON, BSON
include("Training.jl")
include("Customization.jl")

# QML variables and functions
dict = Dict{String,Any}()
layers = []

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
  open(string(name,".json"),"w") do f
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

@qmlfunction(
    # Model saving
    reset_layers,
    update_layers,
    save_model,
    # Model loading
    load_model,
    model_count,
    model_properties,
    model_get_property,
    # Data loading
    get_urls_imgs_labels,
    get_labels_colors
)

load("GUI//Main.qml")
exec()
