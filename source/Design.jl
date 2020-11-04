
outdims = Flux.outdims

# Layers
struct Parallel
    layers::Tuple
end
function Parallel(x::Array{AbstractFloat}, layers::Tuple)
    result = []
    for i = 1:length(layers)
        push!(result, layers[i](x))
    end
    return result
end
function Parallel(x::Array{Array}, layers::Tuple)
    result = []
    for i = 1:length(layers)
        push!(result, layers[i](x[i]))
    end
    return result
end
(m::Parallel)(x) = Parallel(x, m.layers)

struct Catenation
    dims::Any
end
(m::Catenation)(x) = cat(x..., dims = m.dims)

struct Decatenation
    outputs::Any
    dims::Any
end
function Decatenation_func(x, outputs::Int64, dims::Int64)
    x_out = Array{Array}(undef, outputs)
    step_var = Int64(size(x, dims) / outputs)
    if dims == 1
        for i = 1:outputs
            x_out[i] = x[(1+(i-1)*step_var):(i)*step, :, :,:]
        end
    elseif dims == 2
        for i = 1:outputs
            x_out[i] = x[:, (1+(i-1)*step_var):(i)*step, :,:]
        end
    elseif dims == 3
        for i = 1:outputs
            x_out[i] = x[:, :, (1+(i-1)*step_var):(i)*step_var,:]
        end
    end
    return x_out
end
(m::Decatenation)(x) = Decatenation_func(x, m.outputs, m.dims)

struct Addition end
(m::Addition)(x) = sum(x)

struct Upscaling
    multiplier::Float64
    new_size::Tuple
    dims::Any
end
function Upscaling_func(x, multiplier::Float64, new_size::Tuple, dims)
    type = typeof(x[1])
    new_x = zeros(type, new_size)
    if dims == 1
        for i = 1:multiplier
            new_x[i:multiplier:end, :, :, :] = x
        end
    elseif dims == 2
        for i = 1:multiplier
            new_x[:, i:multiplier:end, :, :] = x
        end
    elseif dims == 3
        for i = 1:multiplier
            new_x[:, :, i:multiplier:end, :] = x
        end
    elseif dims == (1, 2)
        for i = 1:multiplier
            for j = 1:multiplier
                new_x[i:multiplier:end, j:multiplier:end, :, :] = x
            end
        end
    elseif dims == (1, 2, 3)
        for i = 1:multiplier
            for j = 1:multiplier
                for l = 1:multiplier
                    new_x[
                        i:multiplier:end,
                        j:multiplier:end,
                        l:multiplier:end,
                        :,
                    ] = x
                end
            end
        end
    end
    return new_x
end
(m::Upscaling)(x) = Upscaling_func(x, multiplier, new_size, dims)

struct Activation
    f::Any
end
(m::Activation)(x) = m.f.(x)

# Model constructor
function getlinear(type::AbstractString, d, in_size::Tuple)
    if type == "Convolution"
        layer = Conv(
            d["filtersize"],
            in_size[3] => d["filters"],
            pad = SamePad(),
            stride = d["stride"],
            dilation = d["dilationfactor"],
        )
        out = (outdims(layer, in_size)..., d["filters"])
        return (layer, out)
    elseif type == "Transposed convolution"
        layer = ConvTranspose(
            d["filtersize"],
            in_size[3] => d["filters"],
            pad = SamePad(),
            stride = d["stride"],
            dilation = d["dilationfactor"],
        )
        out = (outdims(layer, in)..., in_size[3])
        return (layer, out)
    elseif type == "Dense"
        layer = Dense(in_size, d["filters"])
        out = (d["filters"], in[2:3])
        return (layer, out)
    end
end

function getnorm(type::AbstractString, d, in_size::Tuple)
    if type == "Drop-out"
        return Dropout(d["probability"])
    elseif type == "Batch normalisation"
        return BatchNorm(in_size[end], ϵ = Float32(d["epsilon"]))
    end
end

function getactivation(type::AbstractString, d, in_size::Tuple)
    if type == "RelU"
        return Activation(relu)
    elseif type == "Laeky RelU"
        return Activation(leakyrelu)
    elseif type == "ElU"
        return Activation(elu)
    elseif type == "Tanh"
        return Activation(tanh)
    elseif type == "Sigmoid"
        return Activation(sigmoid)
    end
end

function getpooling(type::AbstractString, d, in_size::Tuple)
    if type == "Max pooling"
        return MaxPool(d["poolsize"], stride = d["stride"])
    elseif type == "Average pooling"
        return MeanPool(d["poolsize"], stride = d["stride"])
    end
end

function getresizing(type::AbstractString, d, in_size)
    if type == "Addition"
        out = (in_size[1][1], in_size[1][2], in_size[1][3])
        return (Addition(), out)
    elseif type == "Catenation"
        new_size = Array{Int64}(undef, length(in_size))
        dim = d["dimension"]
        for i = 1:length(in_size)
            new_size[i] = in_size[i][dim]
        end
        new_size = sum(new_size)
        if dim == 1
            out = (new_size, in_size[1][2], in_size[1][3])
        elseif dim == 2
            out = (in_size[1][1], new_size, in_size[1][3])
        elseif dim == 3
            out = (in_size[1][1], in_size[1][2], new_size)
        end
        return (Catenation(dim), out)
    elseif type == "Decatenation"
        dim = d["dimension"]
        nout = d["outputs"]
        out = Array{Tuple{Int64,Int64,Int64}}(undef, nout)
        if dim == 1
            for i = 1:nout
                out[i] = (in_size[1] / nout, in_size[2:3]...)
            end
        elseif dim == 2
            for i = 1:nout
                out[i] = (in_size[1], in_size[2] / nout, in_size[3])
            end
        elseif dim == 3
            for i = 1:nout
                out[i] = (in_size[1], in_size[2], in_size[3] / nout)
            end
        end
        return (Decatenation(nout, dim), out)
    elseif type == "Upscaling"
        multiplier = d["multiplier"]
        dims = d["dimensions"]
        out = [in_size...]
        for i in dims
            out[i] = out[i] * multiplier
        end
        out = (out...,)
        return (Upscaling(multiplier, out, dims), out)
    elseif type == "Flattening"
        out = (prod(size(x)), 1, 1)
        return (flatten(), out)
    end
end

function getlayer(layer, in_size)
    if layer["group"] == "linear"
        layer_f, out = getlinear(layer["type"], layer, in_size)
    elseif layer["group"] == "norm"
        layer_f = getnorm(layer["type"], layer, in_size)
        out = in_size
    elseif layer["group"] == "activation"
        layer_f = getactivation(layer["type"], layer, in_size)
        out = in_size
    elseif layer["group"] == "pooling"
        layer_f, out = getpooling(layer["type"], layer, in_size)
    elseif layer["group"] == "resizing"
        layer_f, out = getresizing(layer["type"], layer, in_size)
    end
    return (layer_f, out)
end

function get_loss(name::String)
    if name == "MAE"
        return Losses.mae
    elseif name == "MSE"
        return Losses.mse
    elseif name == "MSLE"
        return Losses.msle
    elseif name == "Huber"
        return Losses.huber_loss
    elseif name == "Crossentropy"
        return Losses.crossentropy
    elseif name == "Logit crossentropy"
        return Losses.logitcrossentropy
    elseif name == "Binary crossentropy"
        return Losses.binarycrossentropy
    elseif name == "Logit binary crossentropy"
        return Losses.logitbinarycrossentropy
    elseif name == "Kullback-Leiber divergence"
        return Losses.kldivergence
    elseif name == "Poisson"
        return Losses.poisson_loss
    elseif name == "Hinge"
        return Losses.hinge_loss
    elseif name == "Squared hinge"
        return squared_hinge_loss
    elseif name == "Dice coefficient"
        return Losses.dice_coeff_loss
    elseif name == "Tversky"
        return Losses.tversky_loss
    end
end

function getbranch(layer_params,in_size)
    num = layer_params isa Dict ? 1 : length(layer_params)
    if num==1
        #@info in_size
        layer, in_size = getlayer(layer_params, in_size)
    else
        par_layers = []
        par_size = []
        for i = 1:num
            if in_size isa Array
                temp_size = in_size[i]
            else
                temp_size = in_size
            end
            temp_layers = []
            for j = 1:length(layer_params[i])
                layer,temp_size = getbranch(layer_params[i][j],temp_size)
                push!(temp_layers,layer)
            end
            push!(par_layers,Chain(temp_layers...))
            push!(par_size,temp_size)
        end
        layer = Parallel((par_layers...,))
        if allcmp(par_size)
            in_size = par_size
        else
            return @info "incorrect size"
        end
    end
    return layer,in_size
end

function make_model_main(model_data)
    layers_arranged,inds = get_topology()
    if layers_arranged isa String
        return @info "not supported"
    end
    in_size = (layers_arranged[1]["size"]...,)
    model_data.input_size = in_size
    popfirst!(layers_arranged)
    loss_name = layers_arranged[end]["loss"][1]
    model_data.loss = get_loss(loss_name)
    pop!(layers_arranged)
    model_layers = []
    for i = 1:length(layers_arranged)
        layer_params = layers_arranged[i]
        layer,in_size = getbranch(layer_params,in_size)
        push!(model_layers,layer)
    end
    model_data.model = Chain(model_layers...)
    return nothing
end
make_model() = make_model_main(model_data)

function allcmp(inds)
    for i = 1:length(inds)
        if inds[1][1] != inds[i][1]
            return false
        end
    end
    return true
end

function topology_linear(layers_arranged,inds_arranged,layers,connections,types,ind)
    push!(layers_arranged,layers[ind])
    push!(inds_arranged,ind)
    ind = connections[ind]
    return ind
end

function topology_split(layers_arranged,inds_arranged,layers,
    connections,connections_in,types,ind,ind_output)
    num = length(ind)
    par_inds = Array{Array}(undef, num)
    par_layers_arranged = Array{Any}(undef, num)
    for i = 1:num
        layers_temp = []
        inds_temp = []
        ind_temp = [[ind[i]]]
        par_inds[i] =
            get_topology_branches(layers_temp,inds_temp,layers,connections,
            connections_in,types,ind_temp,ind_output)[1]
        par_layers_arranged[i] = layers_temp
        par_inds[i] = inds_temp
    end
    push!(layers_arranged,par_layers_arranged)
    push!(inds_arranged,par_inds)
    ind = map(x -> x[end],par_inds)
    ind = connections[ind]
    return ind
end

function get_topology_branches(layers_arranged,inds_arranged,
    layers,connections,connections_in,types,ind,ind_output)
    while !isempty.([ind])[1]
        numk = length(ind)
        if any(map(x -> x.=="Catenation",types[vcat(vcat(ind...)...)]))
            if allcmp(ind) && length(ind)==length(connections_in[ind[1][1][1]])
                ind = ind[1][1][1]
                push!(layers_arranged,layers[ind])
                push!(inds_arranged,ind)
                ind = connections[ind]
                continue
            else
                return ind
            end
        end
        if numk==1
            if length(ind[1])==1
                ind = topology_linear(layers_arranged,inds_arranged,
                    layers,connections,types,ind[1][1])
            else
                ind = topology_split(layers_arranged,inds_arranged,layers,
                    connections,connections_in,types,ind[1],ind_output)
            end
        else
            if all(length.(ind).==1)
                ind = topology_split(layers_arranged,inds_arranged,layers,
                    connections,connections_in,types,vcat(ind...),ind_output)
            else
                return ind
            end
        end
    end
    return ind
end

function get_topology_main(model_data)
    layers = model_data.layers
    types = [layers[i]["type"] for i = 1:length(layers)]
    groups = [layers[i]["group"] for i = 1:length(layers)]
    connections = [layers[i]["connections_down"] for i = 1:length(layers)]
    connections_in = [layers[i]["connections_up"] for i = 1:length(layers)]
    x = [layers[i]["x"] for i = 1:length(layers)]
    y = [layers[i]["y"] for i = 1:length(layers)]
    ind = findfirst(types .== "Input")
    if isempty(ind)
        @info "no input layer"
        return "no input layer"
    elseif length(ind)>1
        @info "more than one input layer"
        return "more than one input layer"
    end
    ind_output = findfirst(types .== "Output")
    if isempty(ind_output)
        @info "no output layer"
        return "no output layer"
    elseif length(ind_output)>1
        @info "more than one output layer"
        return "more than one output layer"
    end
    layers_arranged = []
    inds_arranged = []
    push!(layers_arranged,layers[ind])
    push!(inds_arranged,ind)
    ind = connections[ind]
    ind = get_topology_branches(layers_arranged,inds_arranged,layers,
        connections,connections_in,types,ind,ind_output)
    return layers_arranged, inds_arranged
end
get_topology() = get_topology_main(model_data)

function arrange_layer(coordinates::Array,coordinate::Array{Float64},
    parameters::Design)
    coordinate[2] = coordinate[2] + parameters.min_dist_y + parameters.height
    push!(coordinates,copy(coordinate))
    return coordinate
end

function arrange_branches(coordinates,coordinate,parameters,layers_arranged)
    num = layers_arranged isa Dict ? 1 : length(layers_arranged)
    if num==1
        coordinate = arrange_layer(coordinates,coordinate,parameters)
    else
        par_coordinates = []
        x_coordinates = []
        push!(x_coordinates,coordinate[1])
        num2 = num-1
        for i=1:num2
            push!(x_coordinates,coordinate[1].+
                (i+1+(i-1))*parameters.min_dist_x+i*parameters.width)
        end
        x_coordinates = x_coordinates .-
            (mean([x_coordinates[1],x_coordinates[end]])-coordinate[1])
        for i = 1:num
            temp_coordinates = []
            temp_coordinate = [x_coordinates[i],coordinate[2]]
            for j = 1:length(layers_arranged[i])
                temp_coordinate = arrange_branches(temp_coordinates,temp_coordinate,
                    parameters,layers_arranged[i][j])
            end
            push!(par_coordinates,temp_coordinates)
        end
        push!(coordinates,copy(par_coordinates))
        coordinate = [coordinate[1],maximum(map(x-> x[end],map(x -> x[end],par_coordinates)))]
    end
    return coordinate
end

function get_values!(values::Array,array::Array,cond_fun)
    for i=1:length(array)
        temp = array[i]
        if cond_fun(temp)
            get_values!(values,temp,cond_fun)
        else
            push!(values,temp)
        end
    end
    return nothing
end

function arrange_main(design)
    parameters = design
    layers_arranged,inds_arranged = get_topology()
    coordinates = []
    coordinate = [layers_arranged[1]["x"],layers_arranged[1]["y"]-
        (design.height+design.min_dist_y)]
    for i = 1:length(inds_arranged)
        coordinate = arrange_branches(coordinates,
            coordinate,parameters,layers_arranged[i])
    end
    coordinates_flattened = []
    get_values!(coordinates_flattened,coordinates,
        x-> x isa Array && x[1] isa Array)
    inds_flattened = []
    get_values!(inds_flattened,inds_arranged,x-> x isa Array)
    return [coordinates_flattened,inds_flattened.-1]
end
arrange() = arrange_main(design)
