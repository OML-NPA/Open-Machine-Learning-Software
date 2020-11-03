
include("packages.jl")
include("helper_functions.jl")
include("data_handling.jl")
include("Training.jl")
include("Design.jl")
include("TrainingPlot.jl")

if !isfile("config.json")
    save_data()
else
    load_data!(master)
end

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
    # Model design
    arrange,
    # Model loading
    load_model,
    model_count,
    model_properties,
    model_get_property,
    # Data loading
    get_urls_imgs_labels,
    get_labels_colors,
    prepare_training_data,
    # Data handling
    reset,
    get_data,
    set_data,
    save_data,
    # Training
    train,
    training_elapsed_time,
    # Other
    isfile,
    isdir,
    num_cores,
    has_cuda,
    source_dir,
    yield,
    info,
    stop_all,
    time,
    arrange
)
load("GUI//Main.qml")
exec()
