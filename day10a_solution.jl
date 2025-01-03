mutable struct Cell
    height::UInt8
    reachable_set::Set{CartesianIndex}
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
        push!(cell.reachable_set, cell_idx)
        cell.expanded = true
        return
    end

    for neighbor_idx in neighbors(cell_idx, size(map))
        neighbor_cell = map[neighbor_idx]

        if neighbor_cell.height == cell.height + 1
            if !neighbor_cell.expanded
                expandcell(map, neighbor_idx)
            end
            union!(cell.reachable_set, neighbor_cell.reachable_set)
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
                map[i,j] = Cell(parse(UInt8, c), Set{CartesianIndex}(), false)
            end

            i += 1
        end
    end

    trailheads = findall(x -> x.height == 0, map)
    total = 0
    for trailhead in trailheads
        expandcell(map, trailhead)
        total += length(map[trailhead].reachable_set)
    end

    println(total)
end

main()