module WaveformAnalysis

import DataStructures.CircularBuffer

export RMS, mean, pkpk, ActiveHigh, ActiveLow, Rising, Falling

RMS(x::Vector{T}) where T <: Real = sqrt.(sum(x.^2)./size(x))
mean(x::Vector{T}) where T <: Real = sum(x)./length(x)
pkpk(x::Vector{T}) where {T <: Real} = maximum(x) - minimum(x)


@enum Edge Rising Falling
@enum Polarity ActiveHigh ActiveLow

export detectcross, detectcrosses

function detectcross(x::Vector{T}, thresh::T, edge::Edge) where {T <: Real}
    start = findfirst(edge == Rising::Edge ? x .< thresh : x .> thresh);
    if start != nothing
        index = findfirst(edge == Rising::Edge ? x[start:end] .>= thresh : x[start:end] .<= thresh);
    end
    try
        index + start - 1
    catch MethodError #comes up if we get a "nothing" from findfirst and try to mix it with an int
        nothing
    end
end

function detectcrosses(x::Vector{T}, thresh::T, edge::Edge) where {T <: Real}
    crosses = Vector{Int64}()
    keepgoing = true
    _index = 0
    while keepgoing
        cross = detectcross(x[_index:end], thresh, edge)
        if cross != nothing
            _index = cross + sum(crosses)
            push!(crosses, _index)
        else
            keepgoing = false
        end
    end
    crosses
end





export edgetime, pulse, period

function edgetime(x::Vector{T}, edge::Edge) where {T <: Real}
    _min = minimum(x)
    _max = maximum(x)
    top = (_max - _min)*9/10 + _min
    bottom = (_max - _min)/10 + _min
    try
        detectcross(x, top, edge) - detectcross(x, bottom, edge)
    catch MethodError
        nothing
    end
end

function pulse(x::Vector{T}, pol::Polarity) where {T <: Real}
    _min = minimum(x)
    _max = maximum(x)
    mid = 0.5(_max + _min)
    firstedge = (pol == ActiveHigh ? detectcross(x, mid, Rising::Edge)
                                    : detectcross(x, mid, Falling::Edge))
    pulse_width = (pol == ActiveHigh ? detectcross(x[firstedge + 1:end], mid, Falling::Edge)
                                    : detectcross(x[firstedge + 1:end], mid, Rising::Edge))
    pulse_width
end



function period(x::Vector{T}) where {T <: Real}
    _min = minimum(x)
    _max = maximum(x)
    mid = 0.5(_max + _min)
    firstedge = detectcross(x, mid, Rising::Edge)
    period = detectcross(x[firstedge + 1:end], mid, Rising::Edge)
    period
end


export FIR, movingaverage

function FIR(x::Vector{T}, filtercoeffs::Vector{T}) where T <: Real
    filterin = CircularBuffer{T}(length(filtercoeffs))
    out = similar(x)
    for i in eachindex(x)
        push!(filterin, x[i])
        #println("filtercoeffs: ",filtercoeffs[1:length(filterin)])
        out[i] = sum(filtercoeffs[1:length(filterin)] .* filterin)
        #println("filterin: ", filterin)
        #println("i: ", i, " length: ", length(filterin), " out[i]: ", out[i])
    end
    out
end

movingaverage(x::Vector{T}, n::Integer) where T <: Real = FIR(x, ones(n)./n)

export dutycycle, risetime, falltime

dutycycle(x::Vector{T}, pol::Polarity) where {T <: Real} = pulse(x, pol) / period(x)

risetime(x::Vector{T} where T <: Real) = edgetime(x, Rising::Edge)
falltime(x::Vector{T} where T <: Real) = -edgetime(x, Falling::Edge)




end
