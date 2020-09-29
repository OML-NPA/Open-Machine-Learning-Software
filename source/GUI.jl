
using QML, JSON, BSON
include("Training.jl")
include("Customization.jl")

# QML variables and functions
dict = Dict{String,Any}()
layers = []
layers_QML = []

function update_layers_main(layers,layers_QML,dict,keys,values,ext...)
    dict = Dict{String,Any}()
    keys = QML.value.(keys)
    values = QML.value.(values)
    sizehint!(dict, length(keys))
    for i = 1:length(keys)
        var_str = values[i]
        var_num = tryparse(Float32, var_str)
        if var_num == nothing
          dict[keys[i]] = var_str
          if occursin(",", var_str) && !occursin("[", var_str)
             dict[keys[i]] = str2tuple(Int64,var_str)
          end
        else
          dict[keys[i]] = var_num
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
    layer_QML = Dict{String,Any}(keys .=> values)
    layer_QML["connections_up"] = dict["connections_up"]
    layer_QML["connections_down"] = dict["connections_down"]
    layer_QML["x"] = dict["x"]
    layer_QML["y"] = dict["y"]
    push!(layers, copy(dict))
    push!(layers_QML, copy(layer_QML))
end
function fixtypes(dict)
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
    layers_QML,dict,keys,values,ext...)

function str2tuple(type,str)
    ar = parse.(type, split(str, ","))
    return (ar...,)
end

function reset_layers_main(layers)
    layers = []
end
reset_layers() = reset_layers_main(layers)

function save_model_main(name,layers,layers_QML)
  layers = JSON.parse(JSON.json(layers))
  BSON.@save(name+".bson",layers,layers_QML)
end
save_model() = save_model_main(layers)

function load_model_main(layers,layers_QML,model_name)
  BSON.@load(model_name,"layers","layers_QML")
end
load_model(model_name) = load_model_main(layers,
    layers_QML,model_name)

@qmlfunction(reset_layers,update_layers,
    get_labels_colors,get_urls_imgs_labels,
    save_model)
load("GUI//Main.qml")
exec()
