export MatrixBlock

"""
    MatrixBlock{N, T} <: AbstractBlock

abstract type that all block with a matrix form will subtype from.
"""
abstract type MatrixBlock{N, T} <: AbstractBlock end

nqubits(::Type{MT}) where {N, MT <: MatrixBlock{N}} = N
nqubits(::MatrixBlock{N}) where N = N

# Traits
isunitary(x::MatrixBlock) = isunitary(mat(x))
isunitary(::Type{X}) where {X <: MatrixBlock} = isunitary(mat(X))

isreflexive(x::MatrixBlock) = isreflexive(mat(x))
isreflexive(::Type{X}) where {X <: MatrixBlock} = isreflexive(mat(X))

ishermitian(x::MatrixBlock) = ishermitian(mat(x))
ishermitian(::Type{X}) where {X <: MatrixBlock} = ishermitian(mat(X))

function apply!(reg::AbstractRegister, b::MatrixBlock)
    reg.state .= mat(b) * reg
    reg
end

# Parameters
nparameters(x::MatrixBlock) = length(parameters(x))
nparameters(::Type{X}) where {X <: MatrixBlock} = 0
parameters(x::MatrixBlock) = ()

"""
    datatype(x) -> DataType

Returns the data type of x.
"""
datatype(block::MatrixBlock{N, T}) where {N, T} = T

include("BlockCache.jl")
include("Primitive.jl")
include("Composite.jl")
