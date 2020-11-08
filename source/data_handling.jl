
@with_kw mutable struct Model_data
    input_size::Tuple = (160,160,1)
    model = Chain()
    layers::Array = []
    features::Array = []
    loss::Function = Losses.crossentropy
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
@with_kw mutable struct Processing_training
    mirroring::Bool = true
    num_angles::Int64 = 2
    min_fr_pix::Float64 = 0.1
end
processing_training = Processing_training()

@with_kw mutable struct Hyperparameters_training
    optimiser::Array = ["ADAM",5]
    optimiser_params::Array = [[],[0.9],[0.9],[0.9],
      [0.9,0.999],[0.9,0.999],[0.9,0.999],[],[0.9],[0.9,0.999],
      [0.9,0.999],[0.9,0.999,0]]
    optimiser_params_names::Array = [[],["ρ"],
      ["ρ"],["ρ"],
      ["β1","β2"],
      ["β1","β2"],
      ["β1","β2"],[],
      ["ρ"],["β1","β2"],
      ["β1","β2"],
      ["β1","β2","Weight decay"]]
    learning_rate::Float64 = 1e-3
    epochs::Int = 1
    batch_size::Int = 10
    savepath::String = "./"
end
hyperparameters_training = Hyperparameters_training()

@with_kw mutable struct General_training
    test_data_fraction::Float64 = 0.2
    testing_frequency::Int64 = 5
end
general_training = General_training()

@with_kw mutable struct Options_training
    General = general_training
    Processing = processing_training
    Hyperparameters = hyperparameters_training
end
options_training = Options_training()

@with_kw mutable struct Design
    width::Float64 = 340
    height::Float64 = 100
    min_dist_x::Float64 = 40
    min_dist_y::Float64 = 40
    hide_name::Bool = false
    iteration::Int64 = 0
    epoch::Int64 = 0
    iterations_per_epoch::Int64 = 0
    starting_time::String = string(now())
    max_iterations::Int64 = iterations_per_epoch*hyperparameters_training.epochs
    training_started::Bool = false
end
design = Design()

@with_kw mutable struct Training_plot
    data_input::Array{Array} = []
    data_labels::Array{Array} = []
    loss::Array = []
    accuracy::Array = []
    test_accuracy::Array = []
    test_loss::Array = []
    iteration::Int64 = 0
    epoch::Int64 = 0
    iterations_per_epoch::Int64 = 0
    starting_time::String = string(now())
    max_iterations::Int64 = iterations_per_epoch*hyperparameters_training.epochs
    learning_rate_changed::Bool = false
end
training_plot = Training_plot()

@with_kw mutable struct Validation_plot
    loss::Array{AbstractFloat} = []
    accuracy::Array{AbstractFloat} = []
    loss_std::AbstractFloat = 0
    accuracy_std::AbstractFloat = 0
    accuracy_std_in::Array{AbstractFloat} = []
    data_input_orig::Array{Array} = []
    data_labels_orig::Array{Array} = []
    data_input::Array{Array} = []
    data_labels::Array{Array} = []
    data_predicted::Array{Array} = []
    data_error::Array{Array} = []
    progress::Float64 = 0
    validation_done::Bool = false
end
validation_plot = Validation_plot()

@with_kw mutable struct Training
    Options = options_training
    Design = design
    Training_plot = training_plot
    Validation_plot = validation_plot
    problem_type::Array{Union{String,Int64}} = ["Classification",0]
    input_type::Array{Union{String,Int64}} = ["Image",0]
    template::String = ""
    images::String = ""
    labels::String = ""
    name::String = "new"
    type::String = "segmentation"
    url_imgs::Array = []
    url_labels::Array = []
    data_ready::Array{Float64} = []
    stop_training::Bool = false
    task_done::Bool = false
    training_started::Bool = false
    validation_started::Bool = false
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
    stop_task::Bool = false
    image::Array = []
end
master = Master()

function get_data_main(master::Master,fields,inds...)
    data = master
    fields = fix_QML_types(fields)
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if !(isempty(inds))
        inds = fix_QML_types(inds[1])
        for i = 1:length(inds)
            data = data[inds[i]]
        end
    end
    return data
end
get_data(fields,inds...) = get_data_main(master,fields,inds...)

function set_data_main(master::Master,fields::QML.QListAllocated,args...)
    data = master
    fields = String.(QML.value.(fields))
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    values = Array{Any}(undef,length(args))
    for i=1:length(args)
        values[i] = fix_QML_types(args[i])
    end
    if length(args)==1
        value = fix_QML_types(args[1])
    elseif length(args)==2
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]] = args[2]
    elseif length(args)==3
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]][args[2]] = args[3]
    end
    setproperty!(data, Symbol(fields[end]), value)
    return nothing
end
set_data(fields,value,args...) = set_data_main(master,fields,value,args...)

function save_data_main(master::Master)
    data_saved = Master()
    skip_fields = [:data_input,:data_labels,:data_ready,
        :stop_training,:url_imgs,:url_labels,:starting_time,
        :data_input_orig,:data_labels_orig,:loss,:accuracy,
        :loss_std,:accuracy_std,:accuracy_std_in,:data_input_orig,
        :data_labels_orig,:data_input,:data_labels,:data_predicted,
        :data_error]
    copy_struct!(data_saved,master,skip_fields)
    open("config.json","w") do f
      JSON.print(f,data_saved)
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
    dict_to_struct!(master,dict,[""])
end

function reset(field)
    var = get_data(field)
    if var isa Array
        var = similar(var,0)
    elseif var isa Number
        var = zero(typeof(var))
    elseif var isa String
        var = ""
    end
end

function resetproperty!(datatype,field)
    var = getproperty(datatype,field)
    if var isa Array

        var = similar(var,0)
    elseif var isa Number
        var = zero(typeof(var))
    elseif var isa String
        var = ""
    end
    setproperty!(datatype,field,var)
end

function info(fields)
    @info get_data(fields)
end

function stop_all_main(master)
    master.Training.stop_training = true
end
stop_all() = stop_all_main(master)

function fix_QML_types(var)
    if var isa AbstractString
        return String(var)
    elseif var isa Integer
        return Int64(var)
    elseif var isa AbstractFloat
        return Float64(var)
    elseif var isa QML.QListAllocated
        return fix_QML_types.(QML.value.(var))
    elseif var isa Tuple
        return fix_QML_types.(var)
    else
        return var
    end
end

function get_image_main(master::Master,model_data,fields,
        img_size::QML.QListAllocated,inds...)
    image = get_data(fields,inds...)
    if !(image[1] isa Matrix || image[1] isa RGB)
        if size(image,3)==1
            image = colorview(Gray,image)
        else
            image = colorview(RGB,image)
        end
    end
    img_size = fix_QML_types(img_size)
    inds = findall(img_size.!=0)
    if !isempty(inds)
        r = minimum(map(x-> img_size[x]/size(image,x),inds))
        image = imresize(image, ratio=r)
    end
    master.image = image
    return [size(image)...]
end
get_image(fields,img_size,inds...) =
    get_image_main(master,model_data,fields,img_size,inds...)

function display_image_main(master::Master,d::JuliaDisplay)
  display(d, master.image)
end
display_image(d) = display_image_main(master,d)
