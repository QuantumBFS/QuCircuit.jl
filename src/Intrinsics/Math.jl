"""
    bit_length(x::Int) -> Int

Return the number of bits required to represent input integer x.
"""
bit_length(x::Int64)  =  64 - leading_zeros(x)
bit_length(x::Int32)  =  32 - leading_zeros(x)

"""
    log2i(x::Integer) -> Integer

Return log2(x), this integer version of `log2` is fast but only valid for number equal to 2^n.
Ref: https://stackoverflow.com/questions/21442088
"""
function log2i end

# function log2i(x::T)::T where T
#     local n::T = 0
#     while x&0x1!=1
#         n += 1
#         x >>= 1
#     end
#     return n
# end

for N in [8, 16, 32, 64, 128]
    T = Symbol(:Int, N)
    UT = Symbol(:UInt, N)
    @eval begin
        log2i(x::$T) = !signbit(x) ? ($(N - 1) - leading_zeros(x)) : throw(ErrorException("nonnegative expected ($x)"))
        log2i(x::$UT) = $(N - 1) - leading_zeros(x)
    end
end

"""
    batch_normalize!(matrix)

normalize a batch of vector.
"""
function batch_normalize!(s::AbstractMatrix, p::Real=2)
    B = size(s, 2)
    for i = 1:B
        normalize!(view(s, :, i), p)
    end
    s
end

"""
    batch_normalize

normalize a batch of vector.
"""
function batch_normalize(s::AbstractMatrix, p::Real=2)
    ts = copy(s)
    batch_normalize!(ts, p)
end

# N: number of qubits
# st: state vector with batch
function rolldims2!(::Val{N}, ::Val{B}, st::AbstractMatrix) where {N, B}
    n = 1 << N
    halfn = 1 << (N - 1)
    temp = st[2:2:n, :]
    st[1:halfn, :] = st[1:2:n, :]
    st[halfn+1:end, :] = temp
    st
end

function rolldims2!(::Val{N}, ::Val{1}, st::AbstractVector) where {N}
    n = 1 << N
    halfn = 1 << (N - 1)
    temp = st[2:2:n]
    st[1:halfn] = st[1:2:n]
    st[halfn+1:end] = temp
    st
end

@generated function rolldims!(::Val{K}, ::Val{N}, ::Val{B}, st::AbstractVecOrMat) where {K, N, B}
    ex = :(rolldims2!(Val($N), Val($B), st))
    for i = 2:K
        ex = :(rolldims2!(Val($N), Val($B), st); $ex)
    end
    ex
end

nqubits(m::AbstractArray) = size(m, 1) |> log2i

"""
    hilbertkron(num_bit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix

Return general kronecher product form of gates in Hilbert space of `num_bit` qubits.

* `gates` are a list of matrices.
* `start_locs` should have the same length as `gates`, specifing the gates starting positions.
"""
function hilbertkron(num_bit::Int, ops::Vector{T}, start_locs::Vector{Int}) where T<:AbstractMatrix
    sizes = [op |> nqubits for op in ops]
    start_locs = num_bit .- start_locs .- sizes .+ 2

    order = sortperm(start_locs)
    sorted_ops = ops[order]
    sorted_start_locs = start_locs[order]
    num_ids = vcat(sorted_start_locs[1]-1, diff(push!(sorted_start_locs, num_bit+1)) .- sizes[order])

    _wrap_identity(sorted_ops, num_ids)
end

# kron, and wrap matrices with identities.
function _wrap_identity(data_list::Vector{T}, num_bit_list::Vector{Int}) where T<:AbstractMatrix
    length(num_bit_list) == length(data_list) + 1 || throw(ArgumentError())

    ⊗ = kron
    reduce(zip(data_list, num_bit_list[2:end]); init=IMatrix(1 << num_bit_list[1])) do x, y
        x ⊗ y[1] ⊗ IMatrix(1<<y[2])
    end
end

"""
    general_controlled_gates(num_bit::Int, projectors::Vector{Tp}, cbits::Vector{Int}, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix

Return general multi-controlled gates in hilbert space of `num_bit` qubits,

* `projectors` are often chosen as `P0` and `P1` for inverse-Control and Control at specific position.
* `cbits` should have the same length as `projectors`, specifing the controling positions.
* `gates` are a list of controlled single qubit gates.
* `locs` should have the same length as `gates`, specifing the gates positions.
"""
function general_controlled_gates(
    n::Int,
    projectors::Vector{<:AbstractMatrix},
    cbits::Vector{Int},
    gates::Vector{<:AbstractMatrix},
    locs::Vector{Int}
)
    IMatrix(1<<n) - hilbertkron(n, projectors, cbits) +
        hilbertkron(n, vcat(projectors, gates), vcat(cbits, locs))
end

"""
    general_c1_gates(num_bit::Int, projector::AbstractMatrix, cbit::Int, gates::Vector{AbstractMatrix}, locs::Vector{Int}) -> AbstractMatrix

general (low performance) construction method for control gate on different lines.
"""
general_c1_gates(num_bit::Int, projector::Tp, cbit::Int, gates::Vector{Tg}, locs::Vector{Int}) where {Tg<:AbstractMatrix, Tp<:AbstractMatrix} =
hilbertkron(num_bit, [IMatrix(2) - projector], [cbit]) + hilbertkron(num_bit, vcat([projector], gates), vcat([cbit], locs))

rotate_matrix(gate::AbstractMatrix, θ::Real) = exp(-0.5im * θ * Matrix(gate))

"""
    linop2dense(applyfunc!::Function, num_bit::Int) -> Matrix

get the dense matrix representation given matrix*matrix function.
"""
linop2dense(applyfunc!::Function, num_bit::Int) = applyfunc!(Matrix{ComplexF64}(I, 1<<num_bit, 1<<num_bit))

"""
    hypercubic(A::Union{Array, DefaultRegister}) -> Array

get the hypercubic representation for an array or a regiseter.
"""
hypercubic(A::Array) = reshape(A, fill(2, size(A) |> prod |> log2i)...)

#################### Reorder ######################
function invorder(A::Matrix)
    M, N = size(A)
    m, n = M |> log2i, N |> log2i
    A = A |> hypercubic
    reshape(permutedims(A, [m:-1:1..., n+m:-1:m+1...]), M, N)
end

reorder(A::IMatrix, orders) = A
function reorder(A::PermMatrix, orders::Vector{Int})
    M = size(A, 1)
    nbit = M|>log2i
    od::Vector{Int} = [b+1 for b::Int in reordered_basis(nbit, orders)]
    perm = similar(A.perm)
    vals = similar(A.vals)
    @simd for i = 1:length(perm)
        @inbounds perm[od[i]] = od[A.perm[i]]
        @inbounds vals[od[i]] = A.vals[i]
    end
    PermMatrix(perm, vals)
end

function reorder(A::Diagonal, orders::Vector{Int})
    M = size(A, 1)
    nbit = M|>log2i
    #od::Vector{Int} = [b+1 for b::Int in reordered_basis(nbit, orders)]
    diag = similar(A.diag)
    #for i = 1:length(perm)
    #    diag[od[i]] = A.diag[i]
    #end
    i = 1
    for b::Int in reordered_basis(nbit, orders)
        diag[b+1] = A.diag[i]
        i += 1
    end
    Diagonal(diag)
end

rotmat(m::AbstractMatrix, θ::Real) = exp(-im*θ/2*Matrix(m))

################### Fidelity ###################
"""fidelity for pure states."""
fidelity_pure(v1::Vector, v2::Vector) = abs(v1'*v2)

"""
    fidelity_mix(m1::Matrix, m2::Matrix)

Fidelity for mixed states.

Reference:
    http://iopscience.iop.org/article/10.1088/1367-2630/aa6a4b/meta
"""
function fidelity_mix(m1::Matrix, m2::Matrix)
    O = m1'*m2
    trace(sqrtm(O*O'))
end

"""
    rand_unitary(N::Int) -> Matrix

Random unitary matrix.
"""
function rand_unitary(N::Int)
    qr(randn(ComplexF64, N, N)).Q |> Matrix
end

"""
    rand_hermitian(N::Int) -> Matrix

Random hermitian matrix.
"""
function rand_hermitian(N::Int)
    A = randn(ComplexF64, N, N)
    A + A'
end
