
@with_kw struct Channels
    training_data_progress::RemoteChannel = RemoteChannel(()->Channel{Float32}(Inf))
    training_data_results::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    training_data_modifiers::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    training_progress::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    training_results::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    training_modifiers::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    validation_data_progress::RemoteChannel = RemoteChannel(()->Channel{Float32}(Inf))
    validation_data_results::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    validation_data_modifiers::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    validation_progress::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    validation_results::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
    validation_modifiers::RemoteChannel = RemoteChannel(()->Channel{Any}(Inf))
end
channels = Channels()

@with_kw mutable struct Feature
    name::String = ""
    color::Vector{Float64} = Vector{Float64}(undef,3)
    border::Bool = false
    parent::String = ""
end
feature = Feature()

@with_kw mutable struct Model_data
    input_size::Tuple{Int64,Int64,Int64} = (160,160,1)
    model::Chain = Chain()
    layers::Array{Dict{String,Any}} = []
    features::Array{Feature} = []
    loss::Function = Losses.crossentropy
end
model_data = Model_data()

#---
@with_kw mutable struct Training_plot_data
    data_input::Vector{Array{Float32}} = Vector{Array{Float32}}(undef,0)
    data_labels::Vector{BitArray} = Vector{BitArray}(undef,0)
    loss::Array{Float32} = []
    accuracy::Array{Float32} = []
    test_accuracy::Array{Float32} = []
    test_loss::Array{Float32} = []
    test_iteration::Array{Float32} = []
    iteration::Int64 = 0
    epoch::Int64 = 0
    iterations_per_epoch::Int64 = 0
    starting_time::DateTime = now()
    max_iterations::Int64 = 0
    learning_rate_changed::Bool = false
end
training_plot_data = Training_plot_data()

@with_kw mutable struct Validation_plot_data
    loss::Array{AbstractFloat} = []
    accuracy::Array{AbstractFloat} = []
    loss_std::AbstractFloat = 0
    accuracy_std::AbstractFloat = 0
    data_input_orig::Vector{Array{RGB{Normed{UInt8,8}},2}} =
        Vector{Array{RGB{Normed{UInt8,8}},2}}(undef,1)
    data_labels_orig::Vector{Array{RGB{Normed{UInt8,8}},2}} =
        Vector{Array{RGB{Normed{UInt8,8}},2}}(undef,1)
    data_input::Vector{Array{Float32,2}} = Vector{Array{Float32,2}}(undef,1)
    data_labels::Vector{BitArray} = Vector{BitArray{3}}(undef,1)
    data_predicted::Vector{Vector{Array{RGB{Float32},2}}} =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    data_error::Vector{Vector{Array{RGB{Float32},2}}} =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
    data_target::Vector{Vector{Array{RGB{Float32},2}}} =
        Vector{Vector{Array{RGB{Float32},2}}}(undef,1)
end
validation_plot_data = Validation_plot_data()

@with_kw mutable struct Training_data
    Training_plot_data = training_plot_data
    Validation_plot_data = validation_plot_data
    url_imgs::Vector{String} = Vector{String}(undef,0)
    url_labels::Vector{String} = Vector{String}(undef,0)
end
training_data = Training_data()

@with_kw mutable struct Master_data
    Training_data = training_data
    image::Array{RGB{Float32},2} = Array{RGB{Float32},2}(undef,10,10)
end
master_data = Master_data()

#---
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


["ADAM",5] isa Array{<:Union{String,Int64}}

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
    weight_accuracy::Bool = true
    test_data_fraction::Float64 = 0
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

@with_kw mutable struct Training
    Options = options_training
    Design = design
    problem_type::Array{Union{String,Int64}} = ["Classification",0]
    input_type::Array{Union{String,Int64}} = ["Image",0]
    template::String = ""
    images::String = ""
    labels::String = ""
    name::String = "new"
    type::String = "segmentation"
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

# Settings
@with_kw mutable struct Settings
    Main = main
    Options = options
    Training = training
    Analysis = analysis
    Visualisation = visualisation
    stop_task::Bool = false
end
settings = Settings()
