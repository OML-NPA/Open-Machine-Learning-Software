ENV["QSG_RENDER_LOOP"] = "basic"
using Distributed
if nprocs() > 2
    rmprocs(workers()[end])
end
if nprocs() < 2
    addprocs(1)
end
@everywhere include("packages.jl")
@everywhere include("data_structures.jl")
@everywhere include("data_handling.jl")
@everywhere include("helper_functions.jl")
@everywhere include("Training.jl")
@everywhere include("Design.jl")
@everywhere include("TrainingPlot.jl")

if !isfile("config.json")
    save_settings()
else
    load_settings!(settings)
end

#---

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
    prepare_validation_data,
    # Data handling
    reset,
    get_data,
    get_settings,
    set_settings,
    save_settings,
    get_image,
    get_results,
    get_progress,
    check_progress,
    empty_results_channel,
    empty_progress_channel,
    put_channel,
    # Training
    train,
    validate,
    set_training_starting_time,
    training_elapsed_time,
    # Other
    isfile,
    isdir,
    num_cores,
    has_cuda,
    source_dir,
    yield,
    info,
    time,
    arrange,
    gc
)
load("GUI//Main.qml",
    display_image = CxxWrap.@safe_cfunction(display_image, Cvoid,
                                        (Array{UInt32,1}, Int32, Int32)))
exec()
