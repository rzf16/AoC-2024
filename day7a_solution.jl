function check_calibration(target::Integer, values::Vector{<:Integer},
                           cache::Dict{<:Tuple{Integer,Integer}, Bool})
    # Check if we've seen this combination of inputs before
    # We can just cache the length of the values rather than the values themselves,
    # since we are always slicing off the end and never changing the values.
    if (target, length(values)) in keys(cache)
        return cache[target, length(values)]
    end

    # Recursive base case
    if length(values) == 1
        solvable = target == values[1]
        cache[(target, 1)] = solvable
        return solvable
    end

    add_valid = target - values[end] > 0
    mul_valid = target % values[end] == 0

    # Because we evaluate left to right, the last value is the one we can pop off.
    if add_valid && mul_valid
        solvable = check_calibration(target - values[end], values[1:end-1], cache) ||
                   check_calibration(target ÷ values[end], values[1:end-1], cache)
    elseif add_valid
        solvable = check_calibration(target - values[end], values[1:end-1], cache)
    elseif mul_valid
        solvable = check_calibration(target ÷ values[end], values[1:end-1], cache)
    else
        solvable = false
    end

    cache[(target, length(values))] = solvable
    return solvable
end

function main()
    total = 0
    open("day7a_input.txt", "r") do f
        while ! eof(f)
            line = readline(f)
            split_string = split(line, ':')
            target = parse(BigInt, split_string[1])
            values = parse.(BigInt, split(split_string[2]))
            if check_calibration(target, values, Dict{Tuple{BigInt, Int}, Bool}())
                total += target
            end
        end
    end

    println(total)
end

main()