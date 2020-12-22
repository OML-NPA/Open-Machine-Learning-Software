
function get_labels_colors_main(training_data::Training_data,channels::Channels)
    url_labels = training_data.url_labels
    num = length(url_labels)
    put!(channels.training_labels_colors,num)
    colors_array = Vector{Vector{Vector{Float32}}}(undef,num)
    labelimgs = Vector{Array{RGB{Normed{UInt8,8}},2}}(undef,0)
    for i=1:num
        push!(labelimgs,RGB.(load(url_labels[i])))
    end
    Threads.@threads for i=1:num
            labelimg = labelimgs[i]
            unique_colors = unique(labelimg)
            ind = findfirst(unique_colors.==RGB.(0,0,0))
            deleteat!(unique_colors,ind)
            colors = channelview(float.(unique_colors))*255
            colors_array[i] = arsplit(colors,2)
            put!(channels.training_labels_colors,1)
    end
    colors_out::Vector{Vector{Float32}} = vcat(colors_array...)
    unique_colors = unique(colors_out)
    put!(channels.training_labels_colors,unique_colors)
    return
end
function get_labels_colors_main2(training_data::Training_data,channels::Channels)
    @everywhere training_data
    remote_do(get_labels_colors_main,workers()[end],training_data,channels)
end
get_labels_colors() = get_labels_colors_main2(training_data,channels)

model_count() = length(model_data.layers)
model_properties(index) = [keys(model_data.layers[index])...]
function model_get_property_main(model_data::Model_data,index,property_name)
    layer = model_data.layers[index]
    property = layer[property_name]
    if  isa(property,Tuple)
        property = join(property,',')
    end
    return property
end
model_get_property(index,property_name) =
    model_get_property_main(model_data,index,property_name)

function reset_layers_main(model_data::Model_data)
    empty!(model_data.layers)
end
reset_layers() = reset_layers_main(model_data::Model_data)

function update_layers_main(model_data::Model_data,keys,values,ext...)
    layers = model_data.layers
    keys = fix_QML_types(keys)
    values = fix_QML_types(values)
    ext = fix_QML_types(ext)
    dict = Dict{String,Any}()
    sizehint!(dict, length(keys))
    for i = 1:length(keys)
        var = values[i]
        if var isa String
            var_num = tryparse(Float64, var)
            if var_num == nothing
              if occursin(",", var) && !occursin("[", var)
                 dict[keys[i]] = str2tuple(Int64,var)
              else
                 dict[keys[i]] = var
              end
            else
              dict[keys[i]] = var_num
            end
        else
            dict[keys[i]] = var
        end
    end
    if length(ext)!=0
        for i = 1:2:length(ext)
            dict[ext[i]] = ext[i+1]
        end
    end
    dict = fixtypes(dict)
    push!(layers, copy(dict))
end
update_layers(keys,values,ext...) = update_layers_main(model_data::Model_data,
    keys,values,ext...)

function reset_features_main(model_data)
    empty!(model_data.features)
end
reset_features() = reset_features_main(model_data::Model_data)

function append_features_main(model_data::Model_data,name,colorR,colorG,colorB,border,parent)
    push!(model_data.features,Feature(String(name),
        Int64.([colorR,colorG,colorB]),Bool(border),String(parent)))
end
append_features(name,colorR,colorG,colorB,border,parent) =
    append_features_main(model_data,name,colorR,colorG,colorB,border,parent)

function update_features_main(model_data,index,name,colorR,colorG,colorB,border,parent)
    model_data.features[index] = Feature(String(name),Int64.([colorR,colorG,colorB]),
        Bool(border),String(parent))
end
update_features(index,name,colorR,colorG,colorB,border,parent) =
    update_features_main(model_data,index,name,colorR,colorG,colorB,border,parent)

function num_features_main(model_data::Model_data)
    return length(model_data.features)
end
num_features() = num_features_main(model_data::Model_data)

function get_feature_main(model_data::Model_data,index,fieldname)
    return getfield(model_data.features[index], Symbol(String(fieldname)))
end
get_feature_field(index,fieldname) = get_feature_main(model_data,index,fieldname)
