
using QML, JSON, BSON, Printf, Parameters,Observables
using Images, ImageFiltering, ImageTransformations, ImageMorphology, DSP
using Flux,Flux.Losses, Random, CUDAapi, Statistics, Plots
import Base.string, Base.any, Base.copy!, ImageSegmentation.label_components
import CUDA
CUDA.allowscalar(true)

include("helper_functions.jl")
include("data_handling.jl")
include("Training.jl")
include("Customization.jl")
include("TrainingPlot.jl")

if !isfile("config.json")
  save_data()
else
  load_data!(master)
end
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
    num_cores,
    has_cuda,
    source_dir
)
load("GUI//Main.qml";
  observables = JuliaPropertyMap(
    "loss" => master.Training.loss,
    "accuracy" => master.Training.accuracy,
    "training_data_ready" => master.Training.data_ready))
exec()
