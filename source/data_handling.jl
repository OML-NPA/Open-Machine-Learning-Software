
function get_data_main(data::Master_data,fields,inds...)
    fields = fix_QML_types(fields)
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if !(isempty(inds))
        inds = fix_QML_types(inds[1])
        for i = 1:length(inds)
            data = data[inds[i]]
        end
    end
    return data
end
get_data(fields,inds...) = get_data_main(master_data,fields,inds...)

function set_data_main(master_data::Master_data,fields::QML.QListAllocated,args...)
    data = settings
    fields = fix_QML_types(fields)
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    values = Array{Any}(undef,length(args))
    for i=1:length(args)
        values[i] = fix_QML_types(args[i])
    end
    if length(args)==1
        value = fix_QML_types(args[1])
    elseif length(args)==2
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]] = args[2]
    elseif length(args)==3
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]][args[2]] = args[3]
    end
    setproperty!(data, Symbol(fields[end]), value)
    return
end
set_data(fields,value,args...) = set_data_main(master_data,fields,value,args...)

function get_settings_main(settings::Settings,fields,inds...)
    data = settings
    fields = fix_QML_types(fields)
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    if !(isempty(inds))
        inds = fix_QML_types(inds[1])
        for i = 1:length(inds)
            data = data[inds[i]]
        end
    end
    return data
end
get_settings(fields,inds...) = get_settings_main(settings,fields,inds...)

function set_settings_main(settings::Settings,fields::QML.QListAllocated,args...)
    data = settings
    fields = String.(QML.value.(fields))
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    values = Array{Any}(undef,length(args))
    for i=1:length(args)
        values[i] = fix_QML_types(args[i])
    end
    if length(args)==1
        value = fix_QML_types(args[1])
    elseif length(args)==2
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]] = args[2]
    elseif length(args)==3
        value = getproperty(data,Symbol(fields[end]))
        value[args[1]][args[2]] = args[3]
    end
    setproperty!(data, Symbol(fields[end]), value)
    return
end
set_settings(fields,value,args...) = set_settings_main(settings,fields,value,args...)

function save_settings_main(settings::Settings)
    open("config.json","w") do f
      JSON.print(f,settings)
    end
end
save_settings() = save_settings_main(settings)

function load_settings!(settings)
    local dict
    if isfile("config.json")
      open("config.json", "r") do f
        dict = JSON.parse(f)
      end
    end
    dict_to_struct!(settings,dict)
end
load_settings() = load_settings!(settings)

function reset(field)
    var = get_data(field)
    if var isa Array
        var = similar(var,0)
    elseif var isa Number
        var = zero(typeof(var))
    elseif var isa String
        var = ""
    end
end

function resetproperty!(datatype,field)
    var = getproperty(datatype,field)
    if var isa Array
        var = similar(var,0)
    elseif var isa Number
        var = zero(typeof(var))
    elseif var isa String
        var = ""
    end
    setproperty!(datatype,field,var)
end

function info(fields)
    @info get_data(fields)
end

function fix_QML_types(var)
    if var isa AbstractString
        return String(var)
    elseif var isa Integer
        return Int64(var)
    elseif var isa AbstractFloat
        return Float64(var)
    elseif var isa QML.QListAllocated
        return fix_QML_types.(QML.value.(var))
    elseif var isa Tuple
        return fix_QML_types.(var)
    else
        return var
    end
end

function set_output_main(model_data::Model_data,fields::QML.QListAllocated,ind,value)
    ind = fix_QML_types(ind)
    value = fix_QML_types(value)
    fields = fix_QML_types(fields)
    data = model_data.features[ind].Output
    for i = 1:length(fields)-1
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    setproperty!(data, Symbol(fields[end]), value)
    return
end
set_output(fields,ind,value) = set_output_main(model_data,fields,ind,value)

function get_output_main(model_data::Model_data,fields::QML.QListAllocated,ind)
    ind = fix_QML_types(ind)
    fields = fix_QML_types(fields)
    data = model_data.features[ind].Output
    for i = 1:length(fields)
        field = Symbol(fields[i])
        data = getproperty(data,field)
    end
    return data
end
get_output(fields,ind) = get_output_main(model_data,fields,ind)

function get_image_main(master_data::Master_data,model_data,fields,
        img_size,inds...)
    image = collect(get_data(fields,inds...))
    if isempty(image)
        master_data.image = ARGB32.(image)
        return [0,0]
    end
    img_size = fix_QML_types(img_size)
    inds = findall(img_size.!=0)
    if !isempty(inds)
        r = minimum(map(x-> img_size[x]/size(image,x),inds))
        image = imresize(image, ratio=r)
    end
    master_data.image = ARGB32.(image)
    return [size(image)...]
end
get_image(fields,img_size,inds...) =
    get_image_main(master_data,model_data,fields,img_size,inds...)

function get_progress_main(channels,field)
    field = fix_QML_types(field)
    if field=="Training data preparation"
        channel_temp = channels.training_data_progress
    elseif field=="Validation data preparation"
        channel_temp = channels.validation_data_progress
    elseif field=="Training"
        channel_temp = channels.training_progress
    elseif field=="Validation"
        channel_temp = channels.validation_progress
    end
    if isready(channel_temp)
        return take!(channel_temp)
    else
        return false
    end
end
get_progress(field) = get_progress_main(channels,field)

function check_progress_main(channels,field)
    field = fix_QML_types(field)
    if field=="Training data preparation"
        channel_temp = channels.training_data_progress
    elseif field=="Validation data preparation"
        channel_temp = channels.validation_data_progress
    elseif field=="Training"
        channel_temp = channels.training_progress
    elseif field=="Validation"
        channel_temp = channels.validation_progress
    end
    if isready(channel_temp)
        return fetch(channel_temp)
    else
        return false
    end
end
check_progress(field) = check_progress_main(channels,field)

function get_results_main(channels,master_data,model_data,field)
    field = fix_QML_types(field)
    if field=="Training data preparation"
        if isready(channels.training_data_results)
            data = take!(channels.training_data_results)
            training_plot_data = master_data.Training_data.Training_plot_data
            training_plot_data.data_input = data[1]
            training_plot_data.data_labels = data[2]
            return true
        else
            return false
        end
    elseif field=="Validation data preparation"
        if isready(channels.validation_data_results)
            data = take!(channels.validation_data_results)
            validation_plot_data = master_data.Training_data.Validation_plot_data
            validation_plot_data.data_input_orig = data[1]
            validation_plot_data.data_labels_orig = data[2]
            validation_plot_data.data_input = data[3]
            validation_plot_data.data_labels = data[4]
            return true
        else
            return false
        end
    elseif field=="Analysis data preparation"
        if isready(channels.analysis_data_results)
            data = take!(channels.analysis_data_results)
            analysis_data = master_data.Analysis_data
            analysis_data.data_input = data
            return true
        else
            return false
        end
    elseif field=="Training"
        if isready(channels.training_results)
            data = take!(channels.training_results)
            if data!=nothing
                training_plot_data = master_data.Training_data.Training_plot_data
                model_data.model = data[1]
                training_plot_data.accuracy = data[2]
                training_plot_data.loss = data[3]
                training_plot_data.test_accuracy = data[4]
                training_plot_data.test_loss = data[5]
                training_plot_data.test_iteration = data[6]
            end
            return true
        else
            return false
        end
    elseif field=="Validation"
        if isready(channels.validation_results)
            data = take!(channels.validation_results)
            validation_plot_data = master_data.Training_data.Validation_plot_data
            validation_plot_data.data_predicted = data[1]
            validation_plot_data.data_error = data[2]
            validation_plot_data.data_target = data[3]
            validation_plot_data.accuracy = data[4]
            validation_plot_data.loss = data[5]
            validation_plot_data.accuracy_std = data[6]
            validation_plot_data.loss_std = data[7]
            return [data[4],data[5],mean(data[4]),mean(data[5]),data[6],data[7]]
        else
            return false
        end
    elseif field=="Labels colors"
        if isready(channels.training_labels_colors)
            data = take!(channels.training_labels_colors)
            return data
        else
            return false
        end
    end
    return
end
get_results(field) = get_results_main(channels,master_data,model_data,field)

function empty_progress_channel_main(channels::Channels,field)
    field = fix_QML_types(field)
    if field=="Training data preparation"
        channel_temp = channels.training_data_progress
    elseif field=="Validation data preparation"
        channel_temp = channels.validation_data_progress
    elseif field=="Training data preparation modifiers"
        channel_temp = channels.training_data_modifiers
    elseif field=="Validation data preparation modifiers"
        channel_temp = channels.validation_data_modifiers
    elseif field=="Training"
        channel_temp = channels.training_progress
    elseif field=="Validation"
        channel_temp = channels.validation_progress
    elseif field=="Training modifiers"
        channel_temp = channels.training_modifiers
    elseif field=="Validation modifiers"
        channel_temp = channels.validation_modifiers
    elseif field=="Labels colors"
        channel_temp = channels.training_labels_colors
    end
    while true
        if isready(channel_temp)
            take!(channel_temp)
        else
            return
        end
    end
end
empty_progress_channel(field) = empty_progress_channel_main(channels,field)

function empty_results_channel_main(channels::Channels,field)
    field = fix_QML_types(field)
    if field=="Training data preparation"
        channel_temp = channels.training_data_results
    elseif field=="Validation data preparation"
        channel_temp = channels.validation_data_results
    elseif field=="Training"
        channel_temp = channels.training_results
    elseif field=="Validation"
        channel_temp = channels.validation_results
    end
    while true
        if isready(channel_temp)
            take!(channel_temp)
        else
            return nothing
        end
    end
end
empty_results_channel(field) = empty_results_channel_main(channels,field)

function put_channel_main(channels::Channels,field,value)
    field = fix_QML_types(field)
    value = fix_QML_types(value)
    if field=="Training data preparation"
        put!(channels.training_data_modifiers,value)
    elseif field=="Validation data preparation"
        put!(channels.validation_data_modifiers,value)
    elseif field=="Training"
        put!(channels.training_modifiers,value)
    elseif field=="Validation"
        put!(channels.validation_modifiers,value)
    end
end
put_channel(field,value) = put_channel_main(channels,field,value)

function display_image(buffer::Array{UInt32, 1},
                      width32::Int32,
                      height32::Int32)
    width = width32
    height = height32
    buffer = reshape(buffer, width, height)
    buffer = reinterpret(ARGB32, buffer)
    image = master_data.image
    if size(buffer)==reverse(size(image))
        buffer .= transpose(ARGB32.(image))
    end
    return
end

function save_model_main(model_data,url)
  BSON.@save(String(url),model_data)
end
save_model(url) = save_model_main(model_data,url)

function load_model_main(model_data,url)
  data = BSON.load(String(url))
  if haskey(data,:model_data)
      copystruct!(model_data,data[:model_data])
      return true
  else
      return false
  end
end
load_model(url) = load_model_main(model_data,url)
