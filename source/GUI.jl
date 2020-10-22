
using QML, JSON, BSON, Printf, Parameters
using Images, ImageFiltering, ImageTransformations, ImageMorphology, DSP
using Flux, Random, CUDAapi, Statistics, Plots
import Base.string, Base.any, Base.copy!, ImageSegmentation.label_components

# Variable definitions
layers = []
model = Chain()
features = []
url_imgs = Array{String}(undef,0)
url_labels = Array{String}(undef,0)
data_imgs = Array{Array}(undef,0)
data_labels = Array{BitArray}(undef,0)

@with_kw mutable struct Model_data
    input_size::Tuple = (160,160,1)
    loss::String = "Dice coefficient"
end
model_data = Model_data()

@with_kw mutable struct Features
    name::String = ""
    color::Array = [0,0,0]
    border::Bool = false
    parent::String = ""
end

# Main
@with_kw mutable struct Main_s
    a::Int = 0
end
main = Main_s()

# Options
@with_kw mutable struct Hardware_resources
    allow_GPU::Bool = true
    num_cores::Int64 = Threads.nthreads()
end
hardware_resources = Hardware_resources()
@with_kw mutable struct Options
    Hardware_resources = hardware_resources
end
options = Options()

# Training
@with_kw mutable struct Processing_temp
    mirroring::Bool = true
    num_angles::Int64 = 6
    min_fr_pix::Float64 = 0.1
end
processing_temp = Processing_temp()

@with_kw mutable struct Hyperparameters_temp
    learning_rate::Float64 = 1e-3
    epochs::Int = 1
    batch_size::Int = 10
    savepath::String = "./"
end
hyperparameters_temp = Hyperparameters_temp()

@with_kw mutable struct Options_temp
    Processing = processing_temp
    Hyperparameters = hyperparameters_temp
end
options_temp = Options_temp()

@with_kw mutable struct Training
    template::String = ""
    images::String = ""
    labels::String = ""
    name::String = "new"
    Options = options_temp
end
training = Training()

# Analysis
@with_kw mutable struct Analysis
    a::Int = 0
end
analysis = Analysis()

# Visualisation
@with_kw mutable struct Visualisation
    a::Int = 0
end
visualisation = Visualisation()

# Master
@with_kw mutable struct Master
    Main = main
    Options = options
    Training = training
    Analysis = analysis
    Visualisation = visualisation
end
master = Master()

include("Training.jl")
include("Customization.jl")
include("TrainingPlot.jl")

function get_data_main(master::Master,fields::QML.QListAllocated)
    data = master
    fields = QML.value.(fields)
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    return data
end
get_data(fields) = get_data_main(master,fields)

function set_data_main(master::Master,fields::QML.QListAllocated,value)
    data = master
    fields = String.(QML.value.(fields))
    if value isa AbstractString
        value = String(value)
    elseif value isa Integer
        value = Int64(value)
    elseif values isa AbstractFloat
        value = Float64(value)
    end
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    setproperty!(data, Symbol(fields[end]), value)
    return nothing
end
set_data(fields,value) = set_data_main(master,fields,value)

function save_data_main(master::Master)
    open("config.json","w") do f
      JSON.print(f,master)
    end
end
save_data() = save_data_main(master)

function load_data!(master)
    dict = []
    if isfile("config.json")
      open("config.json", "r") do f
        dict = JSON.parse(f)
      end
    end
    dict_to_struct!(master,dict)
end

function dict_to_struct!(master,dict::Dict)
  ks = [keys(dict)...]
  for i = 1:length(ks)
    value = dict[ks[i]]
    if value isa Dict
      dict_to_struct!(getproperty(master,Symbol(ks[i])),value)
    else
      setproperty!(master,Symbol(ks[i]),value)
    end
  end
end

function num_cores()
  return Threads.nthreads()
end

if !isfile("config.json")
  save_data()
end
load_data!(master)
@qmlfunction(
    # Model saving
    reset_layers,
    update_layers,
    make_model,
    save_model,
    # Handle features
    num_features,
    reset_features,
    append_features,
    update_features,
    get_feature_field,
    # Model loading
    load_model,
    model_count,
    model_properties,
    model_get_property,
    # Data loading
    get_urls_imgs_labels,
    get_labels_colors,
    # Data handling
    get_data,
    set_data,
    save_data,
    # Other
    isfile,
    isdir,
    num_cores
)
load("GUI//Main.qml")
exec()
