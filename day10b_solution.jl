using DataStructures

mutable struct Cell
    height::UInt8
    n_reachable::Int
    expanded::Bool
end

function neighbors(idx::CartesianIndex, bounds)
    candidates = [idx + CartesianIndex(1,0),
                  idx + CartesianIndex(0,1),
                  idx + CartesianIndex(-1,0),
                  idx + CartesianIndex(0,-1)]
    return filter(x -> 1 <= x[1] <= bounds[1] && 1 <= x[2] <= bounds[2],
                  candidates)
end

function expandcell(map::Array{Cell,2}, cell_idx::CartesianIndex)
    cell = map[cell_idx]
    if cell.expanded
        return
    end

    # Recursive base case
    if cell.height == 9
        cell.n_reachable = 1
        cell.expanded = true
        return
    end

    for neighbor_idx in neighbors(cell_idx, size(map))
        neighbor_cell = map[neighbor_idx]

        if neighbor_cell.height == cell.height + 1
            if !neighbor_cell.expanded
                expandcell(map, neighbor_idx)
            end
            cell.n_reachable += neighbor_cell.n_reachable
        end
    end

    cell.expanded = true
end

function main()
    map = nothing
    open("day10a_input.txt", "r") do f
        i = 1
        while ! eof(f)
            line = readline(f)
            if isnothing(map)
                map = Array{Cell,2}(undef, (length(line), length(line)))
            end

            for (j,c) in enumerate(collect(line))
                map[i,j] = Cell(parse(UInt8, c), 0, false)
            end

            i += 1
        end
    end

    trailheads = findall(x -> x.height == 0, map)
    total = 0
    for trailhead in trailheads
        expandcell(map, trailhead)
        total += map[trailhead].n_reachable
    end

    println(total[])
end

main()