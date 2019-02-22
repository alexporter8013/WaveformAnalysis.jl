module WaveformAnalysis

mid(x::Vector{T}) where T <: Real = sum(extrema(x))/2

export RMS, pkpk, ActiveHigh, ActiveLow, Rising, Falling

RMS(x::Vector{T}) where T <: Real = sqrt.(sum(x.^2)./length(x))
pkpk(x::Vector{T}) where {T <: Real} = diff(extrema(x))

@enum Edge Rising Falling
@enum Polarity ActiveHigh ActiveLow

export detectcross, detectcrosses

function detectcrosses(x::Vector{T}, thresh::T, edge::Edge) where {T <: Real}
    events = (edge == Rising ? x .>= thresh : x .<= thresh)
    findall(events .& (.~events >> 1))
end

detectcrosses(x::Vector{T}, edge::Edge) where {T <: Real} = detectcrosses(x, mid(x), edge)

detectcrosses(x::Vector{Bool}, edge::Edge) = detectcrosses(BitVector(x), edge)
detectcrosses(x::BitVector, edge::Edge) = edge == Rising ? findall(x .& (.~x >> 1)) : findall(x >> 1 .& (.~x))

function detectcross(x::Vector{T}, thresh::T, edge::Edge) where {T <: Real}
    results = detectcrosses(x,thresh,edge)
    (isempty(results) ? nothing : results[1])
end

function detectcross(x::BitVector, edge::Edge)
    results = detectcrosses(x, edge)
    (isempty(result) ? nothing : results[1])
end

detectcross(x::Vector{Bool}, edge::Edge) = detectcross(x, edge)

function edgetime(x::Vector{T}, edge::Edge) where {T <: Real}
    _min, _max = extrema(x)
    top = (_max - _min)*9/10 + _min
    bottom = (_max - _min)/10 + _min
    try
        detectcross(x, top, edge) - detectcross(x, bottom, edge)
    catch MethodError
        nothing
    end
end

pulse(x, pol::Polarity) = pulses(x,pol)[1]
pulse(x::Vector{T}, thresh::T, pol::Polarity) where {T <: Real} = pulses(x,thresh,pol)[1]
export pulse

pulses(x::Vector{T}, pol::Polarity) where T <: Real = pulses(x, mid(x), pol)
pulses(x::Vector{T}, thresh::T, pol::Polarity) where T <: Real = 
    measurepulses(detectcrosses(x, thresh, Rising), detectcrosses(x, thresh, Falling), pol)
pulses(x::Vector{Bool}, pol::Polarity) = pulses(x, pol)
pulses(x::BitVector, pol::Polarity) = 
    measurepulses(detectcrosses(x, Rising), detectcrosses(x, Falling), pol)
export pulses

function measurepulses(poscrosses::Vector{T}, negcrosses::Vector{T}, pol::Polarity) where T <: Int64
    if !isempty(poscrosses) && !isempty(negcrosses)
        if pol == ActiveHigh
            alignedges!(poscrosses, negcrosses)
            negcrosses .- poscrosses
        else
            alignedges!(negcrosses, poscrosses)
            poscrosses .- negcrosses
        end
    else
        nothing
    end
end

#Aligns two edge arrays such that all x comes before all y. This assumes 
#each array is regular since they are detected edges. Operates on the
#vector of indices returned by detectcrosses
function alignedges!(x::Vector{T}, y::Vector{T}) where T <: Int64
    if length(x) == length(y)
        if x[1] < y[1]
            return
        else
            popfirst!(y)
            pop!(x)
        end
    else
        if length(x) > length(y)
            if x[1] < y[1]
                pop!(x)
            else
                popfirst!(x)
            end
        else
            if x[1] < y[1]
                pop!(y)
            else
                popfirst!(y)
            end
        end
    end
end

periods(x::Vector{T}) where T <: Real = periods(x, sum(extrema(x))/2)
periods(x::Vector{T}, thresh::T) where T <: Real = diff(detectcrosses(x, thresh, Rising))
periods(x::Vector{Bool}) = periods(x)
periods(x::BitVector) = diff(detectcrosses(x,Rising))
export periods

period(x) = periods(x)[1]
export period, periods

export dutycycle, risetime, falltime

dutycycle(x::Vector{T}, pol::Polarity) where {T <: Real} = pulse(x, pol) / period(x)
dutycycle(x::Vector{T}, thresh::T, pol::Polarity) where {T <: Real} = pulse(x, thresh, pol) / period(x, thresh)

# Need to finish these later
#dutycycles(x::Vector{T}, pol::Polarity) where T <: Real = pulses(x, pol) ./ periods(x)
#dutycycles(x::Vector{T}, pol::Polarity) where T <: Real = pulses(x, pol) ./ periods(x)
#dutycycles(x::Vector{T}, pol::Polarity) where T <: Real = dutycycles()
#dutycycles(x::Vector{T}, thresh::T, pol::Polarity) where T <: Real = pulses(x, thresh, pol) ./ periods(x, thresh)

risetime(x::Vector{T} where T <: Real) = edgetime(x, Rising::Edge)
falltime(x::Vector{T} where T <: Real) = try -edgetime(x, Falling::Edge); catch MethodError nothing; end

export trigger

function trigger(x::Vector{T}, thresh::T, pre::Integer, post::Integer, edge::Edge) where T <: Real
    trig_point = detectcross(x, thresh, edge)
    if trig_point != nothing
        x[max(1,trig_point - pre) : min(length(x), trig_point + post)]
    else
        nothing
    end
end


end
