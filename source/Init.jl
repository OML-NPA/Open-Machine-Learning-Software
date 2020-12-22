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
@everywhere include("handling_channels.jl")
@everywhere include("data_handling.jl")
@everywhere include("helper_functions.jl")
@everywhere include("design.jl")
@everywhere include("training.jl")
@everywhere include("training_QML.jl")
@everywhere include("training_common.jl")
@everywhere include("validation.jl")
@everywhere include("analysis.jl")

CUDA.allowscalar(false)
gc() = @everywhere GC.gc()

if !isfile("config.bson")
    save_settings()
else
    load_settings()
end
