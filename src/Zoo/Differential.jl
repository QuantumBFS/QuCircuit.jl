export diff_circuit, num_gradient, rotter, cnot_entangler, opgrad, collect_rotblocks, perturb

"""
    rotter(noleading::Bool=false, notrailing::Bool=false) -> ChainBlock{1, ComplexF64}

Arbitrary rotation unit, set parameters notrailing, noleading true to remove trailing and leading Z gates.
"""
function rotter(noleading::Bool=false, notrailing::Bool=false)
    g = chain(1)
    !noleading && push!(g, Rz(0))
    push!(g, Rx(0))
    !notrailing && push!(g, Rz(0))
    g
end

"""
    cnot_entangler([n::Int, ] pairs::Vector{Pair}) = ChainBlock

Arbitrary rotation unit, support lazy construction.
"""
cnot_entangler(n::Int, pairs) = chain(n, control(n, [ctrl], target=>X) for (ctrl, target) in pairs)
cnot_entangler(pairs) = n->cnot_entangler(n, pairs)

layer(tag::Symbol) = layer(Val(tag))
layer(::Val{:first}) = n->chain(n, put(i=>cache(rotter(true, false))) for i=1:n)
layer(::Val{:mid}) = n->chain(n, put(i=>cache(rotter(false, false))) for i=1:n)
layer(::Val{:last}) = n->chain(n, put(i=>cache(rotter(false, true))) for i=1:n)

"""
    diff_circuit(n, nlayer, pairs) -> ChainBlock

A kind of widely used differentiable quantum circuit, angles in the circuit is randomely initialized.

ref:
    1. Kandala, A., Mezzacapo, A., Temme, K., Takita, M., Chow, J. M., & Gambetta, J. M. (2017).
       Hardware-efficient Quantum Optimizer for Small Molecules and Quantum Magnets. Nature Publishing Group, 549(7671), 242–246.
       https://doi.org/10.1038/nature23879.
"""
function diff_circuit(n, nlayer, pairs)
    circuit = chain(n)

    push!(circuit, layer(:first))
    for i = 1:(nlayer - 1)
        push!(circuit, cache(cnot_entangler(pairs)))
        push!(circuit, layer(:mid))
    end

    push!(circuit, cache(cnot_entangler(pairs)))
    push!(circuit, layer(:last))
    dispatch!(circuit, rand(nparameters(circuit))*2π)
end

"""
    collect_rotblocks(blk::AbstractBlock) -> Vector{RotationGate}

filter out all rotation gates, which is differentiable.
"""
function collect_rotblocks(blk::AbstractBlock)
    rots = blockfilter!(x->x isa RotationGate, Vector{RotationGate}([]), blk)
    nparameters(blk)==length(rots) || warn("some parameters in this circuit are not differentiable!")
    rots
end

"""
    perturb(func, gates::Vector{<:RotationGate}, diff::Real) -> Matrix

perturb every rotation gates, and evaluate losses.
The i-th element of first column of resulting Matrix corresponds to Gi(θ+δ), and the second corresponds to Gi(θ-δ).
"""
function perturb(func, gates::Vector{<:RotationGate}, diff::Real)
    ng = length(gates)
    res = Matrix{Float64}(ng, 2)
    for i in 1:ng
        gate = gates[i]
        dispatch!(+, gate, diff)
        res[i, 1] = func()

        dispatch!(+, gate, -2*diff)
        res[i, 2] = func()

        dispatch!(+, gate, diff) # set back
    end
    res
end

"""
    num_gradient(lossfunc, rots::Vector{<:RotationGate}, δ::Float64=1e-2) -> Vector

Compute gradient numerically.
"""
function num_gradient(lossfunc, rots::Vector{<:RotationGate}, δ::Float64=1e-2)
    gperturb = perturb(lossfunc, rots, δ)
    (gperturb[:,1] - gperturb[:,2])/(2δ)
end

"""
    opgrad(op_expect, rots::Vector{<:RotationGate}) -> Vector

get the gradient of an operator expectation function.

References:
    Mitarai, K., Negoro, M., Kitagawa, M., & Fujii, K. (2018). Quantum Circuit Learning, 1–3. Retrieved from http://arxiv.org/abs/1803.00745
"""
function opgrad(op_expect, rots::Vector{<:RotationGate})
    gperturb = perturb(op_expect, rots, π/2)
    (gperturb[:,1] - gperturb[:,2])/2
end
