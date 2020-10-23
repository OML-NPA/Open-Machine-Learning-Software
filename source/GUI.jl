
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

include("helper_functions.jl")
include("data_handling.jl")
include("Training.jl")
include("Customization.jl")
include("TrainingPlot.jl")

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
