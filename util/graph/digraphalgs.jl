using DataStructures
using Bijections

# Tarjan's algorithm for strongly-connected components; O(V+E)
# https://www.cs.cmu.edu/~15451-f18/lectures/lec19-DFS-strong-components.pdf
mutable struct TarjanVertexData
    index::Int # Index of when this vertex was visited by the DFS
    lowlink::Int # Oldest vertex within the SCC reachable via this vertex's DFS subtree
    on_stack::Bool # This vertex is still in the DFS and hasn't been committed to an SCC
end
function tarjan(g::AbstractDiGraph{T}) where T
    sccs = Vector{Set{Int}}()
    dfs_index = 1
    scc_stack = Stack{T}()
    tarjan_data = Dict{T, TarjanVertexData}()

    # Finds the strongly-connected components in the subgraph of v
    function strongconnect(g::AbstractDiGraph{T}, v::T)
        if haskey(tarjan_data, v)
            return nothing
        end

        # Initialize the vertex's data and put it on the stack,
        # signifying that it is part of the current SCC
        tarjan_data[v] = TarjanVertexData(dfs_index, dfs_index, true)
        dfs_index += 1
        push!(scc_stack, v)

        # Advance to all successors of v
        for w in successors(g, v)
            # If the successor hasn't been visited yet, recurse on it.
            # Once the depth-first recursive call returns, we know the entire subgraph of
            # w has been visited and its lowlink is finished being changed.
            # w's subtree is part of v's subtree, so take the min of the two lowlinks.
            if !haskey(tarjan_data, w)
                strongconnect(g, w)
                tarjan_data[v].lowlink = min(tarjan_data[v].lowlink, tarjan_data[w].lowlink)
            # If the successor is on the stack, it's in the DFS but not committed to an SCC.
            # Because w already has its own DFS subtree in this case, we do not take its lowlink
            # (which would not be part of v's DFS subtree) and only take its index.
            elseif tarjan_data[w].on_stack
                tarjan_data[v].lowlink = min(tarjan_data[v].lowlink, tarjan_data[w].index)
            # If the successor has been visited by the DFS before but is no longer on the stack,
            # its SCC has been finalized. Thus, we cannot use it for our lowlink, since the lowlink
            # value must be within our SCC.
            end
        end

        # If, after the DFS subtree has been explored, v's lowlink is still its own index,
        # then it must be the root/lowpoint of its SCC. The SCC is then anything
        # on the stack above v (i.e., uncommitted vertices from its subtree).
        #
        # Rough proof
        # -----------
        # v is reachable through any vertex on the stack. Let's say
        # a vertex v' is on the stack (i.e., not committed to an SCC).
        # If v is not reachable, then v' must be in a different SCC than v.
        # If v' were older than v, due to the depth-first nature of the search,
        # the SCC of v' would have been fully explored before v was visited
        # (if it were indeed a different SCC), and v' would be popped off the stack.
        # If v' were newer than v, by this point (after the full subtree of v has been explored),
        # if v' were part of another SCC, the DFS again would have already
        # completed that SCC and removed its vertices from the stack.
        # Thus, by contradiction, v is reachable from any vertex on the stack.
        #
        # Additionally, the lowlink value will always point to a vertex currently
        # on the stack. When the lowlink value was assigned to a vertex index,
        # that vertex was on the stack. Any vertex using its index as the lowlink would
        # have been above it on the stack (i.e., later in the DFS)
        # to pass the min check against its own index (since the lowlink is initialized to the index).
        # Thus, if this vertex were popped off the stack, any vertex using it as its lowlink
        # would have been popped already.
        #
        # Finally, SCCs must have a single lowpoint where the lowlink equals the index.
        # A vertex v' within the SCC of v, where v has the lowest index in the SCC,
        # is necessarily within the DFS subtree of v and has a higher index than v.
        # If v' is part of the SCC of v, there must be a series of edges that connects v' to v.
        # At some point along the path, there must be an edge going back to an earlier vertex
        # to form a cycle, by the nature of an SCC. If that edge originates
        # from v', it would take the index of the earlier vertex as its lowlink.
        # If that edge originates from a different vertex, that vertex must be in the DFS
        # subtree of v', and the lowlink of v' will be set when the recursion rolls back up.
        #
        # Then, knowing that the lowlink of v is on the stack and that v is reachable from
        # any stack vertex, if the lowlink of v is not its own index, it cannot
        # be the SCC root, as the lowlink of v has a lower index and is still a member of the SCC.
        # Conversely, as shown above, if v is not the SCC root, it cannot have a lowlink equal its own index,
        # as the path back to the SCC root necessarily sets a lower lowlink for v.
        # As such, we can say that v is the lowpoint of the SCC iff its lowlink is equal to its index.
        #
        # Further, the rest of the SCC is comprised of all vertices above v on the stack.
        # Because the recursive call to v has not yet returned, any new vertices on the stack
        # must be in the DFS subtree of v, meaning they are reachable from v. We also know from before
        # that v is reachable from any vertex on the stack. Thus, these vertices must be in the
        # SCC of v. Meanwhile, any vertices below v on the stack are not reachable from v. If a vertex v'
        # were both earlier in the stack and reachable from v, knowing that v is reachable from v',
        # v' would then be in the same SCC as v, and thus be the lowpoint. However, because
        # we know v is the lowpoint, such a v' cannot exist. Thus, the full SCC is given by
        # the values above v on the stack and v itself.
        if tarjan_data[v].lowlink == tarjan_data[v].index
            curr_scc = Set{Int}()
            while true
                w = pop!(scc_stack)
                tarjan_data[w].on_stack = false
                push!(curr_scc, w)
                if w == v
                    break
                end
            end
            push!(sccs, curr_scc)
        end

        return nothing
    end

    # Make sure every vertex is convered in case of disjoint graphs
    for v in vertices(g)
        if !haskey(tarjan_data, v)
            strongconnect(g, v)
        end
    end

    return sccs
end

# Compute the SCC DAG of the directed graph; O(V^2)
function scc_collapse(g::AbstractDiGraph{T}) where T
    sccs = Vector{Set{T}}(tarjan(g))
    scc_dag = SparseDiGraph{Int}() # An SCC DAG is extremely sparse by nature

    for i in 1:length(sccs)
        addvertex!(scc_dag, i)
    end

    scc_successors = [reduce(∪, [successors(g, v) for v in scc]) for scc in sccs]
    for (i, (scc1, scc1_successors)) in enumerate(zip(sccs, scc_successors))
        for (j, scc2) in enumerate(sccs)
            # If there is an element of SCC2 in the successors of SCC1,
            # there is an edge from SCC1 to SCC2!
            if !isempty(scc1_successors ∩ scc2)
                addedge!(scc_dag, i, j)
            end
        end
    end

    return sccs, scc_dag
end

# Uncollapse an SCC DAG; O(V^2)
# The edge information within the SCC and the original vertex ordering will be lost 😢
# SCCs are assumed to be fully connected
function scc_uncollapse(sccs::AbstractVector{Set{T}}, scc_dag::AbstractDiGraph{<:Integer}) where T
    g = DenseDiGraph{T}()

    # Add all vertices in SCCs as fully connected
    for scc in sccs
        for v in scc
            for w in scc
                if v != w
                    if !hasvertex(g, v)
                        addvertex!(g, v)
                    end
                    if !hasvertex(g, w)
                        addvertex!(g, w)
                    end

                    addedge!(g, v, w)
                end
            end
        end
    end

    # Connect SCCs
    for (i, scc1) in enumerate(sccs)
        for (j, scc2) in enumerate(sccs)
            if i != j && hasedge(scc_dag, i, j)
                for v in scc1
                    for w in scc2
                        addedge!(g, v, w)
                    end
                end
            end
        end
    end

    return g
end

# Kahn's algorithm for topological sort; O(V+E)
function topological_sort(g::AbstractDiGraph{T}) where T
    scratch = deepcopy(g)

    L = Vector{Int}() # List of vertices in sorted order
    # Set of vertices with no incoming edges, i.e., unreachable
    S = Set{T}([v for v in vertices(scratch) if isempty(predecessors(scratch, v))])

    while !isempty(S)
        v = collect(Iterators.take(S, 1))[1] # Get one vertex from S
        pop!(S, v)
        push!(L, v)
        for w in successors(scratch, v)
            deleteedge!(scratch, v, w)
            if isempty(predecessors(scratch, w))
                push!(S, w)
            end
        end
    end

    if n_edges(scratch) > 0
        # Graph has cycles!
        return Vector{Int}([])
    else
        return L
    end
end

# Fast algorithm for transitive closure using the SCC DAG,
# topological sort, and boolean matrix multiplication
# using the fact that (A+I)^V, where A is the adjacency matrix,
# gives the adjacency matrix of the transitive closure!
# https://people.csail.mit.edu/virgi/6.890/lecture3.pdf
# O(V^3) from matrix mulitplication.
function transitive_closure(g::AbstractDiGraph)
    sccs, scc_dag = scc_collapse(g)

    # Re-order the SCC in topological order so that the adjacency matrix is upper triangular
    ordered_scc_dag = SparseDiGraph{Int}()
    scc_topo = topological_sort(scc_dag)
    for v in scc_topo
        addvertex!(ordered_scc_dag, v)
    end
    for v in scc_topo
        for w in successors(scc_dag, v)
            addedge!(ordered_scc_dag, v, w)
        end
    end

    closure_adjacency = adjacency_matrix(ordered_scc_dag)
    # Need the diagonal true for the boolean matrix mulplication trick to work
    for i in 1:n_vertices(ordered_scc_dag)
        closure_adjacency[i,i] = 1
    end

    # Split the upper triangular matrix into sub-matrices to avoid computations
    # on the zero lower-left sub-matrix
    submat_size = ceil(Int, n_vertices(ordered_scc_dag) / 2)
    M = closure_adjacency[1:submat_size, 1:submat_size]
    C = closure_adjacency[1:submat_size, submat_size+1:end]
    B = closure_adjacency[submat_size+1:end, submat_size+1:end]

    prev_closure_adjacency = zeros(Bool, size(closure_adjacency))
    for i in 1:n_vertices(ordered_scc_dag)
        # If we have no change, we've converged to the right adjacency matrix
        if closure_adjacency == prev_closure_adjacency
            break
        end

        # Take sub-matrix exponents until we converge
        prev_closure_adjacency[:] = closure_adjacency[:]
        closure_adjacency[1:submat_size, 1:submat_size] =
            (closure_adjacency[1:submat_size, 1:submat_size] * M) .> 0
        closure_adjacency[submat_size+1:end, submat_size+1:end] =
            (closure_adjacency[submat_size+1:end, submat_size+1:end] * B) .> 0
        closure_adjacency[1:submat_size, submat_size+1:end] =
            (closure_adjacency[1:submat_size, 1:submat_size] * C *
             closure_adjacency[submat_size+1:end, submat_size+1:end]) .> 0
    end

    for i in 1:n_vertices(ordered_scc_dag)
        closure_adjacency[i,i] = 0
    end

    scc_closure = SparseDiGraph{Int}(scc_topo, closure_adjacency)
    closure = scc_uncollapse(sccs, scc_closure)

    return closure
end