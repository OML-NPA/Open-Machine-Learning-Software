
# Get urls of files in a selected folder. Files are used for application.
function get_urls_application_main(application::Application,
        application_data::Application_data,model_data::Model_data)
    if model_data.type[2]=="Images"
        allowed_ext = ["png","jpg","jpeg"]
    end
    url_input = application_data.url_input
    folders = application_data.folders
    empty!(url_input)
    main_dir = application.folder_url
    dirs = application.checked_folders
    if isempty(main_dir) || isempty(dirs)
        @info "empty main dir"
    end
    for i = 1:length(dirs)
        dir = dirs[i]
        files_input = getfiles(joinpath(main_dir,dir))
        files_input = filter_ext(files_input,allowed_ext)
        push!(folders,dir)
        temp = Vector{String}(undef,0)
        for j = 1:length(files_input)
            push!(temp,joinpath(main_dir,dir,files_input[j]))
        end
        push!(url_input,temp)
    end
    return nothing
end
get_urls_application() =
    get_urls_application_main(application,application_data,model_data)

function prepare_application_data(urls::Vector{String})
    num = length(urls)
    data = Vector{Array{Float32,4}}(undef,length(urls))
    @threads for i = 1:num
        url = urls[i]
        image = load_image(url)
        data[i] = image_to_gray_float(image)[:,:,:,:]
    end
    data_out = reduce(cat4,data)
    return data_out
end

function get_filenames(urls::Vector{Vector{String}})
    num = length(urls)
    data = Vector{Vector{String}}(undef,num)
    for i = 1:num
        data_temp = copy(urls[i])
        data_temp = split.(data_temp,"\\")
        data_temp = map(x->x[end],data_temp)
        data_temp = split.(data_temp,".")
        data[i] = map(x->string(x[1:end-1]...),data_temp)
    end
    return data
end

# Batches filenames together allowing for correct naming during export
function batch_urls_filenames(urls::Vector{Vector{String}},batch_size::Int64)
    num = length(urls)
    filenames = get_filenames(urls)
    filename_batches = Vector{Vector{Vector{String}}}(undef,num)
    url_batches = Vector{Vector{Vector{String}}}(undef,num)
    for i = 1:num
        urls_temp = urls[i]
        filenames_temp = filenames[i]
        len = length(urls_temp)
        url_batches_temp = Vector{Vector{String}}(undef,0)
        filename_batches_temp = Vector{Vector{String}}(undef,0)
        num = len - batch_size
        val = max(0.0,floor(num/batch_size))
        finish = Int64(val*batch_size)
        inds = collect(0:batch_size:finish)
        if isempty(inds)
            inds = [0]
        end
        num = length(inds)
        for j = 1:num
            ind = inds[j]
            if j==num
                ind1 = ind+1
                ind2 = len
            else
                ind1 = ind+1
                ind2 = ind+batch_size
            end
            push!(url_batches_temp,urls_temp[ind1:ind2])
            push!(filename_batches_temp,filenames_temp[ind1:ind2])
        end
        url_batches[i] = url_batches_temp
        filename_batches[i] = filename_batches_temp
    end
    return url_batches,filename_batches
end

# Main function that performs application
function apply_main(settings::Settings,application_data::Application_data,
        model_data::Model_data,channels::Channels)
    # Initialize constants
    application = settings.Application
    application_options = application.Options
    apply_by_file = application_options.apply_by[1]=="file"
    model = model_data.model
    loss = model_data.loss
    features = model_data.features
    use_GPU = settings.Options.Hardware_resources.allow_GPU && has_cuda()
    labels_color,labels_incl,border = get_feature_data(features)
    num_feat = length(border)
    num_border = sum(border)
    apply_border = num_border>0
    scaling = application_options.scaling
    batch_size = application_options.minibatch_size
    # Output information
    log_area_obj = map(x->x.Output.Area.obj_area,features)
    log_area_obj_sum = map(x->x.Output.Area.obj_area_sum,features)
    log_area_dist = map(x->x.Output.Area.area_distribution,features)
    log_volume_obj = map(x->x.Output.Volume.obj_volume,features)
    log_volume_obj_sum = map(x->x.Output.Volume.obj_volume_sum,features)
    log_volume_dist = map(x->x.Output.Volume.volume_distribution,features)
    num_obj_area = count(log_area_obj)
    num_obj_area_sum = count(log_area_obj_sum)
    num_dist_area = count(log_area_dist)
    num_obj_volume = count(log_volume_obj)
    num_obj_volume_sum = count(log_volume_obj_sum)
    num_dist_volume = count(log_volume_dist)
    # Get savepath, folders and names
    folders = application.checked_folders
    num = length(folders)
    urls = application_data.url_input
    urls_batched,filenames_batched = batch_urls_filenames(urls,batch_size)
    savepath_main = application_options.savepath
    dirs = split(savepath_main,"/")
    for i=1:length(dirs)
        temp_path = join(dirs[1:i],"/")
        if !isdir(temp_path)
            mkdir(temp_path)
        end
    end
    # Get file extensions
    img_ext,img_sym_ext = get_image_ext(application_options.image_type)
    data_ext,data_sym_ext = get_data_ext(application_options.data_type)
    # Make savepath directory if does not exist
    if !isdir(savepath_main)
        mkdir(savepath_main)
    end
    # Run application
    cnt = 0
    num_parts = 20 # For dividing input image into n parts
    offset = 20 # For taking extra n pixels from both sides of an image part
    put!(channels.application_progress,sum(length.(urls_batched))+length(urls_batched))
    @everywhere GC.gc()
    for k = 1:num
        cnt = 0
        urls_batch = urls_batched[k]
        filenames_batch = filenames_batched[k]
        num_batch = length(urls_batch)
        savepath = joinpath(savepath_main,folders[k])
        # Initialize accumulators
        if apply_by_file
            num_init = num_batch
        else
            num_init = 1
        end
        objs_area = Vector{Vector{Vector{Float64}}}(undef,num_init)
        objs_volume = Vector{Vector{Vector{Float64}}}(undef,num_init)
        objs_area_sum = Vector{Vector{Float64}}(undef,num_init)
        objs_volume_sum = Vector{Vector{Float64}}(undef,num_init)
        histograms_area = Vector{Vector{Histogram}}(undef,num_init)
        histograms_volume = Vector{Vector{Histogram}}(undef,num_init)
        fill_no_ref!(objs_area,Vector{Vector{Float64}}(undef,num_feat))
        for i = 1:num_init
            fill_no_ref!(objs_area[i],Float64[])
        end
        fill_no_ref!(objs_volume,Vector{Vector{Float64}}(undef,num_feat))
        for i = 1:num_init
            fill_no_ref!(objs_volume[i],Float64[])
        end
        fill_no_ref!(objs_area_sum,Vector{Float64}(undef,num_obj_area_sum))
        fill_no_ref!(objs_volume_sum,Vector{Float64}(undef,num_obj_volume_sum))
        fill_no_ref!(histograms_area,Vector{Histogram}(undef,num_dist_area))
        fill_no_ref!(histograms_volume,Vector{Histogram}(undef,num_dist_volume))
        for l = 1:num_batch
            # Stop if asked
            if isready(channels.application_modifiers)
                stop_cond::String = fetch(channels.training_modifiers)[1]
                if stop_cond=="stop"
                    take!(channels.application_modifiers)
                    break
                end
            end
            # Get neural network output
            input_data = prepare_application_data(urls_batch[l])
            predicted = forward(model,input_data,num_parts=num_parts,
                offset=offset,use_GPU=use_GPU)
            predicted_bool = predicted.>0.5
            size_dim4 = size(predicted_bool,4)
            # Flatten and use border info if present
            masks = Vector{BitArray{3}}(undef,size_dim4)
            for j = 1:size_dim4
                temp_mask = predicted_bool[:,:,:,j]
                if apply_border
                    border_mask = apply_border_data_main(temp_mask,model_data)
                    temp_mask = cat3(temp_mask,border_mask)
                end
                @threads for l=1:num_feat
                    min_area = features[l].min_area
                    if min_area>1
                        if border[l]
                            ind = l + num_feat + num_border
                        else
                            ind = l
                        end
                        temp_array = temp_mask[:,:,ind]
                        # Fix areaopen not removing all objects less than min area
                        for k=1:2
                            areaopen!(temp_array,min_area)
                        end
                        temp_mask[:,:,ind] .= temp_array
                    end
                end
                masks[j] = temp_mask
            end
            filenames = filenames_batch[l]
            for j = 1:length(masks)
                if apply_by_file
                    cnt = cnt + 1
                else
                    cnt = 1
                end
                filename = filenames[j]
                mask = masks[j]
                # Make and export images
                mask_to_img(mask,features,labels_color,border,savepath,filename,img_ext,img_sym_ext)
                # Make data out of masks
                mask_to_data(objs_area,objs_volume,cnt,mask,features,labels_incl,border,
                    num_feat,num_border,scaling)
            end
            put!(channels.application_progress,1)
            @everywhere GC.safepoint()
        end
        if num_obj_area_sum>0 
            for i = 1:num_init
                for j = 1:num_feat
                    if features[j].Output.Area.obj_area_sum
                        objs_area_sum[i][j] = sum(objs_area[i][j])
                    end
                end
            end
        end
        if num_obj_volume_sum>0 
            for i = 1:num_init
                for j = 1:num_feat
                    if features[j].Output.Volume.obj_volume_sum
                        objs_volume_sum[i][j] = sum(objs_volume[i][j])
                    end
                end
            end
        end
        data_to_histograms(histograms_area,histograms_volume,objs_area,objs_volume,
        features,num_init,num_feat,num_border,border)
        # Export data
        if apply_by_file
            filenames = filenames_batch
        else
            filenames = [folders[k]]
        end
        export_histograms(histograms_area,histograms_volume,features,num_init,num_dist_area,
            num_dist_volume,log_area_dist,log_volume_dist,
            savepath,filenames,data_ext,data_sym_ext)
        export_objs("Objects",objs_area,objs_volume,features,num_init,num_obj_area,
            num_obj_volume,log_area_obj,log_volume_obj,
            savepath,filenames,data_ext,data_sym_ext)
        export_objs("Objects sum",objs_area_sum,objs_volume_sum,features,num_init,num_obj_area_sum,
            num_obj_volume_sum,log_area_obj_sum,log_volume_obj_sum,
            savepath,filenames,data_ext,data_sym_ext)
        put!(channels.application_progress,1)
    end
    return nothing
end
function apply_main2(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    @everywhere settings,application_data,model_data
    remote_do(apply_main,workers()[end],settings,application_data,model_data,channels)
end
apply() = apply_main2(settings,training_data,
model_data,channels)

#---Histogram and objects related functions
function objects_count(components::Array{Int64,2})
    return maximum(components)
end

function objects_area(mask_current::BitArray{2},components::Array{Int64,2},
        components_vector::Vector{Array{Int64,2}},labels_incl::Vector{Vector{Int64}},
        scaling::Float64,l::Int64)
    scaling = scaling^2
    incl_bool = map(x->any(x.==l),labels_incl)
    ind = findfirst(incl_bool)
    if isnothing(ind)
        area = component_lengths(components)[2:end]
        area_out = convert(Vector{Float64},area)./scaling
    else
        components_parent = components_vector[ind]
        num = maximum(components_parent)
        area_out = Vector{Float64}(undef,num)
        @threads for i = 1:num
            ind_bool = components_parent.==i
            area_out[i] = count(mask_current[ind_bool])./scaling
        end
    end
    return area_out
end

# Makes a 3D representation of a 2D object based on optimising circularity
function func2D_to_3D(objects_mask::BitArray{2})
    D = Float32.(distance_transform(feature_transform((!).(objects_mask))))
    w = zeros(Float32,(size(D)...,8))
    inds = vcat(1:4,6:9)
    @threads for i = 1:8
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

function objects_volume(objects_mask::BitArray{2},components::Array{Int64,2},
        components_vector::Vector{Array{Int64,2}},labels_incl::Vector{Vector{Int64}},
        scaling::Float64,l::Int64)
    volume_model = func2D_to_3D(objects_mask)
    scaling = scaling^3
    num = maximum(components)
    incl_bool = map(x->any(x.==l),labels_incl)
    ind = findfirst(incl_bool)
    if isnothing(ind)
        num = maximum(components)
        volumes_out = Vector{Float64}(undef,num)
        @threads for i = 1:num
            logical_inds = components.==i
            pixels = volume_model[logical_inds]
            volumes_out[i] = 2*sum(pixels)/scaling
        end
    else
        components_parent = components_vector[ind]
        num = maximum(components_parent)
        volumes_out = Vector{Float64}(undef,num)
        @threads for i = 1:num
            ind_bool = components_parent.==i
            pixels = volume_model[ind_bool]
            volumes_out[i] = 2*sum(pixels)/scaling
        end
    end
    return volumes_out
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
    inds = 1:2:2*num
    for j = 1:num
        weights = histograms[j].weights
        numel = length(weights)
        edges = collect(histograms[j].edges[1])
        edges = map(ind->mean([edges[ind],edges[ind+1]]),1:numel)
        df[1:numel,inds[j]+offset] .= edges
        df[1:numel,inds[j]+offset+1] .= weights
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

function objs_to_dataframe(df::DataFrame,objs::Vector{Float64},
        num::Int64,offset::Int64)
    start = offset + 1
    finish = num + start -1
    df[1,start:finish] .= objs
end

function data_to_histograms(histograms_area::Vector{Vector{Histogram}},
        histograms_volume::Vector{Vector{Histogram}},
        objs_area::Vector{Vector{Vector{Float64}}},
        objs_volume::Array{Vector{Vector{Float64}}},features::Vector{Feature},num_batch::Int64,
        num_feat::Int64,num_border::Int64,border::Vector{Bool})
    @threads for i = 1:num_batch
        temp_histograms_area = histograms_area[i]
        temp_histograms_volume = histograms_volume[i]
        @threads for l = 1:num_feat
            output_options = features[l].Output
            area_dist_cond = output_options.Area.area_distribution
            volume_dist_cond = output_options.Volume.volume_distribution
            ind = l
            if border[l]==true
                ind = l + num_border + num_feat
            end
            if area_dist_cond
                area_options = output_options.Area
                area_values = objs_area[i][l]
                temp_histograms_area[l] = make_histogram(area_values,area_options)
            end
            if volume_dist_cond
                volume_options = output_options.Volume
                volume_values = objs_volume[i][l]
                temp_histograms_volume[l] = make_histogram(volume_values,volume_options)
            end
        end
    end
    return nothing
end

function mask_to_data(objs_area::Vector{Vector{Vector{Float64}}},
        objs_volume::Vector{Vector{Vector{Float64}}},cnt::Int64,mask::BitArray{3},
        features::Vector{Feature},labels_incl::Vector{Vector{Int64}},
        border::Vector{Bool},num_feat::Int64,num_border::Int64,scaling::Float64)
    temp_objs_area = objs_area[cnt]
    temp_objs_volume = objs_volume[cnt]
    components_vector = Vector{Array{Int64,2}}(undef,num_feat)
    for l = 1:num_feat
        output_options = features[l].Output
        area_dist_cond = output_options.Area.area_distribution
        area_obj_cond = output_options.Area.obj_area
        area_sum_obj_cond = output_options.Area.obj_area_sum
        volume_dist_cond = output_options.Volume.volume_distribution
        volume_obj_cond = output_options.Volume.obj_volume
        volume_sum_obj_cond = output_options.Volume.obj_volume_sum
        ind = l
        if border[l]==true
            ind = l + num_border + num_feat
        end
        mask_current = mask[:,:,ind]
        components = label_components(mask_current,conn(4))
        components_vector[l] = components
        if area_dist_cond || area_obj_cond || area_sum_obj_cond
            temp_objs_area2 = temp_objs_area[l]
            area_options = output_options.Area
            area_values = objects_area(mask_current,components,
                components_vector,labels_incl,scaling,l)
            if area_obj_cond || area_sum_obj_cond
                push!(temp_objs_area2,area_values...)
            end
        end
        if volume_dist_cond || volume_obj_cond || volume_sum_obj_cond
            temp_objs_volume2 = temp_objs_volume[l]
            volume_options = output_options.Volume
            volume_values = objects_volume(mask_current,components,
                components_vector,labels_incl,scaling,l)
            if volume_obj_cond || volume_sum_obj_cond
                push!(temp_objs_volume2,volume_values...)
            end
        end
    end
    return nothing
end

function make_histogram(values::Vector{<:Real}, options::Union{Output_area,Output_volume})
    if options.binning==0
        h = fit(Histogram, values)
    elseif options.binning==1
        maxval = maximum(values)
        minval = minimum(values)
        dif = maxval-minval
        step = dif/(options.value-1)
        bins = minval:step:maxval
        h = fit(Histogram, values,bins)
    else
        num = round(maximum(values)/options.value)
        h = fit(Histogram, values, nbins=num)
    end
    if options.normalisation==0
        h = normalize(h, mode=:pdf)
    elseif options.normalisation==1
        h = normalize(h, mode=:density)
    elseif options.normalisation==2
        h = normalize(h, mode=:probability)
    else
        h = normalize(h, mode=:none)
    end
    return h
end

function export_histograms(histograms_area::Vector{Vector{Histogram}},
        histograms_volume::Vector{Vector{Histogram}},features::Vector{Feature},num::Int64,
        num_dist_area::Int64,num_dist_volume::Int64,
        log_area_dist::Vector{Bool},log_volume_dist::Vector{Bool},savepath::String,
        filenames::Vector{String},data_ext::String,data_sym_ext::Symbol)
    num_cols_dist = num_dist_area + num_dist_volume
    if num_cols_dist==0
        return nothing
    end
    @threads for i = 1:num
        num_cols_dist = num_dist_area + num_dist_volume
        if num_dist_area>0
            num_rows_area = maximum(map(x->length(x.weights),histograms_area[i]))
        else
            num_rows_area = 0
        end
        if num_dist_volume>0
            num_rows_volume = maximum(map(x->length(x.weights),histograms_volume[i]))
        else
            num_rows_volume = 0
        end
        num_rows = max(num_rows_area,num_rows_volume)
        histogram_area = histograms_area[i]
        histogram_volume = histograms_volume[i]
        rows = Vector{Union{Float64,String}}(undef,num_rows)
        fill!(rows,"")
        df_dists = DataFrame(repeat(rows,1,2*num_cols_dist), :auto)
        histograms_to_dataframe(df_dists,histogram_area,num_dist_area,0)
        offset = 2*num_dist_area
        histograms_to_dataframe(df_dists,histogram_volume,num_dist_volume,offset)
        names = map(x->x.name,features)
        names_area = get_dataframe_names(names,"area",log_area_dist,:dists)
        names_volume = get_dataframe_names(names,"volume",log_volume_dist,:dists)
        names_all = vcat(names_area,names_volume)
        rename!(df_dists, Symbol.(names_all))
        fname = filenames[i]
        name = string("Distributions ",fname,data_ext)
        save(savepath,name,df_dists,data_sym_ext)
    end
    return nothing
end

function export_objs(type_name::String,objs_area::Vector,
        objs_volume::Vector,features::Vector{Feature},
        num::Int64,num_obj_area::Int64,num_obj_volume::Int64,
        log_area_obj::Vector{Bool},log_volume_obj::Vector{Bool},savepath::String,
        filenames::Vector{String},data_ext::String,data_sym_ext::Symbol)
    num_cols_obj = num_obj_area + num_obj_volume
    if num_cols_obj==0
        return nothing
    end
    for i = 1:num
        if num_obj_area>0
            num_rows_area = maximum(map(x->length(x),objs_area[i]))
        else
            num_rows_area = 0
        end
        if num_obj_volume>0
            num_rows_volume = maximum(map(x->length(x),objs_volume[i]))
        else
            num_rows_volume = 0
        end
        num_rows = max(num_rows_area,num_rows_volume)
        obj_area = objs_area[i]
        obj_volume = objs_volume[i]
        rows = Vector{Union{Float64,String}}(undef,num_rows)
        fill!(rows,"")
        df_objs = DataFrame(repeat(rows,1,num_cols_obj), :auto)
        objs_to_dataframe(df_objs,obj_area,num_obj_area,0)
        offset = num_obj_area
        objs_to_dataframe(df_objs,obj_volume,num_obj_volume,offset)
        names = map(x->x.name,features)
        names_area = get_dataframe_names(names,"area",log_area_obj,:objs)
        names_volume = get_dataframe_names(names,"volume",log_volume_obj,:objs)
        names_all = vcat(names_area,names_volume)
        rename!(df_objs, Symbol.(names_all))
        fname = filenames[i]
        name = string(type_name," ",fname,data_ext)
        save(savepath,name,df_objs,data_sym_ext)
    end
    return nothing
end

#---Image related functions
function get_save_image_info(num_dims::Int64,features::Vector{Feature},border::Vector{Bool})
    num_feat = length(border)
    num_border = sum(border)
    logical_inds = BitArray{1}(undef,num_dims)
    img_names = Vector{String}(undef,num_feat+num_border*2)
    for a = 1:num_feat
        feature = features[a]
        feature_name = feature.name
        if feature.Output.Mask.mask
            logical_inds[a] = true
            img_names[a] = feature_name
        end
        if feature.border
            if features[a].Output.Mask.mask_border
                ind = a + num_feat
                logical_inds[ind] = true
                img_names[ind] = string(feature_name," (border)")
            end
            if features[a].Output.Mask.mask_applied_border
                ind = num_feat + num_border + a
                logical_inds[ind] = true
                img_names[ind] = string(feature_name," (applied border)")
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
    for j = 1:length(inds) #@threads 
        ind = inds[j]
        mask_current = mask[:,:,ind]
        color = perm_labels_color[ind]
        mask_float = convert(Array{Float32,2},mask_current)
        mask_dim3 = cat3(mask_float,mask_float,mask_float)
        mask_dim3 = mask_dim3.*color
        mask_dim3 = cat3(mask_dim3,mask_float)
        mask_dim3 = permutedims(mask_dim3,[3,1,2])
        mask_RGB = colorview(RGBA,mask_dim3)
        img_name = img_names[ind]
        path = joinpath(savepath,filename)
        name = string(img_name," ",filename,ext)
        save(path,name,mask_RGB,sym_ext)
    end
    return nothing
end

function export_output(mask_imgs::Vector{Vector{Array{RGBA{Float32},2}}},
        histograms_area::Array{Histogram},histograms_volume::Array{Histogram},
        objs_area::Array{Vector{Float64},2},objs_volume::Array{Vector{Float64},2},
        filenames::Vector{String},options::Application_options)
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

#---Saving
function get_data_ext(ind)
    ext = [".csv",".xlsx",".json",".bson"]
    ext_symbol = [:csv,:xlsx,:json,:bson]
    return ext[ind+1],ext_symbol[ind+1]
end

function get_image_ext(ind)
    ext = [".png",".tiff",".bson"]
    ext_symbol = [:png,:tiff,:bson]
    return ext[ind+1],ext_symbol[ind+1]
end

function save(path::String,name::String,data,ext::Symbol)
    if !isdir(path)
        dirs = splitpath(path)
        start = length(dirs) - 3
        for i=start:length(dirs)
            temp_path = join(dirs[1:i],'/')
            if !isdir(temp_path)
                mkdir(temp_path)
            end
        end
    end
    url = joinpath(path,name)
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
