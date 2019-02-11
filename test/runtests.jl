using Test
using WaveformAnalysis
using BenchmarkTools

a = Array([0:0.1:100;0:0.1:100;0:0.1:100])
b = float.([0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0,0,0,1,1])

println("Peak to peak: ", pkpk(a))

println("High pulse: ", pulse(b, ActiveHigh))
println("Low pulse: ", pulse(b, ActiveLow))

println("Period: ", period(b))

println("Duty cycle high: ", dutycycle(b, ActiveHigh))
println("Duty cycle low: ", dutycycle(b, ActiveLow))

@testset "pulses" begin
    @test pulses([0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0.0], ActiveHigh) == [2,2,2,2]
    @test pulses([0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1.0], ActiveHigh) == [2,2,2]
    @test pulses([1,1,0,0,1,1,0,0,1,1,0,0,1,1.0,0], ActiveHigh) == [2,2,2]
    @test pulses([1,1,0,0,1,1,0,0,1,1,0,0,1,1.0], ActiveHigh) == [2,2]
end

@testset "detectcrosses" begin
    @test isempty(detectcrosses(ones(10), 0.5, Rising))
    @test isempty(detectcrosses(zeros(10), 0.5, Rising))
    @test detectcrosses([0,0,1,1.0], 0.5, Rising) == [3,]
    @test detectcrosses([0,0,1,1.0,0,0,1,1.0], 0.5, Rising) == [3,7]
    @test detectcrosses(1 .- [0,0,1,1.0,0,0,1,1.0], 0.5, Rising) == [5,]
    bits = [true,false,false,true,true,false,true]
    @test detectcrosses(bits, Rising) == [4,7]
    @test detectcrosses(bits, Falling) == [2,6]
end

@testset "risetime" begin
    @test risetime([0,0,0,0]) == nothing
    @test risetime([0,0,1.0,1.0]) == 0
    @test risetime([0,0,0.5,1]) == 1
    @test risetime(Array(1:1.0:10)) == 8
    @test risetime([0.5,0.5,0.625,0.75,0.875,1]) == 3
end

@testset "falltime" begin
    @test falltime([0,0,0,0]) == nothing
    @test falltime([1.0,1.0,0,0]) == 0
    @test falltime([1,1,0.5,0]) == 1
    @test falltime(Array(10:-1.0:1)) == 8
    @test falltime([1.0,1.0,0.875,0.75,0.625,0.5,0.5]) == 3

end

@testset "RMS" begin
    @test RMS(zeros(10)) == 0
    @test RMS(ones(10)) == 1.0
    @test RMS([zeros(10);ones(10);zeros(10);ones(10)]) ≈ 1/sqrt(2)
    @test RMS([-ones(10);ones(10);-ones(10);ones(10)]) == 1
end

@testset "trigger" begin
    @test trigger([0,0,0,0.5,1.0,1.0,1.0], 0.25, 2, 2, Rising) == [0,0,0.5,1,1]
    @test trigger(ones(10), 0.25, 2, 2, Rising) == nothing
    @test trigger(zeros(10), 0.25, 2, 2, Rising) == nothing
    @test trigger([0,1.0], 0.5, 10, 10, Rising) == [0,1.0]

end
#=
randvec = rand(10000);

println("Benchmarking risetime...")
@btime risetime(randvec)
println("Benchmarking falltime...")
@btime falltime(randvec)
println("Benchmarking RMS...")
@btime RMS(randvec)
=#