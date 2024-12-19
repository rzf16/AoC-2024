inbounds(c::CartesianIndex, bounds) = 1 <= c[1] <= bounds[1] && 1 <= c[2] <= bounds[2]

function main()
    networks = Dict{Char, Vector{CartesianIndex}}()
    map_size = nothing
    open("day8b_input.txt", "r") do f
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
                new_antinodes = Set{CartesianIndex}()
                diff = w - v
                factor = gcd(diff[1], diff[2])
                step = CartesianIndex(diff[1] ÷ factor, diff[2] ÷ factor)

                # Step in both directions until off the map
                curr = v
                while inbounds(curr, map_size)
                    push!(new_antinodes, curr)
                    curr = curr + step
                end
                curr = v
                while inbounds(curr, map_size)
                    push!(new_antinodes, curr)
                    curr = curr - step
                end

                lock(antinodes_lock) do
                    union!(antinodes, new_antinodes)
                end
            end
        end
    end

    println(length(antinodes))
end

main()