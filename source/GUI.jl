
using QML
using Observables
using JSON

cd("C:\\Users\\a_ill\\Documents\\GitHub\\Deep-Data-Analysis\\source")

load("GUI//Main.qml")

# QML functions and vars
dict = Dict{String,Any}()
layers = []

function returnfolder(folder)
    folder = QString(folder)
    folder = folder[8:length(folder)]
    return (folder)
end

# ADD PARSING OF "x,x" TYPE VALUES
function returnmap(keys, values, ext...)
    global dict
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
            end
        end
    end
    dict = fixtypes(dict)
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
            @info dict["size"]
        end
    end
    for key in ["filtersize", "poolsize","newsize"]
        if haskey(dict, key)
            dict[key] = Int64(dict[key])
            if length(dict[key]) == 1
                dict[key] = (dict[key], dict[key])
            else
                dict[key] = (dict[key]...,)
            end
        end
    end
    return dict
end

function str2tuple(type,str)
    ar = parse.(type, split(str, ","))
    return (ar...,)
end

function resetlayers()
    global layers
    layers = []
end

function updatelayers()
    global layers
    global dict
    push!(layers, copy(dict))
end

@qmlfunction(returnfolder, returnmap, resetlayers, updatelayers)

exec()


function test()
  open("layers.json","w") do f
      JSON.print(f, layers)
  end
  layers = []
  open("layers.json", "r") do f
      global layers
      layers = JSON.parse(f)  # parse and transform data
  end
end
