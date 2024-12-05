using DelimitedFiles

function main()
    data = readdlm("day1a_input.txt", Int)
    l1 = sort(data[:,1])
    l2 = sort(data[:,2])
    println(sum(abs.(l1 - l2)))
end

main()