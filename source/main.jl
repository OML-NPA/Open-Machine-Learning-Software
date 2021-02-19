
# Initialization
if !@isdefined master_data
    include("init.jl")
end

# Launches GUI
@qmlfunction(
    # Model functions
    reset_layers,
    update_layers,
    make_model,
    save_model,
    load_model,
    get_model_type,
    set_model_type,
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
    model_get_layer_property,
    # Model design
    arrange,
    # Data loading
    get_urls_training,
    get_urls_validation,
    get_urls_application,
    get_labels_colors,
    prepare_training_data,
    prepare_validation_data,
    prepare_application_data,
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
    apply,
    # Training related
    set_training_starting_time,
    training_elapsed_time,
    # Other
    make_tuple,
    num_cores,
    has_cuda,
    pwd,
    yield,
    info,
    time,
    pwd,
    gc,
    fix_slashes,
    source_dir
)
load("GUI//Main.qml",
    display_image = CxxWrap.@safe_cfunction(display_image, Cvoid,
                                        (Array{UInt32,1}, Int32, Int32)))
exec()