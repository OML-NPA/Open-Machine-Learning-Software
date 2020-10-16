
using QML, JSON, BSON
include("Training.jl")
include("Customization.jl")
include("TrainingPlot.jl")

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
