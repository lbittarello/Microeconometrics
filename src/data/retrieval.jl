#==========================================================================================#

# GET VARIABLE SETS

function getvector(MD::Microdata, x::Symbol)
    haskey(MD.map, x)       || throw(string(x) * " not found")
    iszero(MD.map[x])       && throw(string(x) * " not found")
    (length(MD.map[x]) > 1) && throw(string(x) * " is not a vector")
    return view(MD.mat.m, :, MD.map[x]...)
end

getvector(MM::ParModel, x::Symbol)      = getvector(MM.sample, x)
getvector(MM::TwoStageModel, x::Symbol) = getvector(second_stage(MM).sample, x)

function getmatrix(MD::Microdata, args...)

    n = length(args)

    for i in args
        haskey(MD.map, i) || throw(string(x) * " not found")
        iszero(MD.map[i]) && throw(string(i) * " not found")
    end

    x = Vector{Int64}()

    for i in args
        x = vcat(x, MD.map[i])
    end

    return view(MD.mat.m, :, x)
end

getmatrix(MM::ParModel, args...)        = getmatrix(MM.sample, args...)
getmatrix(MM::TwoStageModel, x::Symbol) = getmatrix(second_stage(MM).sample, x)

#==========================================================================================#

# GET VARIABLE NAMES

function getnames(MD::Microdata, args...)

    n = length(args)

    for i in args
        haskey(MD.map, i) || throw(string(x) * " not found")
        iszero(MD.map[i]) && throw(string(i) * " not found")
    end

    x = Vector{Int64}()

    for i in args
        x = vcat(x, MD.map[i])
    end

    return MD.names[x]
end

getnames(MM::ParModel, args...)      = getnames(MM.sample, args...)
getnames(MM::TwoStageModel, args...) = getnames(second_stage(MM).sample, args...)

#==========================================================================================#

# GET CORRELATION STRUCTURE

getcorr(obj::Microdata)     = obj.corr
getcorr(obj::ParModel)      = obj.sample.corr
getcorr(obj::TwoStageModel) = second_stage(obj).sample.corr

#==========================================================================================#

# GET INDICATOR OF MISSING DATA

getmsng(obj::Microdata)     = obj.msng
getmsng(obj::ParModel)      = obj.sample.msng
getmsng(obj::TwoStageModel) = second_stage(obj).sample.msng

#==========================================================================================#

# CHECK WEIGHT

checkweight(MD::Microdata)     = (haskey(MD.map, :weight) && !iszero(MD.map[:weight]))
checkweight(MM::Micromodel)    = checkweight(MM.sample)
checkweight(MM::TwoStageModel) = checkweight(second_stage(MM))