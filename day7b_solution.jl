concat(v1::Integer, v2::Integer) = parse(typeof(v1), repr(v1) * repr(v2))

function check_calibration(target::Integer, values::Vector{<:Integer})
    # It was awkward trying to do DP here because the values are changing
    # from the concat operator and using a full vector of values as the key
    # to a cache entry is weird.

    # Recursive base case
    if length(values) == 1
        solvable = target == values[1]
        return solvable
    end

    add_valid = values[1] + values[2] <= target
    mul_valid = values[1] * values[2] <= target
    cat_valid = concat(values[1], values[2]) <= target

    solvable = false
    # Concatenation isn't commutative, so we can't cheat like before 😢
    if add_valid
        solvable |= check_calibration(target,
                                      [[values[1] + values[2]]; values[3:end]])
    end
    if mul_valid
        solvable |= check_calibration(target,
                                      [[values[1] * values[2]]; values[3:end]])
    end
    if cat_valid
        solvable |= check_calibration(target,
                                      [[concat(values[1], values[2])]; values[3:end]])
    end

    return solvable
end

function main()
    total = 0
    open("day7b_input.txt", "r") do f
        while ! eof(f)
            line = readline(f)
            split_string = split(line, ':')
            target = parse(BigInt, split_string[1])
            values = parse.(BigInt, split(split_string[2]))
            if check_calibration(target, values)
                total += target
            end
        end
    end

    if total < 6231007345478
        println("YOYO")
    end

    println(total)
end

main()