include("util/graph/GraphUtils.jl")
using .GraphUtils

import Base.findfirst

@enum CellType begin
    CELL_FREE
    CELL_OBSTACLE
end

@enum Direction begin
    DIR_DOWN
    DIR_RIGHT
    DIR_UP
    DIR_LEFT
end

function rightof(dir::Direction)
    if dir == DIR_DOWN
        return DIR_LEFT
    elseif dir == DIR_RIGHT
        return DIR_DOWN
    elseif dir == DIR_UP
        return DIR_RIGHT
    elseif dir == DIR_LEFT
        return DIR_UP
    end
end

function leftof(dir::Direction)
    if dir == DIR_DOWN
        return DIR_RIGHT
    elseif dir == DIR_RIGHT
        return DIR_UP
    elseif dir == DIR_UP
        return DIR_LEFT
    elseif dir == DIR_LEFT
        return DIR_DOWN
    end
end

function unitvector(dir::Direction)
    if dir == DIR_DOWN
        return CartesianIndex(1,0)
    elseif dir == DIR_RIGHT
        return CartesianIndex(0,1)
    elseif dir == DIR_UP
        return CartesianIndex(-1,0)
    elseif dir == DIR_LEFT
        return CartesianIndex(0,-1)
    end
end

struct Configuration
    loc::CartesianIndex
    dir::Direction
end
function str(q::Configuration)
    if q.dir == DIR_DOWN
        return "($(q.loc[1]),$(q.loc[2])) DOWN"
    elseif q.dir == DIR_RIGHT
        return "($(q.loc[1]),$(q.loc[2])) RIGHT"
    elseif q.dir == DIR_UP
        return "($(q.loc[1]),$(q.loc[2])) UP"
    elseif q.dir == DIR_LEFT
        return "($(q.loc[1]),$(q.loc[2])) LEFT"
    end
end

# Finds the next element in coords, a list of 2D coordinates, that will be encountered when starting from q.
# coords is assumed to be sorted by the first index, then the second!
function findfirst(q::Configuration, coords)
    if q.dir == DIR_DOWN
        return findfirst(x -> x[1] > q.loc[1] && x[2] == q.loc[2], coords)
    elseif q.dir == DIR_RIGHT
        return findfirst(x -> x[1] == q.loc[1] && x[2] > q.loc[2], coords)
    elseif q.dir == DIR_UP
        return findlast(x -> x[1] < q.loc[1] && x[2] == q.loc[2], coords)
    elseif q.dir == DIR_LEFT
        return findlast(x -> x[1] == q.loc[1] && x[2] < q.loc[2], coords)
    end
end

# Insight: any path is fully defined by the obstacles the guard encounters!
# We can represent the space of paths as a graph with edges between obstacles.
function build_obstacle_graph(obstacles)
    g = SparseDiGraph{String}()
    vertex_data = Dict{String, Configuration}()
    addvertex!(g, "terminal")

    # We will use four vertices per obstacle to represent
    # each incoming direction, since the outgoing edge will differ
    # based on that.
    for o_loc in obstacles
        for d in instances(Direction)
            q = Configuration(o_loc, d)
            addvertex!(g, str(q))
            vertex_data[str(q)] = q
        end
    end

    # Now, find what would happen if we hit each obstacle from each direction
    for v_str in vertices(g)
        if v_str == "terminal"
            continue
        end

        o = vertex_data[v_str]

        # Conveniently, the way we parsed the obstacles ensures
        # that the list is sorted first by row, then by column,
        # so we can use our findfirst pretty easily :)
        # We will end up one cell short of the obstacle in the direction of movement and turn right
        i_successor = findfirst(Configuration(o.loc-unitvector(o.dir), rightof(o.dir)), obstacles)

        # Nothing found -> we'll leave the map!
        if isnothing(i_successor)
            addedge!(g, v_str, "terminal")
        # Otherwise, add an edge to that obstacle/direction vertex
        else
            successor = Configuration(obstacles[i_successor], rightof(o.dir))
            addedge!(g, v_str, str(successor))
        end
    end

    return g, vertex_data
end

function createscycle(g::AbstractDiGraph{String}, vertex_data::Dict{String,Configuration},
                      o::Configuration, obstacles, bounds)
    # The obstacle is already in the graph!
    if o.loc in obstacles
        return false
    end

    # Obstacle is out of bounds
    if o.loc[1] < 1 || o.loc[1] > bounds[1] || o.loc[2] < 1 || o.loc[2] > bounds[2]
        return false
    end

    # Add the obstacle to the graph
    temp_vertices = Set{String}()
    for d in instances(Direction)
        q = Configuration(o.loc, d)
        push!(temp_vertices, str(q))
        addvertex!(g, str(q))
        vertex_data[str(q)] = q

        i_successor = findfirst(Configuration(q.loc-unitvector(q.dir), rightof(q.dir)), obstacles)
        if isnothing(i_successor)
            addedge!(g, str(q), "terminal")
        else
            successor = Configuration(obstacles[i_successor], rightof(q.dir))
            addedge!(g, str(q), str(successor))
        end
    end

    # If there are no successors from the guard's path, this obstacle can't create a cycle
    if collect(Iterators.take(successors(g, str(o)), 1))[1] == "terminal"
        for v_str in temp_vertices
            deletevertex!(g, v_str)
            delete!(vertex_data, v_str)
        end
        return false
    end

    # Check if this new obstacle is the successor of any existing vertices
    # We need to search:
    # * The row above to the left
    # * The row below to the right
    # * The column right upwards
    # * The column left downwards
    old_edges = Vector{Tuple{String, String}}()

    left_candidates = filter(x -> x[1] == o.loc[1]-1 && x[2] < o.loc[2], obstacles)
    for candidate_loc in left_candidates
        q = Configuration(candidate_loc, leftof(DIR_RIGHT))
        successor_str = collect(Iterators.take(successors(g, str(q)), 1))[1]
        # If the successor was to the right of the new obstacle,
        # the new obstacle is the new successor
        if successor_str == "terminal" || vertex_data[successor_str].loc[2] > o.loc[2]
            push!(old_edges, (str(q), successor_str))
            deleteedge!(g, str(q), successor_str)
            addedge!(g, str(q), str(Configuration(o.loc, DIR_RIGHT)))
        end
    end

    right_candidates = filter(x -> x[1] == o.loc[1]+1 && x[2] > o.loc[2], obstacles)
    for candidate_loc in right_candidates
        q = Configuration(candidate_loc, leftof(DIR_LEFT))
        successor_str = collect(Iterators.take(successors(g, str(q)), 1))[1]
        # If the successor was to the left of the new obstacle,
        # the new obstacle is the new successor
        if successor_str == "terminal" || vertex_data[successor_str].loc[2] < o.loc[2]
            push!(old_edges, (str(q), successor_str))
            deleteedge!(g, str(q), successor_str)
            addedge!(g, str(q), str(Configuration(o.loc, DIR_LEFT)))
        end
    end

    up_candidates = filter(x -> x[1] < o.loc[1] && x[2] == o.loc[2]+1, obstacles)
    for candidate_loc in up_candidates
        q = Configuration(candidate_loc, leftof(DIR_DOWN))
        successor_str = collect(Iterators.take(successors(g, str(q)), 1))[1]
        # If the successor was below the new obstacle,
        # the new obstacle is the new successor
        if successor_str == "terminal" || vertex_data[successor_str].loc[1] > o.loc[1]
            push!(old_edges, (str(q), successor_str))
            deleteedge!(g, str(q), successor_str)
            addedge!(g, str(q), str(Configuration(o.loc, DIR_DOWN)))
        end
    end

    down_candidates = filter(x -> x[1] > o.loc[1] && x[2] == o.loc[2]-1, obstacles)
    for candidate_loc in down_candidates
        q = Configuration(candidate_loc, leftof(DIR_UP))
        successor_str = collect(Iterators.take(successors(g, str(q)), 1))[1]
        # If the successor was above the new obstacle,
        # the new obstacle is the new successor
        if successor_str == "terminal" || vertex_data[successor_str].loc[1] < o.loc[1]
            push!(old_edges, (str(q), successor_str))
            deleteedge!(g, str(q), successor_str)
            addedge!(g, str(q), str(Configuration(o.loc, DIR_UP)))
        end
    end

    # Starting from the configuration at which we initially encounter this obstacle,
    # follow the successors and see if we create a cycle
    curr_str = str(o)
    successor_str = collect(Iterators.take(successors(g, curr_str), 1))[1]
    visited_set = Set{String}([curr_str])
    while successor_str != "terminal" && successor_str ∉ visited_set
        push!(visited_set, successor_str)
        curr_str = successor_str
        successor_str = collect(Iterators.take(successors(g, curr_str), 1))[1]
    end

    # Delete our temporary vertices and restore the replaced edges
    for v_str in temp_vertices
        deletevertex!(g, v_str)
        delete!(vertex_data, v_str)
    end
    for e in old_edges
        addedge!(g, e[1], e[2])
    end

    return successor_str != "terminal"
end

# State machine logic for the guard
function step_guard(guard::Configuration, obstacles, bounds)
    if guard.loc[1] < 1 || guard.loc[1] > bounds[1] ||
       guard.loc[2] < 1 || guard.loc[2] > bounds[2]
        return true, nothing
    end

    next_loc = guard.loc + unitvector(guard.dir)
    if next_loc ∈ obstacles
        return false, Configuration(guard.loc, rightof(guard.dir))
    elseif guard.dir == DIR_DOWN && next_loc[1] > bounds[1]
        return true, nothing
    elseif guard.dir == DIR_RIGHT && next_loc[2] > bounds[2]
        return true, nothing
    elseif guard.dir == DIR_UP && next_loc[1] < 1
        return true, nothing
    elseif guard.dir == DIR_LEFT && next_loc[2] < 1
        return true, nothing
    else
        return false, Configuration(next_loc, guard.dir)
    end
end

function main()
    map_size = nothing
    obstacles = Vector{CartesianIndex}()
    initial_guard = nothing
    open("day6b_input.txt", "r") do f
        i = 1
        line_length = nothing
        while ! eof(f)
            line = readline(f)
            line_length = length(line)

            for (j,c) in enumerate(collect(line))
                if c == '#'
                    push!(obstacles, CartesianIndex(i,j))
                elseif c == 'v'
                    initial_guard = Configuration(CartesianIndex(i,j), DIR_DOWN)
                elseif c == '>'
                    initial_guard = Configuration(CartesianIndex(i,j), DIR_RIGHT)
                elseif c == '^'
                    initial_guard = Configuration(CartesianIndex(i,j), DIR_UP)
                elseif c == '<'
                    initial_guard = Configuration(CartesianIndex(i,j), DIR_LEFT)
                end
            end

            i += 1
        end
        map_size = (i-1, line_length)
    end

    g, vertex_data = build_obstacle_graph(obstacles)

    # Iterate through the path cycle-checking
    guard = deepcopy(initial_guard)
    tested_o_locs = Set{CartesianIndex}()
    cycle_o_locs = Set{CartesianIndex}()
    while true
        # Check an obstacle placed directly in front of the guard's pose
        o = Configuration(guard.loc+unitvector(guard.dir), guard.dir)

        # Condition 1: skip the initial guard location
        # Condition 2: do not test any locations we've tested before
        #   This is actually extremely important, not just a performance gain,
        #   because if the obstacle location is at a point that was previously
        #   on the path, there's no guarantee we even reach the current pose
        #   after being redirected by the new obstruction.
        #   The cycle test function searches from the graph from the
        #   provided obstacle pose, not from the initial guard pose,
        #   so we need this logic to avoid erroneous cycles being reported.
        if o.loc != initial_guard.loc && o.loc ∉ tested_o_locs
            push!(tested_o_locs, o.loc)
            if createscycle(g, vertex_data, o, obstacles, map_size)
                push!(cycle_o_locs, o.loc)
            end
        end

        terminal, guard = step_guard(guard, obstacles, map_size)
        if terminal
            break
        end
    end

    println(length(cycle_o_locs))
end

main()