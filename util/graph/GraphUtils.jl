module GraphUtils
export AbstractGraph, AbstractDiGraph
export SparseDiGraph, DenseDiGraph
export length, n_vertices, n_edges
export vertexid, vertextag, vertices, hasvertex
export adjacency_matrix, hasedge, successors, predecessors
export addvertex!, addedge!, deletevertex!, deleteedge!, empty!
export subgraph
export todense, tosparse
export tarjan, scc_collapse, scc_uncollapse, topological_sort, transitive_closure

include("graph.jl")
include("digraph.jl")
include("sparsedigraph.jl")
include("densedigraph.jl")
include("digraphalgs.jl")

end # module GraphUtils