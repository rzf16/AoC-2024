using DelimitedFiles

function main()
    data = readdlm("day1b_input.txt", Int)

    # Naive linear search for each number is O(n^2)
    # Instead, let's try to do better with sorting!

    # First, sort both lists: O(nlogn)
    l1 = sort(data[:,1])
    l2 = sort(data[:,2])

    # Now, we keep track of a few numbers for our iteration
    prev_l1_num = nothing # Previous l1 number to cache a repeat
    prev_score = 0 # Previous score to cache a repeat
    curr_l2_index = 1 # Current index on l2;
                      # we don't need to search before this index since the lists are sorted!

    # Iterate over the numbers in l1 and look for them in l2
    # At worst a binary search per number: O(nlogn)
    total_score = 0
    for l1_num in l1
        # If the l1 number is greater than the largest l2 number, just exit
        if l1_num > l2[end]
            break
        # If we have a repeat, just use the cached score
        # I considered a lookahead search on l1 to get all the repeats in one go, but
        # I think those are miniscule gains? Still linear iteration, just swapping out a few additions
        # for a multiplication 
        elseif l1_num == prev_l1_num
            total_score += prev_score
        # No point in even looking if the next number in l2 is larger
        elseif l2[curr_l2_index] > l1_num
            prev_l1_num = l1_num
            prev_score = 0
        # Get the range of matching values if we can't use the cache or cheat skip
        else
            matches = searchsorted(l2[curr_l2_index:end], l1_num)

            # Compute the score
            prev_l1_num = l1_num
            if isempty(matches)
                prev_score = 0
            else
                prev_score = l1_num * length(matches)
                total_score += prev_score
            end

            # At this point, we can set the l2 index to the first l2 number greater than the l1 number
            # We would have already encountered any number less than that,
            # and we'll just use the cache if equal
            curr_l2_index = searchsortedfirst(l2[curr_l2_index:end], l1_num, lt=((x, y) -> x <= y))

            # Unfortunately, we can't just exit here if no value of l2 is <= l1_num,
            # since we still need to handle repeats
        end
    end

    println(total_score)
end

main()