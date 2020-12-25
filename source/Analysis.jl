
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
    # Initialize constants
    analysis = settings.Analysis
    options_analysis = analysis.Options
    model = model_data.model
    loss = model_data.loss
    features = model_data.features
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    labels_color,_,border = get_feature_data(features)
    num_feat = length(border)
    num_border = sum(border)
    apply_border = num_border>0
    scaling = options_analysis.scaling
    batch_size = options_analysis.minibatch_size
    # Get path and names
    filenames_vector = get_filenames(analysis_data.url_imgs)
    filenames_batched = batch_filenames(filenames_vector,batch_size)
    savepath = options_analysis.savepath
    # Get file extensions
    img_ext,img_sym_ext = get_image_ext(options_analysis.image_type)
    data_ext,data_sym_ext = get_data_ext(options_analysis.data_type)
    # Prepare set
    set = analysis_data.data_input
    num = length(set)
    # Initialize accumulators
    log_area_dist = map(x->x.Output.Area.area_distribution,features)
    log_area_obj = map(x->x.Output.Area.individual_obj_area,features)
    log_volume_dist = map(x->x.Output.Volume.volume_distribution,features)
    log_volume_obj = map(x->x.Output.Volume.individual_obj_volume,features)
    num_dist_area = sum(log_area_dist)
    num_dist_volume = sum(log_volume_dist)
    num_obj_area = sum(log_area_obj)
    num_obj_volume = sum(log_volume_obj)
    histograms_area = Vector{Vector{Histogram}}(undef,num)
    histograms_volume = Vector{Vector{Histogram}}(undef,num)
    objs_area = Vector{Vector{Vector{Float64}}}(undef,num)
    objs_volume = Vector{Vector{Vector{Float64}}}(undef,num)

    # Run analysis
    cnt = 1
    num_parts = 6
    offset = 20
    put!(channels.analysis_progress,2*num+1)
    @everywhere GC.gc()
    for i = 1:num
        # Stop if asked
        if isready(channels.analysis_modifiers)
            stop_cond::String = fetch(channels.training_modifiers)[1]
            if stop_cond=="stop"
                take!(channels.analysis_modifiers)
                break
            end
        end
        # Get neural network output
        input_data = set[i]
        predicted = forward(model,input_data,num_parts=num_parts,
            offset=offset,use_GPU=use_GPU)
        predicted_bool = predicted.>0.5
        size_dim4 = size(predicted_bool,4)
        put!(channels.analysis_progress,1)
        # Flatten and use border info if present
        masks = Vector{BitArray{3}}(undef,size_dim4)
        for j = 1:size_dim4
            temp_mask = predicted_bool[:,:,:,j]
            if apply_border
                border_mask = apply_border_data_main(temp_mask,model_data)
                temp_mask = cat3(temp_mask,border_mask)
            end
            masks[j] = temp_mask
        end
        # Make and export images
        filenames = filenames_batched[i]
        for j = 1:length(masks)
            filename = filenames[j]
            mask = masks[j]
            mask_to_img(mask,features,labels_color,border,savepath,filename,img_ext,img_sym_ext)
            mask_to_data(histograms_area,histograms_volume,objs_area,objs_volume,cnt,j,
                    mask,features,border,num,num_feat,num_border,output_options,scaling)
            cnt = cnt + 1
        end
        put!(channels.analysis_progress,1)
        @everywhere GC.safepoint()
    end
    # Export data
    export_histograms(histograms_area,histograms_volume,features,num,num_dist_area,
        num_dist_volume,log_area_dist,log_volume_dist,
        savepath,filenames_vector,data_ext,data_sym_ext)
    export_objs(objs_area,objs_volume,features,num,num_dist_area,
        num_dist_volume,log_area_obj,log_volume_obj,
        savepath,filenames_vector,data_ext,data_sym_ext)
    put!(channels.analysis_progress,1)
    return nothing
end
function analyse_main2(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    @everywhere settings,analysis_data,model_data
    remote_do(analyse_main,workers()[end],settings,analysis_data,model_data,channels)
end
analyse() = analyse_main2(settings,training_data,
model_data,channels)

function export_histograms(histograms_area::Vector{Vector{Histogram}},
        histograms_volume::Vector{Vector{Histogram}},features::Vector{Feature},num::Int64,
        num_dist_area::Int64,num_dist_volume::Int64,
        log_area_dist::Vector{Bool},log_volume_dist::Vector{Bool},savepath::String,
        filenames_vector::Vector{String},data_ext::String,data_sym_ext::Symbol)
    num_cols_dist = num_dist_area + num_dist_volume
    if num_cols_dist==0
        return nothing
    end
    for i = 1:num
        num_cols_dist = num_dist_area + num_dist_volume
        num_rows_area = maximum(map(x->length(x.weights),histograms_area[i]))
        num_rows_volume = maximum(map(x->length(x.weights),histograms_volume[i]))
        num_rows = max(num_rows_area,num_rows_volume)
        histogram_area = histograms_area[i]
        histogram_volume = histograms_volume[i]
        rows = Vector{Union{Float64,Nothing}}(undef,num_rows)
        fill!(rows,nothing)
        df_dists = DataFrame(repeat(rows,1,2*num_cols_dist), :auto)
        histograms_to_dataframe(df_dists,histogram_area,num_dist_area,0)
        offset = 2*num_dist_area
        histograms_to_dataframe(df_dists,histogram_volume,num_dist_volume,offset)
        names = map(x->x.name,features)
        names_area = get_dataframe_names(names,"area",log_area_dist,:dists)
        names_volume = get_dataframe_names(names,"volume",log_volume_dist,:dists)
        names_all = vcat(names_area,names_volume)
        rename!(df_dists, Symbol.(names_all))
        fname = filenames_vector[i]
        path = string(savepath,"/",fname,"/")
        if num_cols_dist>0
            name = string("Distributions ",fname,data_ext)
            save(path,name,df_dists,data_sym_ext)
        end
    end
    return nothing
end

function export_objs(objs_area::Vector{Vector{Vector{Float64}}},
        objs_volume::Vector{Vector{Vector{Float64}}},features::Vector{Feature},
        num::Int64,num_obj_area::Int64,num_obj_volume::Int64,
        log_area_obj::Vector{Bool},log_volume_obj::Vector{Bool},savepath::String,
        filenames_vector::Vector{String},data_ext::String,data_sym_ext::Symbol)
    num_cols_obj = num_obj_area + num_obj_volume
    if num_cols_obj==0
        return nothing
    end
    for i = 1:num
        num_rows_area = maximum(map(x->length(x),objs_area[i]))
        num_rows_volume = maximum(map(x->length(x),objs_volume[i]))
        num_rows = max(num_rows_area,num_rows_volume)
        obj_area = objs_area[i]
        obj_volume = objs_volume[i]
        rows = Vector{Union{Float64,Nothing}}(undef,num_rows)
        fill!(rows,nothing)
        df_objs = DataFrame(repeat(rows,1,num_cols_obj), :auto)
        objs_to_dataframe(df_objs,obj_area,num_obj_area,0)
        offset = num_obj_area
        objs_to_dataframe(df_objs,obj_volume,num_obj_volume,offset)
        names = map(x->x.name,features)
        names_area = get_dataframe_names(names,"area",log_area_obj,:objs)
        names_volume = get_dataframe_names(names,"volume",log_volume_obj,:objs)
        names_all = vcat(names_area,names_volume)
        rename!(df_objs, Symbol.(names_all))
        fname = filenames_vector[i]
        path = string(savepath,"/",fname,"/")
        if num_cols_obj>0
            name = string("Objects ",fname,data_ext)
            save(path,name,df_objs,data_sym_ext)
        end
    end
    return nothing
end

function get_dataframe_names(names::Vector{String},type::String,
        Bools::Vector{Bool},datatype::Symbol)
    names_x = String[]
    inds = findall(Bools)
    if datatype==:dists
        for i in inds
            name_current = names[i]
            name_edges = string(name_current,"_",type,"_edges")
            name_weights = string(name_current,"_",type,"_weights")
            push!(names_x,name_edges,name_weights)
        end
    elseif datatype==:objs
        for i in inds
            name_current = names[i]
            name = string(name_current,"_",type)
            push!(names_x,name)
        end
    end
    return names_x
end

function histograms_to_dataframe(df::DataFrame,histograms::Vector{Histogram},
        num::Int64,offset::Int64)
    for j = 1:2:num
        weights = histograms[j].weights
        numel = length(weights)
        edges = collect(histograms[j].edges[1])
        edges = map(ind->mean([edges[ind],edges[ind+1]]),1:numel)
        df[1:numel,j+offset] .= edges
        df[1:numel,j+offset+1] .= weights
    end
end

function objs_to_dataframe(df::DataFrame,objs::Vector{Vector{Float64}},
        num::Int64,offset::Int64)
    for j = 1:num
        objs_current = objs[j]
        numel = length(objs_current)
        df[1:numel,j+offset] .= objs_current
    end
end

function get_filenames(data::Vector{String})
    data = split.(data,"/")
    data = map(x->x[end],data)
    data = split.(data,".")
    data = map(x->string(x[1:end-1]...),data)
    return data
end

function batch_filenames(filenames::Vector{String},batch_size::Int64)
    len = length(filenames)
    num = len - batch_size
    val = max(0.0,floor(num/batch_size))
    finish = Int64(val*batch_size)
    inds = Vector(0:batch_size:finish)
    if isempty(inds)
        inds = [0]
    end
    num = length(inds)
    filename_batches = Vector{Vector{String}}(undef,num)
    for i = 1:num
        ind = inds[i]
        if i==num
            ind1 = ind+1
            ind2 = len
        else
            ind1 = ind+1
            ind2 = ind+batch_size
        end
        filename_batches[i] = filenames[ind1:ind2]
    end
    return filename_batches
end

function get_save_image_info(num_dims::Int64,features::Vector{Feature},border::Vector{Bool})
    num_feat = length(border)
    num_border = sum(border)

    logical_inds = BitArray{1}(undef,num_dims)
    img_names = Vector{String}(undef,0)
    for a = 1:num_feat
        feature = features[a]
        feature_name = feature.name
        if feature.Output.Mask.mask
            logical_inds[a] = true
            push!(img_names,feature_name)
        end
        if feature.border
            if features[a].Output.Mask.mask
                ind = a + num_feat
                logical_inds[ind] = true
                push!(img_names,string(feature_name," (border)"))
            end
            if features[a].Output.Mask.mask
                ind = num_feat + num_border + a
                logical_inds[ind] = true
                push!(img_names,string(feature_name," (applied border)"))
            end
        end
    end
    inds = findall(logical_inds)
    return inds,img_names
end

function mask_to_img(mask::BitArray{3},features::Vector{Feature},
        labels_color::Vector{Vector{Float64}},border::Vector{Bool},
        savepath::String,filename::String,ext::String,sym_ext::Symbol)
    num_dims = size(mask)[3]
    inds,img_names = get_save_image_info(num_dims,features,border)
    if isempty(inds)
        return nothing
    end
    border_colors = labels_color[findall(border)]
    labels_color = vcat(labels_color,border_colors,border_colors)
    perm_labels_color64 = map(x -> permutedims(x[:,:,:]/255,[3,2,1]),labels_color)

    num2 = length(labels_color)
    perm_labels_color = convert(Array{Array{Float32,3}},perm_labels_color64)
    predicted_color = Vector{Array{RGBA{Float32},2}}(undef,0)
    for j = 1:length(inds)
        ind = inds[j]
        mask_current = mask[:,:,ind]
        color = perm_labels_color[ind]
        mask_float = convert(Array{Float32,2},mask_current)
        mask_dim3 = cat3(mask_float,mask_float,mask_float)
        mask_dim3 = mask_dim3.*color
        mask_dim3 = cat3(mask_dim3,mask_float)
        mask_dim3 = permutedims(mask_dim3,[3,1,2])
        mask_RGB = colorview(RGBA,mask_dim3)
        img_name = img_names[j]
        path = string(savepath,"/",filename,"/")
        name = string(img_name," ",filename,ext)
        save(path,name,mask_RGB,sym_ext)
    end
    return nothing
end

function save(path::String,name::String,data,ext::Symbol)
    if !isdir(path)
        mkdir(path)
    end
    url = string(path,name)
    if isfile(url)
        rm(url)
    end
    if ext==:json
        open(url,"w") do f
            JSON.print(f,data)
        end
    elseif ext==:bson
        BSON.@save(url,data)
    elseif ext==:xlsx
        XLSX.writetable(url, collect(DataFrames.eachcol(data)), DataFrames.names(data))
    else
        FileIO.save(url,data)
    end
end

function get_image_ext(ind)
    ext = [".png",".tiff",".bson"]
    ext_symbol = [:png,:tiff,:bson]
    return ext[ind+1],ext_symbol[ind+1]
end

function get_data_ext(ind)
    ext = [".csv",".xlsx",".json",".bson"]
    ext_symbol = [:csv,:xlsx,:json,:bson]
    return ext[ind+1],ext_symbol[ind+1]
end

function mask_to_data(histograms_area::Vector{Vector{Histogram}},
        histograms_volume::Vector{Vector{Histogram}},
        objs_area::Vector{Vector{Vector{Float64}}},
        objs_volume::Array{Vector{Vector{Float64}}},i::Int64,j::Int64,
        mask::BitArray{3},features::Vector{Feature},border::Vector{Bool},num::Int64,
        num_feat::Int64,num_border::Int64,output_options::Output_options,scaling::Float64)
    temp_histograms_area = Histogram[]
    temp_histograms_volume = Histogram[]
    temp_objs_area = Vector{Float64}[]
    temp_objs_volume = Vector{Float64}[]
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
                push!(temp_histograms_area,make_histogram(area_values,area_options))
            end
            if area_obj_cond
                push!(temp_objs_area,area_values)
            end
        end
        if volume_dist_cond || volume_obj_cond
            volume_options = output_options.Volume
            volume_values = objects_volume(components,mask_current,scaling)
            if volume_dist_cond
                push!(temp_histograms_volume,make_histogram(volume_values,volume_options))
            end
            if volume_obj_cond
                push!(temp_objs_volume,volume_values)
            end
        end
    end
    histograms_area[i] = temp_histograms_area
    histograms_volume[i] = temp_histograms_volume
    objs_area[i] = temp_objs_area
    objs_volume[i] = temp_objs_volume
    return nothing
end

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
    return h
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
        histograms_area::Array{Histogram},histograms_volume::Array{Histogram},
        objs_area::Array{Vector{Float64},2},objs_volume::Array{Vector{Float64},2},
        filenames::Vector{String},options::Options_analysis)
    inds_bool = map(x->isassigned(mask_imgs, x),1:length(mask_imgs))
    if any(inds_bool)
        inds = findall(inds_bool)
    end
    inds_bool = map(x->isassigned(histograms_area, x),1:length(histograms_area))
    if any(inds_bool)
        inds = findall(inds_bool)
    end
    return nothing
end
