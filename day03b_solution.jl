const mul_regex = r"mul\((\d{1,3}),(\d{1,3})\)"
const dont_regex = r"don't\(\)"
const do_regex = r"do\(\)"

enabled = true
total = 0

function execute_enabled(line::String, index::Int)
    global total
    global enabled

    mul_match = match(mul_regex, line, index)
    dont_match = match(dont_regex, line, index)

    mul_index = !isnothing(mul_match) ? mul_match.offset : Inf
    dont_index = !isnothing(dont_match) ? dont_match.offset : Inf

    if mul_index < dont_index
        # mul happends before dont; only process the mul
        total += parse(Int, mul_match.captures[1]) * parse(Int, mul_match.captures[2])
        return mul_index + length(mul_match.match)
    elseif dont_index < mul_index
        # dont happens before mul; only process the dont
        enabled = false
        return dont_index + length(dont_match.match)
    else
        return length(line)+1 # No relevant matches left in the line - go next!
    end
end

function execute_disabled(line::String, index::Int)
    global enabled

    # When disabled, we only care about the next do command
    do_match = match(do_regex, line, index)
    if !isnothing(do_match)
        enabled = true
        return do_match.offset + length(do_match.match)
    else
        return length(line)+1 # No relevant matches left in the line - go next!
    end
end

function main()
    open("day3a_input.txt", "r") do f
        while ! eof(f)
            line = readline(f)
            index = 1
            while index <= length(line)
                if enabled
                    index = execute_enabled(line, index)
                else
                    index = execute_disabled(line, index)
                end
            end
        end
    end

    println(total)
end

main()