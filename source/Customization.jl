
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

struct Activation
    f
end
(m::Activation)(x) = m.f.(x)

# Model
model = []

model = Chain(
    Parallel((Conv((2,2),1=>2),Conv((2,2),1=>2))),
    Catenation(2),
    Activation(relu))
#clearconsole()
model(ones(Float32, 8,8,1,1))

layers_names = []
model_layers = []
for i = 1:length(layers)
    push!(layers_names,layers[i]["type"])
end
ind = findall(x -> x=="Input",layers_names)
input_params = layers[ind][1]
in_size = input_params["size"]
if length(in_size)==2
    in_size = (in_size...,1)
end
inds = input_params["connections_down"]
for i = 1:length(layers)
    layer = layers[inds][1]
    if layer.group=="linear"
        out, layer_f = getlinear(type,layer,in_size)
        push!(model_layers,layer_f)
    elseif layer.group=="norm"
        push!(model_layers,getnorm(type,layer,in_size))
        out = in_size
    elseif layer.group=="activation"
        push!(model_layers,getactivation(type,layer,in_size))
        out = in_size
    elseif layer.group=="pooling"
        out, layer_f = getpooling(type,layer,in_size)
        push!(model_layers,layer_f)
    elseif layer.group=="resizing"
        out, layer_f = getresizing(type,layer,in_size)
        push!(model_layers,layer_f)
    end
    inds = layer["connections_down"]
    in_size = out
end

function getlinear(type::String,d,in)
    if type=="Convolution"
        layer = Conv(d["filtersize"], in[3]=>d["filters"],pad=SamePad(),
            stride=d["stride"], dilation=d["dilationfactor"]))
        out = (outdims(layer,in)...,in[3])
        return (out,layer)

    elseif type=="Transposed convolution"
        layer = ConvTranspose(d["filtersize"], in[3]=>d["filters"],pad=SamePad(),
            stride=d["stride"], dilation=d["dilationfactor"])
        out = (outdims(layer,in)...,in[3])
        return (out,layer)
    elseif type=="Dense"
        return ((d["filters"],in[2:3]),Dense(in,d["filters"]))
    end
end

function getnorm(type::String,d,in)
    if type=="Drop-out"
        return Dropout(d["probability"])
    elseif type=="Batch normalisation"
        return BatchNorm(in, ϵ=d["epsilon"])
    end
end

function getactivation(type::String,d,in)
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

function getpooling(type::String,d,in)
    if type=="Max pooling"
        return MaxPool(d["poolsize"], stride = d["stride"])
    elseif type=="Average pooling"
        return MeanPool(d["poolsize"], stride = d["stride"])
    end
end

function getresizing(type::String,d,in)
    if type=="Catenation"
        return (sum(in...), Catenation(d["dimension"])
    elseif type=="Decatenation"
        out = ntuple(x->(0,0,0), d["outputs"])
        if dimension==1
            for i = 1:d["outputs"]
                out[i] = (in[1]/d["outputs"], in[2:3]...)
            end
        elseif dimension==2
            for i = 1:d["outputs"]
                out[i] = (in[1], in[2]/d["outputs"], in[3])
            end
        elseif dimension==3
            for i = 1:d["outputs"]
                out[i] = (in[1], in[2], in[3]/d["outputs"])
            end
        end
        return (out, Decatenation(d["outputs"],d["dimension"])
    elseif type=="Scaling"
        out = (in[1]*multiplier,in[2]*multiplier,in[3])
        return (out, Scaling(d["multiplier"]))
    elseif type=="Resizing"
        out = (d["newsize"][1:2]...,in[3])
        return (out, Resizing(d["newsize"],d["mode"]))
    end
end
