export RotationGate

mutable struct RotationGate{T, GT <: PrimitiveBlock{1, Complex{T}}} <: PrimitiveBlock{1, Complex{T}}
    U::GT
    theta::T
end

_make_rot_mat(I, U, theta) = I * cos(theta / 2) - im * sin(theta / 2) * U
mat(R::RotationGate{T, GT}) where {T, GT} = _make_rot_mat(IMatrix{2, Complex{T}}(), mat(R.U), R.theta)

copy(R::RotationGate{T, GT}) where {T, GT} = RotationGate{T, GT}(copy(R.U), R.theta)

function dispatch!(f::Function, R::RotationGate{T, GT}, theta) where {T, GT}
    R.theta = f(R.theta, theta)
    R
end

# Properties
nparameters(::RotationGate) = 1

==(lhs::RotationGate{TA, GTA}, rhs::RotationGate{TB, GTB}) where {TA, TB, GTA, GTB} = false
==(lhs::RotationGate{TA, GT}, rhs::RotationGate{TB, GT}) where {TA, TB, GT} = lhs.theta == rhs.theta

function hash(gate::RotationGate{T, GT}, h::UInt) where {T, GT}
    hashkey = hash(objectid(gate), h)
    hashkey = hash(gate.theta, hashkey)
    hashkey = hash(gate.U, hashkey)
    hashkey
end

function print_block(io::IO, R::RotationGate)
    print(io, "Rot ", R.U, ": ", R.theta)
end
