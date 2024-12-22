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

mutable struct Guard
    loc::CartesianIndex
    dir::Direction
end

# State machine logic for the guard
function step_guard!(map::AbstractArray{CellType,2}, guard::Guard, visit_map::AbstractArray{Bool})
    i = guard.loc[1]
    j = guard.loc[2]

    if i < 1 || i > size(map)[1] || j < 1 || j > size(map)[1]
        return true
    end

    if guard.dir == DIR_DOWN
        if i == size(map)[1]
            return true
        end

        if map[i+1,j] == CELL_OBSTACLE
            guard.dir = DIR_LEFT
        else
            guard.loc += CartesianIndex(1,0)
        end
    elseif guard.dir == DIR_RIGHT
        if j == size(map)[2]
            return true
        end

        if map[i,j+1] == CELL_OBSTACLE
            guard.dir = DIR_DOWN
        else
            guard.loc += CartesianIndex(0,1)
        end
    elseif guard.dir == DIR_UP
        if i == 1
            return true
        end

        if map[i-1,j] == CELL_OBSTACLE
            guard.dir = DIR_RIGHT
        else
            guard.loc += CartesianIndex(-1,0)
        end
    elseif guard.dir == DIR_LEFT
        if j == 1
            return true
        end

        if map[i,j-1] == CELL_OBSTACLE
            guard.dir = DIR_UP
        else
            guard.loc += CartesianIndex(0,-1)
        end
    end

    visit_map[guard.loc] = true
    return false
end

function main()
    map = nothing
    visit_map = nothing
    guard = nothing
    open("day6a_input.txt", "r") do f
        i = 1
        while ! eof(f)
            line = readline(f)
            if isnothing(map)
                map = Array{CellType,2}(undef, (length(line), length(line)))
                visit_map = zeros(Bool, size(map))
            end

            for (j,c) in enumerate(collect(line))
                if c == '.'
                    map[i,j] = CELL_FREE
                elseif c == '#'
                    map[i,j] = CELL_OBSTACLE
                elseif c == 'v'
                    guard = Guard(CartesianIndex(i,j), DIR_DOWN)
                    map[i,j] = CELL_FREE
                elseif c == '>'
                    guard = Guard(CartesianIndex(i,j), DIR_RIGHT)
                    map[i,j] = CELL_FREE
                elseif c == '^'
                    guard = Guard(CartesianIndex(i,j), DIR_UP)
                    map[i,j] = CELL_FREE
                elseif c == '<'
                    guard = Guard(CartesianIndex(i,j), DIR_LEFT)
                    map[i,j] = CELL_FREE
                else
                    map[i,j] = CELL_FREE
                end
            end

            i += 1
        end
    end

    visit_map[guard.loc] = true
    while !step_guard!(map, guard, visit_map)
    end

    println(sum(visit_map))
end

main()