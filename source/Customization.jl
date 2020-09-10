
using Flux, Statistics
using Printf, BSON
using QML
outdims = Flux.outdims

# Layers
struct Parallel
    layers::Tuple
end
function Parallel(x,layers::Tuple)
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
        return BatchNorm(in_size[end], ϵ=d["epsilon"])
    end
end

function getactivation(type::AbstractString,d,in_size::Tuple)
    if type=="RelU"
        return Activation(x->relu(x))
    elseif type=="Laeky RelU"
        return Activation(x->leakyrelu(x,a=d["scale"]))
    elseif type=="ElU"
        return Activation(x->elu(x,a=d["alpha"]))
    elseif type=="Tanh"
        return Activation(x->tanh(x))
    end
end

function getpooling(type::AbstractString,d,in_size::Tuple)
    if type=="Max pooling"
        return MaxPool(d["poolsize"], stride = d["stride"])
    elseif type=="Average pooling"
        return MeanPool(d["poolsize"], stride = d["stride"])
    end
end

function getresizing(type::AbstractString,d,in_size::Tuple)
    if type=="Catenation"
        if d["dimension"]==1
            out = (sum(in_size[:][1]),in_size[1][2:3])
        elseif d["dimension"]==2
            out = (in_size[1][1],sum(in_size[:][2]),in_size[1][3])
        elseif d["dimension"]==3
            out = (in_size[1][1:2],sum(in_size[:][3]))
        end
        return (Catenation(d["dimension"]), sum(in_size...))
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
    elseif type=="Scaling"
        out = (in_size[1]*multiplier,in_size[2]*multiplier,in_size[3])
        return (Scaling(d["multiplier"]), out)
    elseif type=="Resizing"
        out = (d["newsize"][1:2]...,in_size[3])
        return (Resizing(d["newsize"],d["mode"]), out)
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
    return (layer_f, in_size)
end

function getbranch(layers,in_size,inds_cat,ind_output,inds)
    branch = []
    while inds!=ind_output && !(inds[1] in inds_cat)
        if length(inds)==1
            layer_params = layers[inds][1]
            layer, in_size = getlayer(layer_params,in_size)
            @info layer
            push!(branch,layer)
            inds = layer_params["connections_down"]
        else
            branch_par = []
            inds_par = []
            in_size_par = []
            for i = 1:length(inds)
                branch_par[i], inds_par[i], in_size_par[i] =
                    getbranch(layers,in_size,inds_cat,ind_output,[inds[i]])
                push!(branch,Parallel(branch_par...))
                if all(inds_par.==inds_par[1]) && all(in_size_par.==in_size_par[1])
                        layers[inds_par[1][1]]["type"]=="Catenation"
                    inds = inds_par[1]
                    in_size = in_size_par[1]
                end
            end
        end
    end
    if inds[1] in inds_cat
        branch = Chain(branch)
    end
    return (branch, inds, in_size)
end

function makemodel(layers)
    layers_names = []
    model_layers = []
    for i = 1:length(layers)
        push!(layers_names,layers[i]["type"])
    end
    ind = findall(x -> x=="Input",layers_names)
    input_params = layers[ind][1]
    in_size = input_params["size"]
    inds = input_params["connections_down"]
    inds_cat = findall(x -> x=="Catenation",layers_names)
    ind_output = findall(x -> x=="Output",layers_names)
    cnt = 0
    while inds!=ind_output || length(cnt)>length(layers)
        branch, inds, in_size =
            getbranch(layers,in_size,inds_cat,ind_output,inds)
        push!(model_layers,branch...)
        cnt = cnt + 1
        @info cnt
    end
    return Chain(model_layers...)
end

model = makemodel(layers)
