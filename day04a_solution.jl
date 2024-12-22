# Filters for each configuration of XMAS to be "slid" across the data.
# I kept them all to 4x4 squares so that they
# can be compared against the same snippet;
# that ended up not mattering because of my
# threaded implementation, but still natural IMO.
# These should definitely be auto-generated, though.
filters = [
    ['X' 'M' 'A' 'S';
     'X' 'M' 'A' 'S';
     'X' 'M' 'A' 'S';
     'X' 'M' 'A' 'S';
    ],

    ['S' 'A' 'M' 'X';
     'S' 'A' 'M' 'X';
     'S' 'A' 'M' 'X';
     'S' 'A' 'M' 'X'
    ],

    ['X' 'X' 'X' 'X';
     'M' 'M' 'M' 'M';
     'A' 'A' 'A' 'A';
     'S' 'S' 'S' 'S'
    ],

    ['S' 'S' 'S' 'S';
     'A' 'A' 'A' 'A';
     'M' 'M' 'M' 'M';
     'X' 'X' 'X' 'X';
    ],

    ['X' '\0' '\0' '\0';
     '\0' 'M' '\0' '\0';
     '\0' '\0' 'A' '\0';
     '\0' '\0' '\0' 'S'
    ],

    ['S' '\0' '\0' '\0';
     '\0' 'A' '\0' '\0';
     '\0' '\0' 'M' '\0';
     '\0' '\0' '\0' 'X'
    ],

    ['\0' '\0' '\0' 'X';
     '\0' '\0' 'M' '\0';
     '\0' 'A' '\0' '\0';
     'S' '\0' '\0' '\0'
    ],

    ['\0' '\0' '\0' 'S';
     '\0' '\0' 'A' '\0';
     '\0' 'M' '\0' '\0';
     'X' '\0' '\0' '\0'
    ]
]

# The row and column stride for each filter.
# For instance, the first filter checks four rows at once for XMAS,
# so there's no point in only stepping down one row. Instead,
# we can step down four rows. However, we still need to step one
# column at a time.
strides = [(4,1), (4,1), (1,4), (1,4), (1,1), (1,1), (1,1), (1,1)]

# How to identify matches for each filter.
@enum Reduction begin
    REDUCE_COL # All values in a column must match
    REDUCE_ROW # All values in a row must match
    REDUCE_DIAG_RIGHT_UP # The diagonal from bottom-left to upper-right must match
    REDUCE_DIAG_RIGHT_DOWN # The diagonal from upper-left to bottom-right must match
end

reductions = [REDUCE_ROW, REDUCE_ROW, REDUCE_COL, REDUCE_COL,
              REDUCE_DIAG_RIGHT_DOWN, REDUCE_DIAG_RIGHT_DOWN,
              REDUCE_DIAG_RIGHT_UP, REDUCE_DIAG_RIGHT_UP]

function main()
    data = nothing
    open("day4a_input.txt", "r") do f
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

    n_matches = Threads.Atomic{Int}(0)
    # Surely there's a better algorithmic solution than this brute force
    # filter search, but can't think of one at 1AM
    Threads.@threads for i in eachindex(filters)
        filter = filters[i]
        stride = strides[i]
        reduction = reductions[i]

        row = 1
        col = 1
        while row <= size(data,1) - size(filter,1) + 1
            while col <= size(data, 2) - size(filter,2) + 1
                elem_matches = data[row:row+size(filter,1)-1, col:col+size(filter,2)-1] .== filter

                # Reduce dimensions
                if reduction == REDUCE_COL
                    n_new_matches = sum(all.(eachcol(elem_matches)))
                elseif reduction == REDUCE_ROW
                    n_new_matches = sum(all.(eachrow(elem_matches)))
                elseif reduction == REDUCE_DIAG_RIGHT_DOWN
                    n_new_matches = all([elem_matches[i,i]
                        for i in 1:min(size(filter,1), size(filter,2))]) ? 1 : 0
                elseif reduction == REDUCE_DIAG_RIGHT_UP
                    n_new_matches = all([elem_matches[i,size(filter,2)-i+1]
                        for i in 1:min(size(filter,1), size(filter,2))]) ? 1 : 0
                end
                Threads.atomic_add!(n_matches, n_new_matches)

                col += stride[2]
            end

            row += stride[1]
            col = 1
        end
    end

    println(n_matches[])
end

main()