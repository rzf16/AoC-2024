# Filters for each configuration of MAS to be "slid" across the data.
# I kept them all to 3x3 squares so that they
# can be compared against the same snippet;
# that ended up not mattering because of my
# threaded implementation, but still natural IMO.
# These should definitely be auto-generated, though.
filters = [
    ['M' '\0' '\0';
     '\0' 'A' '\0';
     '\0' '\0' 'S'
    ],

    ['S' '\0' '\0';
     '\0' 'A' '\0';
     '\0' '\0' 'M'
    ],

    ['\0' '\0' 'M';
     '\0' 'A' '\0';
     'S' '\0' '\0'
    ],

    ['\0' '\0' 'S';
     '\0' 'A' '\0';
     'M' '\0' '\0'
    ],
]

# The row and column stride for each filter.
strides = [(1,1), (1,1), (1,1), (1,1)]

# How to identify matches for each filter.
@enum Reduction begin
    REDUCE_DIAG_RIGHT_UP # The diagonal from bottom-left to upper-right must match
    REDUCE_DIAG_RIGHT_DOWN # The diagonal from upper-left to bottom-right must match
end

reductions = [REDUCE_DIAG_RIGHT_DOWN, REDUCE_DIAG_RIGHT_DOWN,
              REDUCE_DIAG_RIGHT_UP, REDUCE_DIAG_RIGHT_UP]

function main()
    data = nothing
    open("day4b_input.txt", "r") do f
        while ! eof(f)
            line = readline(f)
            if isnothing(data)
                data = Array{Char,2}(undef, (1,length(line)))
                data[1,:] = collect(line)
            else
                data = [data; reshape(collect(line), (1,length(line)))]
            end
        end
    end

    # We need both right-down and right-up to complete an X
    # Track those separately and AND them at the end
    filter_hits_right_down = falses(size(data))
    filter_hits_right_down_lock = ReentrantLock()
    filter_hits_right_up = falses(size(data))
    filter_hits_right_up_lock = ReentrantLock()

    # Pretty happy I did it convolution-style now, very easy to swap out the filters :D
    Threads.@threads for i in eachindex(filters)
        filter = filters[i]
        stride = strides[i]
        reduction = reductions[i]
        filter_center_offset = ((size(filter,1)-1) ÷ 2, (size(filter,2)-1) ÷ 2)

        row = 1
        col = 1
        while row <= size(data,1) - size(filter,1) + 1
            while col <= size(data, 2) - size(filter,2) + 1
                elem_matches = data[row:row+size(filter,1)-1, col:col+size(filter,2)-1] .== filter

                # Reduce dimensions
                if reduction == REDUCE_DIAG_RIGHT_DOWN
                    hit = all([elem_matches[i,i]
                        for i in 1:min(size(filter,1), size(filter,2))])
                    # OR similar filters together; either one works to create an X!
                    lock(filter_hits_right_down_lock) do
                        filter_hits_right_down[row+filter_center_offset[1], col+filter_center_offset[2]] |= hit
                    end
                elseif reduction == REDUCE_DIAG_RIGHT_UP
                    hit = all([elem_matches[i,size(filter,2)-i+1]
                        for i in 1:min(size(filter,1), size(filter,2))])
                    # OR similar filters together; either one works to create an X!
                    lock(filter_hits_right_up_lock) do
                        filter_hits_right_up[row+filter_center_offset[1], col+filter_center_offset[2]] |= hit
                    end
                end

                col += stride[2]
            end

            row += stride[1]
            col = 1
        end
    end

    println(sum(filter_hits_right_down .& filter_hits_right_up))
end

main()