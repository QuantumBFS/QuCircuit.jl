####################### Gate Utilities ######################

###################### X, Y, Z Gates ######################
"""
    xgate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix

X Gate on multiple bits.
"""
function xgate(::Type{MT}, num_bit::Int, bits::Ints) where MT<:Number
    mask = bmask(bits...)
    order = map(b->flip(b, mask) + 1, basis(num_bit))
    PermMatrix(order, ones(MT, 1<<num_bit))
end

"""
    ygate(::Type{MT}, num_bit::Int, bits::Ints) -> PermMatrix

Y Gate on multiple bits.
"""
function ygate(::Type{MT}, num_bit::Int, bits::Ints) where MT<:Complex
    mask = bmask(bits...)
    order = Vector{Int}(1<<num_bit)
    vals = Vector{MT}(1<<num_bit)
    factor = MT(-im)^length(bits)
    for b = basis(num_bit)
        i = b+1
        order[i] = flip(b, mask) + 1
        vals[i] = count_ones(b&mask)%2 == 1 ? -factor : factor
    end
    PermMatrix(order, vals)
end

"""
    zgate(::Type{MT}, num_bit::Int, bits::Ints) -> Diagonal

Z Gate on multiple bits.
"""
function zgate(::Type{MT}, num_bit::Int, bits::Ints) where MT<:Number
    mask = bmask(bits...)
    vals = map(b->count_ones(b&mask)%2==0 ? one(MT) : -one(MT), basis(num_bit))
    Diagonal(vals)
end

####################### Controlled Gates #######################
#### C-X/Y/Z Gates
"""
    cxgate(::Type{MT}, num_bit::Int, b1::Ints, b2::Ints) -> PermMatrix

Single (Multiple) Controlled-X Gate on single (multiple) bits.
"""
function cxgate(::Type{MT}, num_bit::Int, cbits, cvals, b2::Ints) where MT<:Number
    c = controller(cbits, cvals)
    mask2 = bmask(b2)
    order = map(i -> c(i) ? flip(i, mask2)+1 : i+1, basis(num_bit))
    PermMatrix(order, ones(MT, 1<<num_bit))
end

"""
    cygate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) -> PermMatrix

Single Controlled-Y Gate on single bit.
"""
function cygate(::Type{MT}, num_bit::Int, cbits, cvals, b2::Int) where MT<:Complex
    c = controller(cbits, cvals)
    mask2 = bmask(b2)
    order = Vector{Int}(1<<num_bit)
    vals = Vector{MT}(1<<num_bit)
    @simd for b = 0:1<<num_bit-1
        i = b+1
        if b |> c
            @inbounds order[i] = flip(b, mask2) + 1
            @inbounds vals[i] = testany(b, mask2) ? MT(im) : -MT(im)
        else
            @inbounds order[i] = i
            @inbounds vals[i] = MT(1)
        end
    end
    PermMatrix(order, vals)
end

"""
    czgate(::Type{MT}, num_bit::Int, b1::Int, b2::Int) -> Diagonal

Single Controlled-Z Gate on single bit.
"""
function czgate(::Type{MT}, num_bit::Int, cbits, cvals, b2::Int) where MT<:Number
    c = controller([cbits...,b2], [cvals..., 1])
    vals = map(i -> c(i) ? MT(-1) : MT(1), basis(num_bit))
    Diagonal(vals)
end

"""
    controlled_U1(num_bit::Int, gate::AbstractMatrix, cbits::Vector{Int}, b2::Int) -> AbstractMatrix

Return general multi-controlled single qubit `gate` in hilbert space of `num_bit` qubits.

* `cbits` specify the controling positions.
* `b2` is the controlled position.
"""
function controlled_U1 end


# general multi-control single-gate
function controlled_U1(num_bit::Int, gate::PermMatrix{T}, cbits::Vector{Int}, cvals::Vector{Int}, b2::Int) where {T}
    vals = Vector{T}(1<<num_bit)
    order = Vector{Int}(1<<num_bit)
    mask = bmask(cbits...)
    onemask = bmask(cbits[cvals.==1]...)
    mask2 = bmask(b2)
    @simd for b in basis(num_bit)
        bind = b+1
        if testval(b, mask, onemask)
            @inbounds vals[bind] = gate.vals[gate.perm[2-takebit(b, b2)]]
            @inbounds order[bind] = (gate.perm[1] == 1) ? bind : flip(b, mask2)+1
        else
            @inbounds vals[bind] = 1
            @inbounds order[bind] = bind
        end
    end
    PermMatrix(order, vals)
end

function controlled_U1(num_bit::Int, gate::Diagonal{T}, cbits::Vector{Int}, cvals::Vector{Int}, b2::Int) where {T}
    mask = bmask(cbits...)
    onemask = bmask(cbits[cvals.==1]...)

    a, b = gate.diag
    ######### LW's version ###########
    vals = Vector{T}(1<<num_bit)
    @simd for i in basis(num_bit)
        if testval(i, mask, onemask)
            @inbounds vals[i+1] = gate.diag[1+takebit(i, b2)]
        else
            @inbounds vals[i+1] = 1
        end
    end
    Diagonal(vals)
end

function controlled_U1(num_bit::Int, gate::AbstractMatrix, cbits::Vector{Int}, cvals::Vector{Int}, b2::Int)
    general_controlled_gates(num_bit, [c==1 ? mat(P1) : mat(P0) for c in cvals], cbits, [gate], [b2])
end

# arbituary control PermMatrix gate: SparseMatrixCSC
# TODO: to interface
#toffoligate(num_bit::Int, b1::Int, b2::Int, b3::Int) = controlled_U1(num_bit, PAULI_X, [b1, b2], b3)
