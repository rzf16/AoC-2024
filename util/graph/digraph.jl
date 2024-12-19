using Bijections

# Adjacency list representation for sparse directed graphs
mutable struct SparseDiGraph{T} <: AbstractDiGraph{T}
    vertex_map::Bijection{T,Int} # Bidirectional map between external and internal vertex ID
    adjacency_lists::Dict{T,Set{T}} # Graph vertex adjacency lists
end
SparseDiGraph{T}() where T = SparseDiGraph{T}(Bijection{T,Int}(), Dict{T,Set{T}}())

# Adjacency matrix representation for dense directed graphs
mutable struct DenseDiGraph{T} <: AbstractDiGraph{T}
    vertex_map::Bijection{T,Int} # Bidirectional map between external and internal vertex ID
    adjacency_matrix::Array{Bool,2} # Graph adjacency matrix
end
DenseDiGraph{T}() where T = DenseDiGraph{T}(Bijection{T,Int}(), Array{Bool}(undef, (0,0)))