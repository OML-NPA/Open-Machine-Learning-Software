
using Flux, Statistics
using Printf, BSON


d1 = Dense(2,2, relu);
d2 = Dense(2,2, relu);
d3 = Dense(2,1);

function Parallel(x,layers::Tuple)
    out = x
    for i in 1:length(layers)
        cat(out,layers[i](x),dims=2)
    end
    return out
end

model = Chain(Dense(8,2, relu), x -> Parallel(x,(d1,d2)))
clearconsole()
@info(model(ones(Float32, 8, 8)))
