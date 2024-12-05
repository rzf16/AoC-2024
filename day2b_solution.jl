function issafe(report)
    if !issorted(report) && !issorted(report, rev=true)
        return false
    else
        cumdiff = abs.(report[2:length(report)] - report[1:length(report)-1])
        return all(x -> 1 <= x <= 3, cumdiff)
    end
end

function issafedampened(report)
    # Lazy ahh solution - just thread this for-loop instead of doing anything smart at all 🗿
    # My excuse is that "I am using this to learn threading in Julia" 👍
    n_safe = Threads.Atomic{Int}(0)
    Threads.@threads for i in eachindex(report)
        if issafe(deleteat!(deepcopy(report), i))
            Threads.atomic_add!(n_safe, 1)
        end
    end

    return n_safe[] > 0
end

function main()
    # Each report may have a variable number of levels,
    # so let's just do this line-by-line
    # Slightly sad I couldn't abuse Julia vectorization 😢
    n_safe = 0
    open("day2b_input.txt", "r") do f
        while ! eof(f)
            report = parse.(Int32, split(readline(f), ' '))
            if issafedampened(report)
                n_safe += 1
            end
        end
    end

    println(n_safe)
end

main()