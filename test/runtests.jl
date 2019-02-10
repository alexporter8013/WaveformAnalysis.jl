using Test
using WaveformAnalysis

a = Array([0:0.1:100;0:0.1:100;0:0.1:100])
b = float.([0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1])

println("rise time: ", risetime(a))
println("fall time: ", falltime(a))

println("RMS: ", RMS(a))
println("Peak to peak: ", pkpk(a))
println("Mean: ", mean(a))

println("High pulse: ", pulse(b, ActiveHigh))
println("Low pulse: ", pulse(b, ActiveLow))

println("Period: ", period(b))

println("Duty cycle high: ", dutycycle(b, ActiveHigh))
println("Duty cycle low: ", dutycycle(b, ActiveLow))

