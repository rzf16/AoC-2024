const mul_regex = r"mul\((\d{1,3}),(\d{1,3})\)"

function main()
    total = 0
    open("day3a_input.txt", "r") do f
        while ! eof(f)
            line = readline(f)
            mul_match = match(mul_regex, line)
            while !isnothing(mul_match)
                total += parse(Int, mul_match.captures[1]) * parse(Int, mul_match.captures[2])
                if mul_match.offset+length(mul_match.match) > length(line)
                    break
                else
                    mul_match = match(mul_regex, line, mul_match.offset+length(mul_match.match))
                end
            end
        end
    end

    println(total)
end

main()