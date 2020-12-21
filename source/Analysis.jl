
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
function  prepare_analysis_data_main2(analysis_data::Analysis_data,
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
    model = model_data.model
    loss = model_data.loss
    # Preparing set
    set = analysis_data.data_input
    # Load model onto GPU, if enabled
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    if use_GPU
        model = move(model,gpu)
    end
    # Validate
    num = length(set)
    predicted_array = Vector{BitArray{4}}(undef,0)
    put!(channels.analysis_progress,[2*num])
    num_parts = 6
    offset = 20
    @everywhere GC.gc()
    for i = 1:num
        if isready(channels.analysis_modifiers)
            if fetch(channels.analysis_modifiers)[1]=="stop"
                take!(channels.analysis_modifiers)
                break
            end
        end
        input_data = set[i]
        if num_parts==1
            predicted = model(input_data)
        else
            function accum_parts(model::Chain,input_data::Array{Float32,4},
                    num_parts::Int64,use_GPU::Bool)
                input_size = size(input_data)
                max_value = max(input_size...)
                ind_max = findfirst(max_value.==input_size)
                ind_split = Int64(floor(max_value/num_parts))
                predicted = Vector{Array{Float32}}(undef,0)
                for j = 1:num_parts
                    function prepare_data(input_data::Array{Float32,4},
                            ind_split::Int64,j::Int64)
                        start_ind = 1 + (j-1)*ind_split-1
                        end_ind = start_ind + ind_split-1
                        correct_size = end_ind-start_ind+1
                        start_ind = start_ind - offset
                        end_ind = end_ind + offset
                        start_ind = start_ind<1 ? 1 : start_ind
                        end_ind = end_ind>max_value ? max_value : end_ind
                        temp_data = input_data[:,start_ind:end_ind,:,:]
                        max_dim_size = size(temp_data,ind_max)
                        offset_add = Int64(ceil(max_dim_size/16)*16) - max_dim_size
                        temp_data = pad(temp_data,[0,offset_add],same)
                        return temp_data,correct_size,offset_add
                    end
                    function fix_size(temp_predicted::Union{Array{Float32,3},CuArray{Float32,3}},
                            correct_size::Int64,ind_max::Int64,offset_add::Int64,j::Int64)
                        temp_size = size(temp_predicted,ind_max)
                        offset_temp = (temp_size - correct_size) - offset_add
                        if offset_temp>0
                            div_result = offset_add/2
                            offset_add1 = Int64(floor(div_result))
                            offset_add2 = Int64(ceil(div_result))
                            if j==1
                                temp_predicted = temp_predicted[:,
                                    (1+offset_add1):(end-offset_temp-offset_add2),:,:]
                            elseif j==num_parts
                                temp_predicted = temp_predicted[:,
                                    (1+offset_temp+offset_add1):(end-offset_add2),:,:]
                            else
                                temp = (temp_size - correct_size - offset_add)/2
                                offset_temp = Int64(floor(temp))
                                offset_temp2 = Int64(ceil(temp))
                                temp_predicted = temp_predicted[:,
                                    (1+offset_temp+offset_add1):(end-offset_temp2-offset_add2),:,:]
                            end
                        elseif offset_temp<0
                            temp_predicted = pad(temp_predicted,[0,-offset_temp])
                        end
                    end
                    if j==num_parts
                        ind_split = ind_split+rem(max_value,num_parts)
                    end
                    temp_data,correct_size,offset_add = prepare_data(input_data,ind_split,j)
                    if use_GPU
                        temp_data = gpu(temp_data)
                    end
                    temp_predicted = model(temp_data)[:,:,:]
                    temp_predicted = fix_size(temp_predicted,correct_size,ind_max,offset_add,j)
                    push!(predicted,cpu(temp_predicted))
                    @everywhere GC.safepoint()
                end
                return hcat(predicted...)
            end
            predicted = accum_parts(model,input_data,num_parts,use_GPU)
        end
        predicted_bool = predicted.>0.5
        size_dim4 = size(predicted_bool,4)
        if size_dim4!=1
            predicted_bool_split = Iterators.partition(predicted_bool,)
            push!(predicted_array,predicted_bool_split...)
        else
            push!(predicted_array,predicted_bool)
        end
        put!(channels.analysis_progress,1)
        @everywhere GC.safepoint()
    end
    _,_,border = get_feature_data(model_data.features)
    if any(border)
        border_array = map(x->apply_border_data_main(x,model_data)[:,:,:,:],predicted_array)
        predicted_array = cat.(predicted_array,border_array,dims=3)
    end
    features = model_data.features
    num_feat = length(border)
    num_border = sum(border)
    scaling = settings.Analysis.Options.scaling
    mask_imgs = Vector{Vector{Array{RGBA{Float32},2}}}(undef,num)
    area_histograms = Array{Histogram}(undef,num,num_feat)
    volume_histograms = Array{Histogram}(undef,num,num_feat)
    obj_areas = Array{Vector{Float64}}(undef,num,num_feat)
    obj_volumes = Array{Vector{Float64}}(undef,num,num_feat)
    for i = 1:num
        masks = predicted_array[i]
        mask_imgs[i] = masks_to_imgs(masks,features)
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
            mask_current = masks[:,:,ind]
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
    end
    file_names = get_file_names(analysis_data.url_imgs)
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
end

function masks_to_imgs(data::BitArray{4},features::Vector{Feature})
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
        temp2 = cat(temp,temp,temp,dims=3)
        temp2 = temp.*color
        temp2 = cat(temp2,temp,dims=3)
        temp2 = permutedims(temp2,[3,1,2])
        temp3 = colorview(RGBA,temp2)
        temp3 = collect(temp3)
        push!(predicted_color,temp3)
    end
    return predicted_color
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
end

function export_images(mask_imgs::Vector{Vector{Array{RGBA{Float32},2}}},
        file_names::Vector{String},options::Options_analysis)
    for i = 1:length(mask_imgs)
        current_img = mask_imgs[i]
        for j = 1:length(current_img)

        end
    end
end
