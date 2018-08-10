export ConstantGate

"""
    ConstantGate{N, T} <: PrimitiveBlock{N, T}

Abstract type for constant gates.
"""
abstract type ConstantGate{N, T} <: PrimitiveBlock{N, T} end

include("ConstGateTools.jl")
cache_key(x::ConstantGate) = 0x1

include("ConstGateGen.jl")
