function parse_block(n::Int, x::Function)
    x(n)
end

function parse_block(n::Int, x::MatrixBlock{N}) where N
    n == N || throw(ArgumentError("number of qubits does not match: $x"))
    x
end

# 2. composite blocks
# 2.1 chain block
export chain

"""
    chain([T], n::Int) -> ChainBlock
    chain([n], blocks) -> ChainBlock

Returns a `ChainBlock`. This factory method can be called lazily if you
missed the total number of qubits.

This chains several blocks with the same size together.
"""
function chain end
chain(::Type{T}, n::Int) where T = ChainBlock{n, T}([])
chain(n::Int) = chain(DefaultType, n)
chain() = n -> chain(n)

function chain(n::Int, blocks)
    if blocks isa Union{Function, MatrixBlock, Pair}
        ChainBlock([parse_block(n, blocks)])
    else
        ChainBlock(MatrixBlock{n}[parse_block(n, each) for each in blocks])
    end
end

chain(blocks) = n -> chain(n, blocks)

function chain(blocks::Vector{MatrixBlock{N}}) where N
    ChainBlock(Vector{MatrixBlock{N}}(blocks))
end

function chain(n, blocks...)
    ChainBlock(MatrixBlock{n}[parse_block(n, each) for each in blocks])
end

function chain(blocks::MatrixBlock{N}...) where N
    ChainBlock(collect(MatrixBlock{N}, blocks))
end

# 2.2 kron block
import Base: kron

"""
    kron(blocks...) -> KronBlock
    kron(iterator) -> KronBlock
    kron(total, blocks...) -> KronBlock
    kron(total, iterator) -> KronBlock

create a [`KronBlock`](@ref) with a list of blocks or tuple of heads and blocks.

## Example
```@example
kron(4, X, 3=>Z, Y)
```
This will automatically generate a block list looks like
```
1 -- [X] --
2 ---------
3 -- [Z] --
4 -- [Y] --
```
"""
kron(total::Int, blocks::Union{MatrixBlock, Tuple, Pair}...) = KronBlock{total}(blocks)
kron(total::Int, g::Base.Generator) = KronBlock{total}(g)
# NOTE: this is ambiguous
# kron(total::Int, blocks) = KronBlock{total}(blocks)
kron(blocks::Union{MatrixBlock, Tuple{Int, <:MatrixBlock}, Pair{Int, <:MatrixBlock}}...) = N->KronBlock{N}(blocks)
kron(blocks) = N->KronBlock{N}(blocks)

# 2.3 control block

export C, control

decode_sign(ctrls::Int...) = ctrls .|> abs, ctrls .|> sign .|> (x->(1+x)÷2)

"""
    control([total], controls, target) -> ControlBlock

Constructs a [`ControlBlock`](@ref)
"""
function control end

function control(total::Int, controls, target)
    ControlBlock{total}(decode_sign(controls...)..., target.second, target.first)
end

function control(controls, target)
    total->ControlBlock{total}(decode_sign(controls...)..., target.second, target.first)
end

function control(total::Int, controls)
    x::Pair->ControlBlock{total}(decode_sign(controls...)..., x.second, x.first)
end

function control(controls)
    function _control(x::Pair)
        total->ControlBlock{total}(decode_sign(controls...)..., x.second, x.first)
    end
end

function C(controls::Int...)
    function _C(x::Pair{I, BT}) where {I, BT <: MatrixBlock}
        total->ControlBlock{total}(decode_sign(controls...)..., x.second, x.first)
    end
end

# 2.4 roller

export roll

"""
    roll([n], blocks...)

Construct a [`Roller`](@ref) block, which is a faster way to calculate
similar small blocks tile on the whole address.
"""
function roll end

roll(n::Int, block::MatrixBlock) = Roller{n}(block)

function roll(N::Int, blocks::MatrixBlock...)
    T = promote_type([datatype(each) for each in blocks]...)
    @assert N >= sum(x->nqubits(x), blocks) "total number of qubits is not enough"
    Roller{N, T}(blocks)
end

roll(blocks::MatrixBlock...) = n->roll(n, blocks...)

# 2.5 repeat

import Base: repeat

"""
    repeat([n], pairs)
"""
repeat(n::Int, x::Pair{Int, <:MatrixBlock}) = RepeatedBlock{n}(x.second, [x.first])
repeat(n::Int, x::MatrixBlock, lines) = RepeatedBlock{n}(x, lines)
repeat(n::Int, x::MatrixBlock) = RepeatedBlock{n}(x)
repeat(x::MatrixBlock, params...) = n->repeat(n, x, params...)
repeat(x::Pair) = n->repeat(n, x)


export focus
export concentrate

"""
    concentrate(orders...) -> Concentrator

concentrate on serveral lines.
"""
concentrate(nbit::Int, block::AbstractBlock, orders::Vector{Int}) = Concentrator{nbit}(block, orders)
