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
CUDA.allowscalar(false)
gc() = @everywhere GC.gc()

if !isfile("config.json")
    save_settings()
else
    load_settings()
end
