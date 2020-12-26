
if !@isdefined master_data
    include("Init.jl")
end

@qmlfunction(
    # Model functions
    reset_layers,
    update_layers,
    make_model,
    save_model,
    load_model,
    # Handle features
    num_features,
    reset_features,
    append_features,
    update_features,
    get_feature_field,
    set_output,
    get_output,
    model_count,
    model_properties,
    model_get_property,
    # Model design
    arrange,
    # Data loading
    get_urls_training,
    get_urls_analysis,
    get_labels_colors,
    prepare_training_data,
    prepare_validation_data,
    prepare_analysis_data,
    # Data handling
    isfile,
    isdir,
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
    # Main actions
    train,
    validate,
    analyse,
    # Training related
    set_training_starting_time,
    training_elapsed_time,
    # Other
    make_tuple,
    num_cores,
    has_cuda,
    source_dir,
    yield,
    info,
    time,
    gc
)
load("GUI//Main.qml",
    display_image = CxxWrap.@safe_cfunction(display_image, Cvoid,
                                        (Array{UInt32,1}, Int32, Int32)))
exec()
