
function analyse_main(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    training = settings.Training
    analysis = training_data.Analysis_data
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
    accuracy_array = Vector{Float32}(undef,num)
    predicted_array = Vector{Array{Float32}}(undef,num)
    loss_array = Vector{Float32}(undef,num)
    put!(channels.analysis_progress,[2*num])
    num_parts = 6
    offset = 20
    @everywhere GC.gc()
    for i = 1:num
        if isready(channels.analysis_modifiers)
            if fetch(channels.analysis_modifiers)[1]=="stop"
                take!(channels.validation_modifiers)
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
                    function fix_size(temp_predicted::Union{Array{Float32,4},CuArray{Float32,4}},
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
                    temp_predicted = model(temp_data)
                    temp_predicted = fix_size(temp_predicted,correct_size,ind_max,offset_add,j)
                    push!(predicted,cpu(temp_predicted))
                    @everywhere GC.safepoint()
                end
                return hcat(predicted...)
            end
            predicted = accum_parts(model,input_data,num_parts,use_GPU)
        end
        accuracy_array[i] = accuracy(predicted,actual)
        loss_array[i] = loss(predicted,actual)
        predicted_array[i] = predicted
        put!(channels.analysis_progress,1)
        @everywhere GC.safepoint()
    end
    #=empty!(validation_plot_data.data_input_orig)
    empty!(validation_plot_data.data_labels_orig)
    empty!(validation_plot_data.data_input)
    empty!(validation_plot_data.data_labels)=#
    data_predicted,data_error,target = output_and_error_images(predicted_array,
        set[2],model_data,channels)
    data = (data_predicted,data_error,target,
        accuracy_array,loss_array,std(accuracy_array),std(loss_array))
    put!(channels.validation_results,data)
end
function analyse_main2(settings::Settings,training_data::Training_data,
        model_data::Model_data,channels::Channels)
    @everywhere settings,training_data,model_data
    remote_do(validate_main,workers()[end],settings,training_data,model_data,channels)
end
analyse() = remote_do(analyse_main2,workers()[end],settings,training_data,
model_data,channels)

function process_masks(predicted_array::Array{<:Array{<:AbstractFloat}},
        set::Array{<:Array{<:AbstractFloat,4},1},
        model_data::Model_data,channels::Channels)
    labels_color,labels_incl,border = get_feature_data(model_data.features)
    border_colors = labels_color[findall(border)]
    labels_color = vcat(labels_color,border_colors,border_colors)
    perm_labels_color = map(x -> permutedims(x[:,:,:]/255,[3,2,1]),labels_color)
    if any(border)
        border_array = map(x->apply_border_data_main(x,model_data),predicted_array)
        data_array = cat.(predicted_array,border_array,dims=3)
    else
        data_array = predicted_array
    end
    array_size = size(predicted_array[1])
    array_size12 = array_size[1:2]
    num_feat = array_size[3]
    num = length(predicted_array)
    num2 = length(labels_color)
    perm_labels_color = convert(Array{Array{Float32,3}},perm_labels_color)
    predicted_color = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    predicted_error = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    target_color = Vector{Vector{Array{RGB{Float32},2}}}(undef,num)
    Threads.@threads for i = 1:num
        set_part = set[i]
        data_array_part = data_array[i]
        function compute(num2::Int64,num_feat::Int64,set_part::Array{Float32,4},
                data_array_part::Array{Float32,4})
            target_temp = Vector{Array{RGB{Float32},2}}(undef,0)
            predicted_color_temp = Vector{Array{RGB{Float32},2}}(undef,0)
            predicted_error_temp = Vector{Array{RGB{Float32},2}}(undef,0)
            function do_target!(target_temp::Vector{Array{RGB{Float32},2}},
                    target::Array{Float32,2},color::Array{Float32,3})
                target_img = target.*color
                target_img2 = permutedims(target_img,[3,1,2])
                target_img3 = colorview(RGB,target_img2)
                target_img3 = collect(target_img3)
                push!(target_temp,target_img3)
            end
            function do_predicted_error!(predicted_error_temp::Vector{Array{RGB{Float32},2}},
                    truth::BitArray{2},predicted_bool::BitArray{2})
                correct = predicted_bool .& truth
                false_pos = copy(predicted_bool)
                false_pos[truth] .= false
                false_neg = copy(truth)
                false_neg[predicted_bool] .= false
                error_img = zeros(Bool,(size(predicted_bool)...,3))
                error_img[:,:,1:2] .= false_pos
                error_img[:,:,1] = error_img[:,:,1] .| false_neg
                error_img[:,:,2] = error_img[:,:,2] .| correct
                error_img = permutedims(error_img,[3,1,2])
                error_img2 = convert(Array{Float32,3},error_img)
                error_img3 = colorview(RGB,error_img2)
                error_img3 = collect(error_img3)
                push!(predicted_error_temp,error_img3)
                return
            end
            function do_predicted_color!(predicted_color_temp::Vector{Array{RGB{Float32},2}},
                    predicted_bool::BitArray{2},color::Array{Float32,3})
                temp = Float32.(predicted_bool)
                temp = cat(temp,temp,temp,dims=3)
                temp = temp.*color
                temp = permutedims(temp,[3,1,2])
                temp2 = convert(Array{Float32,3},temp)
                temp3 = colorview(RGB,temp2)
                temp3 = collect(temp3)
                push!(predicted_color_temp,temp3)
                return
            end
            for j = 1:num2
                if j>num_feat
                    target = set_part[:,:,j-num_feat]
                else
                    target = set_part[:,:,j]
                end
                color = perm_labels_color[j]
                do_target!(target_temp,target,color)
                truth = target.>0
                predicted_bool = data_array_part[:,:,j].>0.5
                do_predicted_error!(predicted_error_temp,truth,predicted_bool)
                do_predicted_color!(predicted_color_temp,predicted_bool,color)
                @everywhere GC.safepoint()
            end
            return target_temp,predicted_color_temp,predicted_error_temp
        end
        target_temp,predicted_color_temp,predicted_error_temp =
            compute(num2,num_feat,set_part,data_array_part)
        predicted_color[i] = predicted_color_temp
        predicted_error[i] = predicted_error_temp
        target_color[i] = target_temp
        put!(channels.validation_progress,1)
        @everywhere GC.safepoint()
    end
    return predicted_color,predicted_error,target_color
end
