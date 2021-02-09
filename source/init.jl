
# Needed to avoid an endless loop for Julia canvas
ENV["QSG_RENDER_LOOP"] = "basic"
# Start a distributed process
using Distributed
if nprocs() > 2
    rmprocs(workers()[end])
end
if nprocs() < 2
    addprocs(1)
end
# Import functions
@everywhere include("packages.jl")
@everywhere include("data_structures.jl")
@everywhere include("handling_channels.jl")
@everywhere include("handling_data.jl")
@everywhere include("helper_functions.jl")
@everywhere include("image_processing.jl")
@everywhere include("design.jl")
@everywhere include("training.jl")
@everywhere include("common.jl")
@everywhere include("validation.jl")
@everywhere include("application.jl")

# Other
CUDA.allowscalar(false)

# Import the configutation file
if !isfile("config.bson")
    save_settings()
else
    load_settings()
end
