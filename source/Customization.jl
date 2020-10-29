
outdims = Flux.outdims

# Layers
struct Parallel
    layers::Array
end
function Parallel(x,layers::Array)
    result = []
    for i = 1:length(layers)
        push!(result,layers[i](x))
    end
    return result
end
(m::Parallel)(x) = Parallel(x,m.layers)

struct Catenation
    dims
end
(m::Catenation)(x) = cat(x...,dims=m.dims)

struct Decatenation
    outputs
    dims
end
function Decatenation_func(x,outputs::Int64,dims::Int64)
    x_out = ntuple(x->[], outputs)
    step = size(x,dims)/outputs
    if dims==1
        for i = 1:outputs
            x_out[i] = x[(1+(i-1)*step):(i)*step,:,:]
        end
    elseif dims==2
        for i = 1:outputs
            x_out[i] = x[:,(1+(i-1)*step):(i)*step,:]
        end
    elseif dims==3
        for i = 1:outputs
            x_out[i] = x[:,:,(1+(i-1)*step):(i)*step]
        end
    end
    return x_out
end
(m::Decatenation)(x) = Decatenation_func(x,outputs,dims)

struct Addition
end
(m::Addition)(x) = sum(x)

struct Upscaling
    multiplier::Float64
    new_size::Tuple
    dims
end
function Upscaling_func(x,multiplier::Float64,new_size::Tuple,dims)
    type = typeof(x[1])
    new_x = zeros(type, new_size)
    if dims==1
        for i = 1:multiplier
            new_x[i:multiplier:end,:,:,:] = x
        end
    elseif dims==2
        for i = 1:multiplier
            new_x[:,i:multiplier:end,:,:] = x
        end
    elseif dims==3
        for i = 1:multiplier
            new_x[:,:,i:multiplier:end,:] = x
        end
    elseif dims==(1,2)
        for i = 1:multiplier
            for j = 1:multiplier
                new_x[i:multiplier:end,j:multiplier:end,:,:] = x
            end
        end
    elseif dims==(1,2,3)
        for i = 1:multiplier
            for j = 1:multiplier
                for l = 1:multiplier
                    new_x[i:multiplier:end,j:multiplier:end,l:multiplier:end,:] = x
                end
            end
        end
    end
    return new_x
end
(m::Upscaling)(x) = Upscaling_func(x,multiplier,new_size,dims)

struct Activation
    f
end
(m::Activation)(x) = m.f.(x)

# Model constructor
function getlinear(type::AbstractString,d,in_size::Tuple)
    if type=="Convolution"
        layer = Conv(d["filtersize"], in_size[3]=>d["filters"],pad=SamePad(),
            stride=d["stride"], dilation=d["dilationfactor"])
        out = (outdims(layer,in_size)...,d["filters"])
        return (layer,out)
    elseif type=="Transposed convolution"
        layer = ConvTranspose(d["filtersize"], in_size[3]=>d["filters"],pad=SamePad(),
            stride=d["stride"], dilation=d["dilationfactor"])
        out = (outdims(layer,in)...,in_size[3])
        return (layer,out)
    elseif type=="Dense"
        layer = Dense(in_size,d["filters"])
        out = (d["filters"],in[2:3])
        return (layer,out)
    end
end

function getnorm(type::AbstractString,d,in_size::Tuple)
    if type=="Drop-out"
        return Dropout(d["probability"])
    elseif type=="Batch normalisation"
        return BatchNorm(in_size[end], ϵ=Float32(d["epsilon"]))
    end
end

function getactivation(type::AbstractString,d,in_size::Tuple)
    if type=="RelU"
        return Activation(relu)
    elseif type=="Laeky RelU"
        return Activation(leakyrelu)
    elseif type=="ElU"
        return Activation(elu)
    elseif type=="Tanh"
        return Activation(tanh)
    elseif type=="Sigmoid"
        return Activation(sigmoid)
    end
end

function getpooling(type::AbstractString,d,in_size::Tuple)
    if type=="Max pooling"
        return MaxPool(d["poolsize"], stride = d["stride"])
    elseif type=="Average pooling"
        return MeanPool(d["poolsize"], stride = d["stride"])
    end
end

function getresizing(type::AbstractString,d,in_size)
    if type=="Catenation"
        new_size = Array{Int64}(undef,length(in_size))
        dim = d["dimension"]
        for i = 1:length(in_size)
            new_size[i] = in_size[i][dim]
        end
        new_size = sum(new_size)
        if dim==1
            out = (new_size,in_size[1][2],in_size[1][3])
        elseif dim==2
            out = (in_size[1][1],new_size,in_size[1][3])
        elseif dim==3
            out = (in_size[1][1],in_size[1][2],new_size)
        end

        return (Catenation(dim), out)
    elseif type=="Decatenation"
        out = ntuple(x->(0,0,0), d["outputs"])
        if dimension==1
            for i = 1:d["outputs"]
                out[i] = (in_size[1]/d["outputs"], in_size[2:3]...)
            end
        elseif dimension==2
            for i = 1:d["outputs"]
                out[i] = (in_size[1], in_size[2]/d["outputs"], in_size[3])
            end
        elseif dimension==3
            for i = 1:d["outputs"]
                out[i] = (in_size[1], in_size[2], in_size[3]/d["outputs"])
            end
        end
        return (Decatenation(d["outputs"],d["dimension"]), out)
    elseif type=="Upscaling"
        multiplier = d["multiplier"]
        dims = d["dimensions"]
        out = [in_size...]
        for i in dims
            out[i] = out[i]*multiplier
        end
        out = (out...,)
        return (Upscaling(multiplier,out,dims), out)
    elseif type=="Flattening"
        out = (prod(size(x)),1,1)
        return (flatten(), out)
    end
end

function getlayer(layer,in_size)
    if layer["group"]=="linear"
        layer_f, out  = getlinear(layer["type"],layer,in_size)
    elseif layer["group"]=="norm"
        layer_f = getnorm(layer["type"],layer,in_size)
        out = in_size
    elseif layer["group"]=="activation"
        layer_f = getactivation(layer["type"],layer,in_size)
        out = in_size
    elseif layer["group"]=="pooling"
        layer_f, out  = getpooling(layer["type"],layer,in_size)
    elseif layer["group"]=="resizing"
        layer_f, out = getresizing(layer["type"],layer,in_size)
    end
    return (layer_f, out)
end

function getbranch(layers,in_size,inds_cat,inds_cat_in,ind_output,inds)
    branch = []
    inds_out = []
    skip = false
    while inds!=ind_output && !skip
        if length(inds)==1
            layer_params = layers[inds][1]
            layer, in_size = getlayer(layer_params,in_size)
            push!(branch,layer)
            push!(inds_out,inds[1])
            inds = layer_params["connections_down"][1]
            for i = 1:length(inds)
                if inds[i] in inds_cat
                    skip = true
                    break
                end
            end
        else
            branch_par = []
            inds_out_par = []
            inds_par = []
            in_size_par = []
            for i = 1:length(inds)
                #global in_size, inds
                branch_temp, inds_out_temp, inds_temp, in_size_temp =
                    getbranch(layers,in_size,inds_cat,inds_cat_in,ind_output,[inds[i]])
                push!(branch_par,branch_temp)
                push!(inds_par,inds_temp)
                push!(inds_out_par,inds_out_temp)
                push!(in_size_par,in_size_temp)
            end
            push!(branch,Parallel(branch_par))
            if allcmp(inds_par) && allcmp(in_size_par) &&
                    layers[inds_par[1][1]]["type"]=="Catenation"
                inds = inds_par[1]
                in_size = in_size_par
            end
        end
    end
    if length(branch)>1
        branch = Chain(branch...)
    else
        branch = branch[1]
    end
    return (branch,inds_out,inds,in_size)
end

function get_loss(name::String)
    if name=="MAE"
        return Losses.mae
    elseif name=="MSE"
        return Losses.mse
    elseif name=="MSLE"
        return Losses.msle
    elseif name=="Huber"
        return Losses.huber_loss
    elseif name=="Crossentropy"
        return Losses.crossentropy
    elseif name=="Logit crossentropy"
        return Losses.logitcrossentropy
    elseif name=="Binary crossentropy"
        return Losses.binarycrossentropy
    elseif name=="Logit binary crossentropy"
        return Losses.logitbinarycrossentropy
    elseif name=="Kullback-Leiber divergence"
        return Losses.kldivergence
    elseif name=="Poisson"
        return Losses.poisson_loss
    elseif name=="Hinge"
        return Losses.hinge_loss
    elseif name=="Squared hinge"
        return squared_hinge_loss
    elseif name=="Dice coefficient"
        return Losses.dice_coeff_loss
    elseif name=="Tversky"
        return Losses.tversky_loss
    end
end

function make_model_main(model_data)
    layers = model_data.layers
    layers_names = []
    model_layers = []
    for i = 1:length(layers)
        push!(layers_names,layers[i]["type"])
    end
    ind = findall(x -> x=="Input",layers_names)
    input_params = layers[ind][1]
    in_size = (input_params["size"]...,)
    model_data.input_size = in_size
    inds = input_params["connections_down"][1]
    inds_cat = findall(x -> x=="Catenation",layers_names)
    inds_cat_in = Array{Array{Int64}}(undef,length(inds_cat))
    for i = 1:length(inds_cat)
        inds_cat_in[i] = layers[inds_cat[i]]["connections_up"]
    end
    ind_output = findall(x -> x=="Output",layers_names)
    if isempty(ind_output)
        @info "no output layer"
        return
    end
    loss_name = layers[ind_output[1]]["loss"][1]
    model_data.loss = get_loss(loss_name)
    inds_out = []
    while inds!=ind_output
        branch, inds_out_branch, inds, in_size =
            getbranch(layers,in_size,inds_cat,inds_cat_in,ind_output,inds)
        push!(model_layers,branch)
        push!(inds_out,inds_out_branch)
    end
    if length(model_layers)>1
        model_layers = Chain(model_layers...)
    elseif occursin("Chain",string(typeof(model_layers[1])))
        model_layers = model_layers[1]
    else
        model_layers = Chain(model_layers[1])
    end
    model_data.model = model_layers
    return nothing
end
make_model() = make_model_main(model_data)

function allcmp(inds)
    for i = 1:length(inds)
        if inds[1][1]!=inds[i][1]
            return false
        end
    end
    return true
end
