inbounds(c::CartesianIndex, bounds) = 1 <= c[1] <= bounds[1] && 1 <= c[2] <= bounds[2]

function main()
    networks = Dict{Char, Vector{CartesianIndex}}()
    map_size = nothing
    open("day8a_input.txt", "r") do f
        i = 1
        line_length = nothing
        while ! eof(f)
            line = readline(f)
            line_length = length(line)

            for (j,c) in enumerate(collect(line))
                if c != '.'
                    if c ∉ keys(networks)
                        networks[c] = Vector{CartesianIndex}()
                    end

                    push!(networks[c], CartesianIndex(i,j))
                end
            end

            i += 1
        end
        map_size = (i-1, line_length)
    end

    antinodes = Set{CartesianIndex}()
    antinodes_lock = ReentrantLock()

    # For some reason, trying to thread this for-loop
    # fails with something about iterating through dicts
    for antennae in values(networks)
        for (i_antenna, v) in enumerate(antennae[1:end-1])
            for (j_antenna, w) in enumerate(antennae[i_antenna+1:end])
                antinode_1 = 2*(w - v) + v
                antinode_1 = inbounds(antinode_1, map_size) ? antinode_1 : nothing
                antinode_2 = 2*(v - w) + w
                antinode_2 = inbounds(antinode_2, map_size) ? antinode_2 : nothing
                lock(antinodes_lock) do
                    if !isnothing(antinode_1)
                        push!(antinodes, antinode_1)
                    end
                    if !isnothing(antinode_2)
                        push!(antinodes, antinode_2)
                    end
                end
            end
        end
    end

    println(length(antinodes))
end

main()