
function get_urls_analysis_main(analysis::Analysis,analysis_data::Analysis_data)
    url_imgs = analysis_data.url_imgs
    empty!(url_imgs)
    main_dir = analysis.folder_url
    dirs = analysis.checked_folders
    if isempty(main_dir) || isempty(dirs)
        @info "empty main dir"
    end
    for k = 1:length(dirs)
        files_imgs = getfiles(string(main_dir,"/",dirs[k]))
        for l = 1:length(files_imgs)
            push!(url_imgs,string(main_dir,"/",dirs[k],"/",files_imgs[l]))
        end
    end
    return nothing
end
get_urls_analysis() =
    get_urls_analysis_main(analysis,analysis_data)

function prepare_analysis_data_main(analysis_data::Analysis_data,
        features::Vector{Feature},progress::RemoteChannel,results::RemoteChannel)
    put!(progress,2)
    images = load_images(analysis_data)
    put!(progress,1)
    if isempty(features)
        @info "empty features"
        return nothing
    end
    labels_color,labels_incl,border = get_feature_data(features)
    #data_input = Vector{Array{Float32,2}}(undef,length(images))
    data = map(x->image_to_gray_float(x)[:,:,:,:],images)
    put!(results,data)
    put!(progress,1)
    return nothing
end
function prepare_analysis_data_main2(analysis_data::Analysis_data,
        features::Vector{Feature},progress::RemoteChannel,results::RemoteChannel)
    @everywhere analysis_data
    remote_do(prepare_analysis_data_main,workers()[end],analysis_data,
    features,progress,results)
end
prepare_analysis_data() = prepare_analysis_data_main2(analysis_data,
    model_data.features,channels.analysis_data_progress,
    channels.analysis_data_results)

function analyse_main(settings::Settings,analysis_data::Analysis_data,
        model_data::Model_data,channels::Channels)
    analysis = settings.Analysis
    analysis_options = analysis.Options
    model = model_data.model
    loss = model_data.loss
    features = model_data.features
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    _,_,border = get_feature_data(features)
    num_feat = length(border)
    num_border = sum(border)
    apply_border = num_border>0
    scaling = analysis_options.scaling
    minibatch_size = analysis_options.minibatch_size
    # Preparing set
    set = analysis_data.data_input
    num = length(set)
    predicted_array = Vector{BitArray{4}}(undef,0)
    put!(channels.analysis_progress,[2*num])
    num_parts = 6
    offset = 20
    file_names = get_file_names(analysis_data.url_imgs)
    @everywhere GC.gc()
    for i = 1:num
        if isready(channels.analysis_modifiers)
            stop_cond::String = fetch(channels.training_modifiers)[1]
            if stop_cond=="stop"
                take!(channels.analysis_modifiers)
                break
            end
        end
        input_data = set[i]
        predicted = forward(model,input_data,num_parts=num_parts,
            offset=offset,use_GPU=use_GPU)
        predicted_bool = predicted.>0.5
        size_dim4 = size(predicted_bool,4)
        masks = Vector{BitArray{3}}(undef,size_dim4)
        for j in 1:size_dim4
            temp_mask = predicted_bool[:,:,:,j]
            if apply_border
                border_mask = apply_border_data_main(temp_mask,model_data)
                temp_mask::BitArray{3} = cat3(temp_mask,border_mask)
            end
            masks[j] = temp_mask
        end
        for k = 1:length(masks)
            mask = masks[k]
            mask_to_img(mask,labels_color,labels_incl,border)
            mask_to_data(mask,features,num,num_feat,num_border,output_options,scaling)
        end
        put!(channels.analysis_progress,1)
        @everywhere GC.safepoint()
    end
    return nothing
end

function get_file_names(data::Vector{String})
    data = split.(data,"/")
    data = map(x->x[end],data)
    data = split.(data,".")
    data = map(x->string(x[1:end-1]...),data)
    return data
end

function analyse_main2(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    @everywhere settings,training_data,model_data
    remote_do(validate_main,workers()[end],settings,training_data,model_data,channels)
end
analyse() = remote_do(analyse_main,workers()[end],settings,training_data,
model_data,channels)

function make_histogram(values::Vector{<:Real}, options::Union{Output_area,Output_volume})
    if options.binning==0
        h = fit(Histogram, values)
    elseif options.binning==1
        h = fit(Histogram, values, nbins=options.value)
    else
        num = round(maximum(values)/options.value)
        h = fit(Histogram, values, nbins=num)
    end
    if options.normalisation==0
        h = normalize(h, mode=:pdf)
    elseif area_options.normalisation==1
        h = normalize(h, mode=:density)
    elseif area_options.normalisation==2
        h = normalize(h, mode=:probability)
    else
        h = normalize(h, mode=:none)
    end
    return nothing
end

function mask_to_img(data::BitArray{4},labels_color::Vector{Vector{Float64}},
        labels_incl::Vector{Vector{Int64}},border::Vector{Bool})
    labels_color,labels_incl,border = get_feature_data(features)
    num_feat = length(border)
    num_border = sum(border)
    num_dims = size(masks)[3]
    logical_inds = BitArray{1}(undef,num_dims)
    for a = 1:num_feat
        feature = features[a]
        if feature.Output.Mask.mask
            logical_inds[a] = true
        end
        if feature.border
            if features[a].Output.Mask.mask
                ind = a + num_feat
                logical_inds[ind] = true
            end
            if features[a].Output.Mask.mask
                ind = num_feat + num_border + a
                logical_inds[ind] = true
            end
        end
    end
    if !any(logical_inds)
        return nothing
    end
    border_colors = labels_color[findall(border)]
    labels_color = vcat(labels_color,border_colors,border_colors)
    perm_labels_color = map(x -> permutedims(x[:,:,:]/255,[3,2,1]),labels_color)

    num2 = length(labels_color)
    perm_labels_color = convert(Array{Array{Float32,3}},perm_labels_color)

    inds = findall(logical_inds)
    predicted_color = Vector{Array{RGBA{Float32},2}}(undef,0)
    for j in inds
        color = perm_labels_color[j]
        predicted_bool = data[:,:,j].>0.5
        temp = convert(Array{Float32,2},predicted_bool)
        temp2 = cat3(temp,temp,temp)
        temp2 = temp.*color
        temp2 = cat3(temp2,temp)
        temp2 = permutedims(temp2,[3,1,2])
        temp3 = colorview(RGBA,temp2)
        temp3 = collect(temp3)
        push!(predicted_color,temp3)
    end
    return predicted_color
end

function mask_to_data(mask::Array{Float32},features::Vector{Feature},num::Int64,num_feat::Int64,
        num_border::Int64,output_options::Output_options,scaling::Float64)
    area_histograms = Array{Histogram}(undef,num,num_feat)
    volume_histograms = Array{Histogram}(undef,num,num_feat)
    obj_areas = Array{Vector{Float64}}(undef,num,num_feat)
    obj_volumes = Array{Vector{Float64}}(undef,num,num_feat)
    for j = 1:num_feat
        output_options = features[j].Output
        area_dist_cond = output_options.Area.area_distribution
        area_obj_cond = output_options.Area.individual_obj_area
        volume_dist_cond = output_options.Area.area_distribution
        volume_obj_cond = output_options.Area.individual_obj_area
        ind = j
        if border[j]==true
            ind = j + num_border + num_feat
        end
        mask_current = mask[:,:,ind]
        components = label_components(mask_current,conn(4))
        if area_dist_cond || area_obj_cond
            area_options = output_options.Area
            area_values = objects_area(components,scaling)
            if area_dist_cond
                area_histograms[i,j] = make_histogram(area_values,area_options)
            end
            if area_obj_cond
                obj_areas[i,j] = area_values
            end
        end
        if volume_dist_cond || volume_obj_cond
            volume_options = output_options.Volume
            volume_values = objects_volume(components,mask_current,scaling)
            if volume_dist_cond
                volume_histograms[i,j] = make_histogram(volume_values,volume_options)
            end
            if volume_obj_cond
                obj_volumes[i,j] = volume_values
            end
        end
    end
    return nothing
end

function objects_area(components::Array{Int64,2},scaling::Float64)
    area = component_lengths(components)[2:end]
    area = convert(Vector{Float64},area).*scaling
    return area
end

function objects_count(components::Array{Int64,2})
    return maximum(components)
end

function func2D_to_3D(objects_mask::BitArray{2})
    D = Float32.(distance_transform(feature_transform((!).(objects_mask))))
    w = zeros(Float32,(size(D)...,8))
    inds = vcat(1:4,6:9)
    for i = 1:8
      u = zeros(Float32,(9,1))
      u[inds[i]] = 1
      u = reshape(u,(3,3))
      w[:,:,i] = imfilter(D,centered(u))
    end
    pks = all(D.>=w,dims=3)[:,:] .& objects_mask
    mask2 = BitArray(undef,size(objects_mask))
    fill!(mask2,true)
    mask2[pks] .= false
    D2 = Float32.(distance_transform(feature_transform((!).(mask2))))
    D2[(!).(objects_mask)] .= 0
    mask_out = sqrt.((D+D2).^2-D2.^2)
    return mask_out
end

function objects_volume(components::Array{Int64},objects_mask::BitArray{2},scaling::Float64)
    volume_model = func2D_to_3D(objects_mask)
    num = maximum(components)
    volumes = Vector{Float64}(undef,num)
    scaling = scaling^3
    for i = 1:num
        logical_inds = components.==i
        pixels = volume_model[logical_inds]
        volumes[i] = 2*sum(pixels)/scaling
    end
    return volumes
end

function export_output(mask_imgs::Vector{Vector{Array{RGBA{Float32},2}}},
        area_histograms::Array{Histogram},volume_histograms::Array{Histogram},
        obj_areas::Array{Vector{Float64},2},obj_volumes::Array{Vector{Float64},2},
        file_names::Vector{String},options::Options_analysis)
    inds_bool = map(x->isassigned(mask_imgs, x),1:length(mask_imgs))
    if any(inds_bool)
        inds = findall(inds_bool)
    end
    inds_bool = map(x->isassigned(area_histograms, x),1:length(area_histograms))
    if any(inds_bool)
        inds = findall(inds_bool)
    end
    return nothing
end

function export_images(mask_imgs::Vector{Vector{Array{RGBA{Float32},2}}},
        file_names::Vector{String},options::Options_analysis)
    for i = 1:length(mask_imgs)
        current_img = mask_imgs[i]
        for j = 1:length(current_img)

        end
    end
    return nothing
end
