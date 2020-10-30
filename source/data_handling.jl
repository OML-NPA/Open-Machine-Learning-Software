
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

@with_kw mutable struct Training
    template::String = ""
    images::String = ""
    labels::String = ""
    name::String = "new"
    type::String = "segmentation"
    url_imgs::Array = []
    url_labels::Array = []
    data_input::Array{Array} = []
    data_labels::Array{Array} = []
    Options = options_training
    data_ready::Array{Float64} = []
    loss::Array = []
    accuracy::Array = []
    test_accuracy::Array = []
    test_loss::Array = []
    stop_training::Bool = false
    task_done::Bool = false
    iteration::Int64 = 0
    epoch::Int64 = 0
    iterations_per_epoch::Int64 = 0
    starting_time::String = string(now())
    max_iterations::Int64 = iterations_per_epoch*hyperparameters_training.epochs
    training_started::Bool = false
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

function set_data_main(master::Master,fields::QML.QListAllocated,args...)
    data = master
    fields = String.(QML.value.(fields))
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    values = Array{Any}(undef,length(args))
    for i=1:length(args)
      value = args[i]
      if value isa AbstractString
          value = String(value)
      elseif value isa Integer
          value = Int64(value)
      elseif values isa AbstractFloat
          value = Float64(value)
      end
      values[i] = value
    end
    if length(args)==1
      value = args[1]
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

function reset(fields)
  var = get_data(fields)
  if var isa Array
    var = similar(var,0)
  elseif var isa Number
    var = zero(typeof(var))
  elseif var isa String
    var = ""
  end
end

function info(fields)
  @info get_data(fields)
end

function stop_all_main(master)
  master.Training.stop_training = true
end
stop_all() = stop_all_main(master)
