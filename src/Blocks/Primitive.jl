"""
    PrimitiveBlock{N, T} <: MatrixBlock{N, T}

abstract type that all primitive block will subtype from. A primitive block
is a concrete block who can not be decomposed into other blocks. All composite
block can be decomposed into several primitive blocks.

NOTE: subtype for primitive block with parameter should implement `hash` and `==`
method to enable key value cache.
"""
abstract type PrimitiveBlock{N, T} <: MatrixBlock{N, T} end

isunitary(::Type{T}) where {T <: PrimitiveBlock} = true

include("ConstantGate.jl")
include("PhaseGate.jl")
include("RotationGate.jl")

# TODO:
# 1. new Primitive: SWAP gate
include("SwapGate.jl")
