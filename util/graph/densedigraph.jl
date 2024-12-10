using Bijections

import Base: length

# ========================================
# Constructors and converions
# ========================================
# Adjacency matrix constructor
function DenseDiGraph{T}(V::AbstractVector{T}, E::AbstractMatrix{Bool}) where T
    g = DenseDiGraph{T}()

    for v in V
        addvertex!(g, v)
    end

    g.adjacency_matrix = deepcopy(E)
    return g
end

# Adjacency list constructor
function DenseDiGraph{T}(V::AbstractVector{T}, E::AbstractDict{T,Set{T}}) where T
    g = DenseDiGraph{T}()

    for v in V
        addvertex!(g, v)
    end

    for (v,s) in E
        for w in s
            g.adjacency_matrix[g.vertex_map[v], g.vertex_map[w]] = 1
        end
    end
    return g
end

tosparse(g::DenseDiGraph{T}) where T = SparseDiGraph{T}(
    g.vertex_map,
    Dict{T, Set{T}}(v => successors(g, v) for v in vertices(g))
)
DenseDiGraph{T}(g::SparseDiGraph{T}) where T = todense(g)

# ========================================
# Core graph functions
# ========================================
length(g::DenseDiGraph) = length(g.vertex_map)
n_vertices(g::DenseDiGraph) = length(g.vertex_map)
n_edges(g::DenseDiGraph) = sum(g.adjacency_matrix)

vertexid(g::DenseDiGraph{T}, v::T) where T = g.vertex_map[v]
vertextag(g::DenseDiGraph, i::Integer) = g.vertex_map(i)
vertices(g::DenseDiGraph{T}) where T = Set{T}(keys(g.vertex_map))
hasvertex(g::DenseDiGraph{T}, v::T) where T = haskey(g.vertex_map, v)

adjacency_matrix(g::DenseDiGraph) = g.adjacency_matrix

function hasedge(g::DenseDiGraph{T}, src::T, dst::T) where T
    if !hasvertex(g, src) || !hasvertex(g, dst)
        return false
    else
        return g.adjacency_matrix[g.vertex_map[src], g.vertex_map[dst]]
    end
end

successors(g::DenseDiGraph{T}, v::T) where T = Set{T}(g.vertex_map.(
    findall(g.adjacency_matrix[g.vertex_map[v],:])
))
predecessors(g::DenseDiGraph{T}, v::T) where T = Set{T}(g.vertex_map.(
    findall(g.adjacency_matrix[:,g.vertex_map[v]])
))

function addvertex!(g::DenseDiGraph{T}, v::T) where T
    if hasvertex(g, v)
        return nothing
    end

    g.vertex_map[v] = n_vertices(g) + 1

    # Resize the adjacency matrix
    # The full copy is awkward, but there's not really a great way
    # to expand along multiple dimensions without one
    new_adjacency_matrix = zeros(Bool, n_vertices(g), n_vertices(g))
    new_adjacency_matrix[1:end-1, 1:end-1] = g.adjacency_matrix
    g.adjacency_matrix = new_adjacency_matrix

    return nothing
end

function deletevertex!(g::DenseDiGraph{T}, v::T) where T
    if !hasvertex(g, v)
        return nothing
    end

    i_v = g.vertex_map[v]
    delete!(g.vertex_map, v)
    # Drop all the vertex IDs above that of v
    for i_w in (i_v+1):n_vertices(g)
        w = g.vertex_map(i_w)
        delete!(g.vertex_map, w)
        g.vertex_map[w] = i_w - 1
    end

    g.adjacency_matrix = g.adjacency_matrix[1:end .!= i_v, 1:end .!= i_v]

    return nothing
end

function addedge!(g::DenseDiGraph{T}, src::T, dst::T) where T
    if !hasvertex(g, src)
        addvertex!(g, src)
    end
    if !hasvertex(g, dst)
        addvertex!(g, dst)
    end

    if !hasedge(g, src, dst)
        g.adjacency_matrix[g.vertex_map[src], g.vertex_map[dst]] = 1
    end

    return nothing
end

function deleteedge!(g::DenseDiGraph{T}, src::T, dst::T) where T
    if !hasedge(g, src, dst)
        return nothing
    end

    g.adjacency_matrix[g.vertex_map[src], g.vertex_map[dst]] = 0

    return nothing
end

function empty!(g::DenseDiGraph)
    empty!(g.vertex_map)
    empty!(g.adjacency_matrix)
end

function subgraph(g::DenseDiGraph{T}, vertices) where T
    # Re-map the internal vertex IDs
    vertex_map = Bijection{T,Int}()
    i = 1
    for v in vertices
        if hasvertex(g, v)
            vertex_map[v] = i
            i += 1
        end
    end

    indices = [g.vertex_map[v] for v in vertices]
    return DenseDiGraph{T}(vertex_map, g.adjacency_matrix[indices, indices])
end