abstract type AbstractGraph{T} end
abstract type AbstractDiGraph{T} <: AbstractGraph{T} end

# Bijections didn't implement empty, so I put one here for all graphs to use
using Bijections
function empty!(b::Bijection)
    for k in keys(b)
        delete!(b, k)
    end
end