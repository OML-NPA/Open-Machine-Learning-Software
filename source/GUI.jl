
using QML
using Observables
using BSON
import Base.string
import Base.UInt32

cd("C:\\Users\\a_ill\\Documents\\GitHub\\Deep-Data-Analysis\\source")

load("GUI//Main.qml")

# QML functions and vars
dict = Dict{String,Any}()
layers = []

function string(var::QML.QVariantDereferenced)
  return String[var][1]
end

function Int32(var::QML.QVariantDereferenced)
  return Int32[var][1]
end

function returnfolder(folder)
  folder = QString(folder)
  folder = folder[8:length(folder)]
  return (folder)
end

function returnmap(keys, values, ext...)
  global dict
  dict = Dict{String,Any}()
  keys = string.(keys)
  values = string.(values)
  sizehint!(dict, length(keys))
  for i = 1:length(keys)
    var_str = values[i]
    var_num = tryparse(Float32, var_str)
    if var_num == nothing
      dict[keys[i]] = var_str
    else
      dict[keys[i]] = var_num
    end
  end
  if length(ext)!=0
    for i = 1:2:length(ext)
      dict[ext[i]] = Int32.(ext[i+1])
    end
  end

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
