#==========================================================================================#

# TYPE

mutable struct IVPoisson <: GMM

    method::String
    sample::Microdata
    β::Vector{Float64}
    V::Matrix{Float64}
    W::Matrix{Float64}

    IVPoisson() = new()
end

#==========================================================================================#

# CONSTRUCTOR

function IVPoisson(MD::Microdata, W::Matrix{Float64}, method::String)
    obj        = IVPoisson()
    obj.sample = MD
    obj.W      = W
    obj.method = method
    return obj
end

#==========================================================================================#

# INTERFACE

function fit(
        ::Type{IVPoisson},
        MD::Microdata;
        novar::Bool = false,
        method::String = "One-step GMM"
    )

    if method == "Poisson"

        FSM               = Dict(:treatment => "", :instrument => "")
        FSD               = Microdata(MD, FSM)
        FSD.map[:control] = vcat(MD.map[:treatment], MD.map[:control])
        obj               = Poisson(FSD)

        _fit!(obj, getweights(obj))

    elseif method == "Reduced form"

        FSM                = Dict(:treatment => "", :instrument => "")
        FSD                = Microdata(MD, FSM)
        FSD.map[:response] = MD.map[:treatment]
        FSD.map[:control]  = vcat(MD.map[:instrument], MD.map[:control])
        obj                = Poisson(FSD)

        _fit!(obj, getweights(obj))

    else

        if length(MD.map[:treatment]) == length(MD.map[:instrument])
            W   = eye(length(MD.map[:instrument]) + length(MD.map[:control]))
            obj = IVPoisson(MD, W, "Method of moments")
        elseif method == "One-step GMM"
            W   = eye(length(MD.map[:instrument]) + length(MD.map[:control]))
            obj = IVPoisson(MD, W, "One-step GMM")
        elseif (method == "TSLS") | (method == "2SLS")
            W   = crossprod(getmatrix(MD, :instrument, :control), getweights(MD))
            obj = IVPoisson(MD, W, "Two-step GMM")
        elseif (method == "Two-step GMM") | (method == "Optimal GMM")
            W     = crossprod(getmatrix(MD, :instrument, :control), getweights(MD))
            obj   = IVPoisson(MD, W, method) ; _fit!(obj, getweights(obj))
            obj.W = wmatrix(obj, getcorr(obj), getweights(obj))
        else
            throw("unknown method")
        end

        _fit!(obj, getweights(obj))
    end

    novar || _vcov!(obj, getcorr(obj), getweights(obj))

    return obj
end

#==========================================================================================#

# ESTIMATION

function _fit!(obj::IVPoisson, w::UnitWeights)

    O  = haskey(obj.sample.map, :offset)
    y  = getvector(obj, :response)
    x  = getmatrix(obj, :treatment, :control)
    z  = getmatrix(obj, :instrument, :control)
    W  = obj.W * nobs(obj)^2
    μ  = Array{Float64}(undef, length(y))
    xx = Array{Float64}(undef, size(x)...)

    if isdefined(obj, :β)
        β₀ = obj.β
    else
        β₀ = vcat(fill(0.0, size(x, 2) - 1), log(mean(y)))
    end

    O && (xo = getmatrix(obj, :offset, :treatment, :control))

    function L(β::Vector)

        O ? mul!(μ, xo, vcat(1.0, β)) : mul!(μ, x, β)

        μ .= y .- exp.(μ)
        m  = z' * μ
        mw = W \ m

        return 0.5 * dot(m, mw)
    end

    function G!(g::Vector, β::Vector)

        O ? mul!(μ, xo, vcat(1.0, β)) : mul!(μ, x, β)

        μ  .= exp.(μ)
        xx .= x .* μ
        d   = - xx' * z
        μ  .= y .- μ
        mw  = W \ (z' * μ)

        mul!(g, d, mw)
    end

    function LG!(g::Vector, β::Vector)

        O ? mul!(μ, xo, vcat(1.0, β)) : mul!(μ, x, β)

        μ  .= exp.(μ)
        xx .= x .* μ
        d   = - xx' * z
        μ  .= y .- μ
        m   = z' * μ
        mw  = W \ m

        mul!(g, d, mw)

        return 0.5 * dot(m, mw)
    end

    function H!(h::Matrix, β::Vector)

        O ? mul!(μ, xo, vcat(1.0, β)) : mul!(μ, x, β)

        μ  .= exp.(μ)
        xx .= x .* μ
        d   = z' * xx
        dw  = W \ d

        mul!(h, transpose(d), dw)
    end

    res = optimize(TwiceDifferentiable(L, G!, LG!, H!, β₀), β₀, Newton())

    if Optim.converged(res)
        obj.β = Optim.minimizer(res)
    else
        throw("minimization did not converge")
    end
end

function _fit!(obj::IVPoisson, w::AbstractWeights)

    O  = haskey(obj.sample.map, :offset)
    y  = getvector(obj, :response)
    x  = getmatrix(obj, :treatment, :control)
    z  = getmatrix(obj, :instrument, :control)
    W  = obj.W * nobs(obj)^2
    μ  = Array{Float64}(undef, length(y))
    xx = Array{Float64}(undef, size(x)...)

    if isdefined(obj, :β)
        β₀ = obj.β
    else
        β₀ = vcat(fill(0.0, size(x, 2) - 1), log(mean(y)))
    end

    O && (xo = getmatrix(obj, :offset, :treatment, :control))

    function L(β::Vector)

        O ? mul!(μ, xo, vcat(1.0, β)) : mul!(μ, x, β)

        μ .= w .* (y .- exp.(μ))
        m  = z' * μ
        mw = W \ m

        return 0.5 * dot(m, mw)
    end

    function G!(g::Vector, β::Vector)

        O ? mul!(μ, xo, vcat(1.0, β)) : mul!(μ, x, β)

        μ  .= exp.(μ)
        xx .= x .* μ .* w
        d   = - xx' * z
        μ  .= w .* (y .- μ)
        mw  = W \ (z' * μ)

        mul!(g, d, mw)
    end

    function LG!(g::Vector, β::Vector)

        O ? mul!(μ, xo, vcat(1.0, β)) : mul!(μ, x, β)

        μ  .= exp.(μ)
        xx .= x .* μ .* w
        d   = - xx' * z
        μ  .= w .* (y .- μ)
        m   = z' * μ
        mw  = W \ m

        mul!(g, d, mw)

        return 0.5 * dot(m, mw)
    end

    function H!(h::Matrix, β::Vector)

        O ? mul!(μ, xo, vcat(1.0, β)) : mul!(μ, x, β)

        μ  .= w .* exp.(μ)
        xx .= x .* μ
        d   = z' * xx
        dw  = W \ d

        mul!(h, transpose(d), dw)
    end

    res = optimize(TwiceDifferentiable(L, G!, LG!, H!, β₀), β₀, Newton())

    if Optim.converged(res)
        obj.β = Optim.minimizer(res)
    else
        throw("minimization did not converge")
    end
end

#==========================================================================================#

# SCORE (MOMENT CONDITIONS)

score(obj::IVPoisson) = Diagonal(residuals(obj)) * getmatrix(obj, :instrument, :control)

# EXPECTED JACOBIAN OF SCORE × NUMBER OF OBSERVATIONS

function jacobian(obj::IVPoisson, w::UnitWeights)

    if haskey(obj.sample.map, :offset)
        x = getmatrix(obj, :offset, :treatment, :control)
        v = xo * vcat(1.0, obj.β)
    else
        x = getmatrix(obj, :treatment, :control)
        v = x * obj.β
    end

    z  = getmatrix(obj, :instrument, :control)
    v .= exp.(v)

    return - z' * (x .* v)
end

function jacobian(obj::IVPoisson, w::AbstractWeights)

    if haskey(obj.sample.map, :offset)
        x = getmatrix(obj, :offset, :treatment, :control)
        v = xo * vcat(1.0, obj.β)
    else
        x = getmatrix(obj, :treatment, :control)
        v = x * obj.β
    end

    z  = getmatrix(obj, :instrument, :control)
    v .= w .* exp.(v)

    return - z' * (x .* v)
end

#==========================================================================================#

# LINEAR PREDICTOR

function predict(obj::IVPoisson, MD::Microdata)
    if getnames(obj, :control) != getnames(MD, :control)
        throw("some variables are missing")
    end
    if haskey(MD.map, :offset)
        return getmatrix(MD, :offset, :treatment, :control) * vcat(1.0, obj.β)
    else
        return getmatrix(MD, :treatment, :control) * obj.β
    end
end

# FITTED VALUES

fitted(obj::IVPoisson, MD::Microdata) = exp.(predict(obj, MD))

# DERIVATIVE OF FITTED VALUES

function jacobexp(obj::IVPoisson)

    if haskey(obj.sample.map, :offset)
        v = getmatrix(obj, :offset, :treatment, :control) * vcat(1.0, obj.β)
    else
        v = getmatrix(obj, :treatment, :control) * obj.β
    end

    v .= exp.(v)

    return Diag(v) * getmatrix(obj, :treatment, :control)
end

#==========================================================================================#

# UTILITIES

coefnames(obj::IVPoisson) = getnames(obj, :treatment, :control)