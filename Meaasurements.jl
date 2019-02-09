RMS(x::AbstractArray{T, 1}) where {T <: Real} = RMS(x, 1)[1]
RMS(x::AbstractArray{T, N}, dim) where {T <: Real, N} = sqrt.(sum(x.^2, dims=dim)./size(x, dim))
Mean(x::AbstractArray{T, 1}) where T <: Real = Mean(x, 1)[1]
Mean(x::AbstractArray{T, N}, dim) where {T <: Real, N} = sum(x, dims=dim)./size(x, dim)
PkPk(x::AbstractArray{T, 1}) where {T <: Real} = maximum(x) - minimum(x)


@enum Edge Rising Falling
@enum Polarity ActiveHigh ActiveLow

function DetectCross(x::AbstractArray{T,1}, thresh::T, edge::Edge) where {T <: Real}
    start = findfirst(edge == Rising::Edge ? x .< thresh : x .> thresh);
    index = findfirst(edge == Rising::Edge ? x[start:end] .>= thresh : x[start:end] .<= thresh);
    try
        index + start - 1
    catch MethodError #comes up if we get a "nothing" from findfirst and try to mix it with an int
        nothing
    end
end



function EdgeTime(x::AbstractArray{T, 1}, edge::Edge) where {T <: Real}
    _min = minimum(x)
    _max = maximum(x)
    top = (_max - _min)*9/10 + _min
    bottom = (_max - _min)/10 + _min
    DetectCross(x, top, edge) - DetectCross(x, bottom, edge)
end

function Pulse(x::AbstractArray{T, 1}, pol::Polarity) where {T <: Real}
    _min = minimum(x)
    _max = maximum(x)
    mid = 0.5(_max + _min)
    firstedge = (pol == ActiveHigh ? DetectCross(x, mid, Rising::Edge)
                                    : DetectCross(x, mid, Falling::Edge))
    pulse_width = (pol == ActiveHigh ? DetectCross(x[firstedge + 1:end], mid, Falling::Edge)
                                    : DetectCross(x[firstedge + 1:end], mid, Rising::Edge))
    pulse_width
end



function Period(x::AbstractArray{T, 1}) where {T <: Real}
    _min = minimum(x)
    _max = maximum(x)
    mid = 0.5(_max + _min)
    firstedge = DetectCross(x, mid, Rising::Edge)
    period = DetectCross(x[firstedge + 1:end], mid, Rising::Edge)
    period
end

DutyCycle(x::AbstractArray{T, 1}, pol::Polarity) where {T <: Real} = Pulse(x, pol) / Period(x)

RiseTime(x::AbstractArray{T,1} where T <: Real) = EdgeTime(x, Rising::Edge)
FallTime(x::AbstractArray{T,1} where T <: Real) = -EdgeTime(x, Falling::Edge)



a = Array([0:0.1:100;0:0.1:100;0:0.1:100])
b = float.([0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,1,1])

println("rise time: ", RiseTime(a))
println("fall time: ", FallTime(a))

println("RMS: ", RMS(a))
println("Peak to peak: ", PkPk(a))
println("Mean: ", Mean(a))

println("High pulse: ", Pulse(a, ActiveHigh::Polarity))
println("Low pulse: ", Pulse(a, ActiveLow::Polarity))

println("Period: ", Period(a))

println("Duty cycle high: ", DutyCycle(a, ActiveHigh::Polarity))
println("Duty cycle low: ", DutyCycle(a, ActiveLow::Polarity))