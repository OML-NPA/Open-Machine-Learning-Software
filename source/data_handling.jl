
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
    num_angles::Int64 = 6
    min_fr_pix::Float64 = 0.1
end
processing_training = Processing_training()

@with_kw mutable struct Hyperparameters_training
    learning_rate::Float64 = 1e-3
    epochs::Int = 1
    batch_size::Int = 10
    savepath::String = "./"
end
hyperparameters_training = Hyperparameters_training()

@with_kw mutable struct General_training
    test_data_fraction::Float64 = 0.2
end
general_training = General_training()

@with_kw mutable struct Options_training
    General = general_training
    Processing = processing_training
    Hyperparameters = hyperparameters_training
end
options_training = Options_training()

@with_kw mutable struct Training
    template::String = ""
    images::String = ""
    labels::String = ""
    name::String = "new"
    type::String = "segmentation"
    url_imgs::Array = []
    url_labels::Array = []
    data_input::Array{Array} = []
    data_labels = []
    Options = options_training
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