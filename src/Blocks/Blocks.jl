"""
# APIs

### Traits

`nqubits`
`ninput`
`noutput`
`isunitary`
`ispure`
`isreflexive`
`ishermitian`

### Methods

`apply!`
`copy`
`dispatch!`
"""
module Blocks

using Compat
using Compat.Random
using Compat.LinearAlgebra
using Compat.SparseArrays

using MacroTools
using ..Intrinsics
using ..Registers
using ..LuxurySparse
using ..CacheServers

# force import I matrix
import ..LuxurySparse: I

# import package APIs
import ..Yao
import ..Yao: DefaultType, nqubits, isunitary, isreflexive, nparameters, mat, datatype, dispatch!, address
import Compat.LinearAlgebra: ishermitian
import Base: hash, ==, eltype, show, similar, getindex, setindex!, start, next, done, length

# APIs for cache block's matrix
export update_cache, clear_cache, cache
import ..CacheServers: update!, iscached, clear!, pull

# module APIs
export address, @const_gate
export nqubits, ninput, noutput, isunitary, ispure, isreflexive, nparameters, mat, datatype, matrix_type, ishermitian
export apply!, dispatch!

export AnySize, GreaterThan

struct AnySize end
struct GreaterThan{N} end
ismatch(::GreaterThan{N}, n::Int) where N = n > N
ismatch(::AnySize, n::Int) = true

include("Core.jl")
# include("RangedBlock.jl")
include("MatrixBlock.jl")
# others
include("Concentrator.jl")
# include("Sequence.jl")
include("Measure.jl")
include("IOSyntax.jl")

end
