export ConstantGate

"""
    ConstantGate{N, T} <: PrimitiveBlock{N, T}

Abstract type for constant gates.
"""
abstract type ConstantGate{N, T} <: PrimitiveBlock{N, T} end

"""
    @const_gate name[::T] = matrix

Define a new constant gate.
"""
:(@const_gate)

copy(x::ConstantGate) = x

@static if VERSION < v"0.7-"
    include("ConstGateTools.jl")
else
    include("ConstGateTools2.jl")
end

cache_key(x::ConstantGate) = 0x1
include("ConstGateGen.jl")
