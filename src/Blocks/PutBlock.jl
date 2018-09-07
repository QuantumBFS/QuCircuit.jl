export PutBlock

"""
    PutBlock{N, C, GT, T} <: CompositeBlock{N, T}

put a block on given addrs.
"""
mutable struct PutBlock{N, C, GT<:MatrixBlock, T} <: CompositeBlock{N, T}
    block::GT
    addrs::NTuple{C, Int}

    function PutBlock{N, C, GT, T}(block::GT, addrs::NTuple{C, Int}) where {N, C, T, GT<:MatrixBlock{C, T}}
        _assert_addr_safe(N, [i:i for i in addrs])
        length(addrs) == C || throw(ArgumentError("Repeat number mismatch!"))
        new{N, C, GT, T}(block, addrs)
    end
end

function PutBlock{N}(block::GT, addrs::NTuple) where {N, C, T, GT <: MatrixBlock{C, T}}
    PutBlock{N, C, GT, T}(block, addrs)
end

blocks(pb::PutBlock) = [pb.block]
addrs(pb::PutBlock) = pb.addrs
usedbits(pb::PutBlock) = [pb.addrs...]
copy(x::PutBlock) = typeof(x)(x.block, x.addrs)
adjoint(blk::PutBlock{N}) where N = PutBlock{N}(adjoint(blk.block), blk.addrs)

dispatch!(pb::PutBlock, params...) = dispatch!(pb.block, params...)
dispatch!(f::Function, pb::PutBlock, params...) = dispatch!(f, pb.block, params...)

# TODO
mat(pb::PutBlock{N, 1}) where N = u1mat(N, mat(pb.block), pb.addrs...)
mat(pb::PutBlock{N, C}) where {N, C} = unmat(N, mat(pb.block), pb.addrs)
#mat(pb::PutBlock{N, 1}) where N = hilbertkron(N, [mat(pb.block)], [pb.addrs...])
function apply!(r::AbstractRegister, pb::PutBlock{N}) where N
    N == nactive(r) || throw(QubitMismatchError("register Size $(nactive(r)) mismatch with block size $N"))
    unapply!(r.state |> matvec, mat(pb.block), pb.addrs)
    r
end

function hash(pb::PutBlock, h::UInt)
    hashkey = hash(objectid(pb), h)
    hashkey = hash(pb.block, hashkey)
    hashkey = hash(pb.addrs, hashkey)
    hashkey
end

function ==(lhs::PutBlock{N, C, GT, T}, rhs::PutBlock{N, C, GT, T}) where {N, T, C, GT}
    (lhs.block == rhs.block) && (lhs.addrs == rhs.addrs)
end

cache_key(pb::PutBlock) = cache_key(pb.block)

function print_block(io::IO, pb::PutBlock{N}) where N
    printstyled(io, "put on ("; bold=true, color=color(PutBlock))
    for i in eachindex(pb.addrs)
        printstyled(io, pb.addrs[i]; bold=true, color=color(PutBlock))
        if i != lastindex(pb.addrs)
            printstyled(io, ", "; bold=true, color=color(PutBlock))
        end
    end
    printstyled(io, ")"; bold=true, color=color(PutBlock))
end
