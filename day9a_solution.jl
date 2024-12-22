function main()
    diskmap = nothing
    open("day9a_input.txt", "r") do f
        while ! eof(f)
            diskmap = parse.(Int, split(readline(f), ""))
        end
    end

    # Strategy: iterate the disk map bi-directionally,
    #           computing the checksum from the left and filling
    #           in free space from the right as we go.
    left_dense_idx = 1 # Current 1-indexed location of the checksum pointer in the dense disk map
    left_sparse_idx = 0 # Current 0-indexed location of the checksum pointer in the sparse disk map
    # Current location of the fill pointer in the dense disk map
    right_dense_idx = length(diskmap) % 2 == 0 ? length(diskmap) - 1 : length(diskmap)
    # Computes the file ID of an index in the dense disk map; nothing if free space
    fileid(idx::Integer) = idx % 2 == 1 ? (idx - 1) ÷ 2 : nothing

    # When the checksum pointer passes the fill pointer,
    # we know everything remaining is free space
    checksum = 0
    while left_dense_idx < right_dense_idx
        curr_fileid = fileid(left_dense_idx)

        # If the checksum pointer is at a file block, add to the checksum using
        # the current file ID and getting the sparse indices in the block
        if !isnothing(curr_fileid)
            checksum += sum(curr_fileid .* (collect(0:diskmap[left_dense_idx]-1) .+ left_sparse_idx))
            left_sparse_idx += diskmap[left_dense_idx]
            diskmap[left_dense_idx] = 0
            left_dense_idx += 1
        # Otherwise, fill from the fill pointer
        else
            while diskmap[left_dense_idx] > 0
                n_fill = min(diskmap[left_dense_idx], diskmap[right_dense_idx])
                checksum += sum(fileid(right_dense_idx) .* (collect(0:n_fill-1) .+ left_sparse_idx))
                left_sparse_idx += n_fill
                diskmap[left_dense_idx] -= n_fill
                diskmap[right_dense_idx] -= n_fill
                # If we finish the current fill file,
                # move the fill pointer to the next file (two blocks left)
                if diskmap[right_dense_idx] <= 0
                    right_dense_idx -= 2
                end
            end
            left_dense_idx += 1
        end
    end

    println(checksum)
end

main()