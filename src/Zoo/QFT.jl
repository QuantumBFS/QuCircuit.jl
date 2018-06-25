@static if VERSION >= v"0.7-"
    using FFTW
end

export QFTCircuit, QFTBlock, invorder_firstdim

CRk(i::Int, j::Int, k::Int) = control([i, ], j=>shift(2π/(1<<k)))
CRot(n::Int, i::Int) = chain(i==j ? kron(i=>H) : CRk(j, i, j-i+1) for j = i:n)
QFTCircuit(n::Int) = chain(n, CRot(n, i) for i = 1:n)

struct QFTBlock{N} <: PrimitiveBlock{N,ComplexF64} end
mat(q::QFTBlock{N}) where N = applymatrix(q)

apply!(reg::DefaultRegister{B}, ::QFTBlock) where B = (reg.state = ifft!(invorder_firstdim(reg |> state), 1)*sqrt(1<<nqubits(reg)); reg)
apply!(reg::DefaultRegister{B}, ::Daggered{N, T, <:QFTBlock}) where {B,N,T} = (reg.state = invorder_firstdim(fft!(reg|>state, 1)/sqrt(1<<nqubits(reg))); reg)

# traits
ishermitian(q::QFTBlock{N}) where N = N==1
isreflexive(q::QFTBlock{N}) where N = N==1
isunitary(q::QFTBlock{N}) where N = true

function invorder_firstdim(v::Matrix)
    w = similar(v)
    n = size(v, 1) |> log2i
    n_2 = n ÷ 2
    mask = [bmask(i, n-i+1) for i in 1:n_2]
    @simd for b in basis(n)
        @inbounds w[breflect(n, b, mask)+1,:] = v[b+1,:]
    end
    w
end

function invorder_firstdim(v::Vector)
    n = length(v) |> log2i
    n_2 = n ÷ 2
    w = similar(v)
    #mask = SVector{n_2, Int}([bmask(i, n-i+1)::Int for i in 1:n_2])
    mask = [bmask(i, n-i+1)::Int for i in 1:n_2]
    @simd for b in basis(n)
        @inbounds w[breflect(n, b, mask)+1] = v[b+1]
    end
    w
end
