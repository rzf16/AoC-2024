using Bijections

import Base: length

# ========================================
# Constructors and converions
# ========================================
# Adjacency list constructor
function SparseDiGraph{T}(V::AbstractVector{T}, E::AbstractDict{T,Set{T}}) where T
    @assert length(V) == length(E)

    g = SparseDiGraph{T}()

    for v in V
        addvertex!(g, v)
    end

    g.adjacency_lists = deepcopy(E)
    return g
end

# Adjacency matrix constructor
function SparseDiGraph{T}(V::AbstractVector{T}, E::AbstractMatrix{Bool}) where T
    @assert ndims(E) == 2
    @assert length(V) == size(E)[1] == size(E)[2]

    g = SparseDiGraph{T}()

    for v in V
        addvertex!(g, v)
    end

    for v in V
        g.adjacency_lists[v] = Set{T}(g.vertex_map.(findall(E[g.vertex_map[v],:])))
    end
    return g
end

todense(g::SparseDiGraph{T}) where T = DenseDiGraph{T}(g.vertex_map, adjacency_matrix(g))
SparseDiGraph{T}(g::DenseDiGraph{T}) where T = tosparse(g)

# ========================================
# Core graph functions
# ========================================
length(g::SparseDiGraph) = length(g.vertex_map)
n_vertices(g::SparseDiGraph) = length(g.vertex_map)
n_edges(g::SparseDiGraph) = sum([length(s) for s in values(g.adjacency_lists)])

vertexid(g::SparseDiGraph{T}, v::T) where T = g.vertex_map[v]
vertextag(g::SparseDiGraph, i::Integer) = g.vertex_map(i)
vertices(g::SparseDiGraph{T}) where T = Set{T}(keys(g.vertex_map))
hasvertex(g::SparseDiGraph{T}, v::T) where T = haskey(g.vertex_map, v)

function adjacency_matrix(g::SparseDiGraph)
    mat = zeros(Bool, (n_vertices(g), n_vertices(g)))
    for (v,s) in g.adjacency_lists
        for w in s
            mat[g.vertex_map[v], g.vertex_map[w]] = 1
        end
    end
    return mat
end

function hasedge(g::SparseDiGraph{T}, src::T, dst::T) where T
    if !hasvertex(g, src) || !hasvertex(g, dst)
        return false
    else
        return dst ∈ g.adjacency_lists[src]
    end
end

successors(g::SparseDiGraph{T}, v::T) where T = g.adjacency_lists[v]

function predecessors(g::SparseDiGraph{T}, v::T) where T
    ps = Set{T}()
    for (w,s) in g.adjacency_lists
        if v in s
            push!(ps, w)
        end
    end
    return ps
end

function addvertex!(g::SparseDiGraph{T}, v::T) where T
    if hasvertex(g, v)
        return nothing
    end

    g.vertex_map[v] = n_vertices(g) + 1
    g.adjacency_lists[v] = Set{T}()

    return nothing
end

function deletevertex!(g::SparseDiGraph{T}, v::T) where T
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

    delete!(g.adjacency_lists, v)
    for (w,s) in g.adjacency_lists
        if v ∈ s
            pop!(s, v)
        end
    end

    return nothing
end

function addedge!(g::SparseDiGraph{T}, src::T, dst::T) where T
    if !hasvertex(g, src)
        addvertex!(g, src)
    end
    if !hasvertex(g, dst)
        addvertex!(g, dst)
    end

    if !hasedge(g, src, dst)
        push!(g.adjacency_lists[src], dst)
    end

    return nothing
end

function deleteedge!(g::SparseDiGraph{T}, src::T, dst::T) where T
    if !hasedge(g, src, dst)
        return nothing
    end

    pop!(g.adjacency_lists[src], dst)

    return nothing
end

function empty!(g::SparseDiGraph)
    empty!(g.vertex_map)
    empty!(g.adjacency_lists)
end

function subgraph(g::SparseDiGraph{T}, vertices) where T
    # Re-map the internal vertex IDs
    vertex_map = Bijection{T,Int}()
    adjacency_lists = Dict{T,Set{T}}()
    i = 1
    for v in vertices
        if hasvertex(g, v)
            vertex_map[v] = i
            adjacency_lists[v] = g.adjacency_lists[v] ∩ Set{T}(vertices)
            i += 1
        end
    end

    return SparseDiGraph{T}(vertex_map, adjacency_lists)
end