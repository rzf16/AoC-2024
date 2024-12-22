mutable struct DataBlock
    address::Int
    size::Int
    fileid::Int
    processed::Bool
end

function main()
    diskmap = Vector{DataBlock}()
    open("day9b_input.txt", "r") do f
        while ! eof(f)
            blocks = parse.(Int, split(readline(f), ""))
            address = 0
            for (i,b) in enumerate(blocks)
                push!(diskmap, DataBlock(address, b, i % 2 == 0 ? -1 : (i-1)÷2, false))
                address += b
            end
        end
    end

    # Strategy: iterate the disk map bi-directionally,
    #           filling files from the right and
    #           searching for the first available space from the left,
    #           computing the checksum along the way
    left_dense_idx = 1 # Current location of the checksum pointer in the dense disk map;
                       # Everything before this index is fully filled and accounted for
    right_dense_idx = length(diskmap) # Current location of the fill pointer in the dense disk map

    checksum = 0
    while right_dense_idx >= left_dense_idx
        curr_block = diskmap[right_dense_idx]

        if curr_block.fileid < 0 || curr_block.processed
            curr_block.processed = true
            right_dense_idx -= 1
            continue
        end

        # Find the first free space that can accommodate this file
        free_block_found = false
        for (i_block, block) in enumerate(diskmap[left_dense_idx:right_dense_idx-1])
            i_block += left_dense_idx - 1
            # If the block is free and can fit this file,
            # put this file there and process it
            if block.fileid < 0 && block.size >= curr_block.size
                free_block_found = true

                # If this block is larger, add another block of free space afterwards
                if block.size > curr_block.size
                    insert!(diskmap, i_block+1,
                            DataBlock(block.address + curr_block.size,
                                      block.size - curr_block.size,
                                      -1, false))
                end

                # Move the file to the new data block
                block.size = curr_block.size
                block.fileid = curr_block.fileid
                curr_block.fileid = -1
                # Since files can only move left and we started at the right,
                # this block won't be relevant again, so mark it processed.
                curr_block.processed = true

                # Compute the checksum, since this file can't move again
                checksum += sum(block.fileid .* (collect(0:block.size-1) .+ block.address))
                block.processed = true

                right_dense_idx -= 1
                break

            # If the block is free but can't fit this file,
            # mark that we found a free block to stop incrementing the left pointer
            elseif block.fileid < 0
                free_block_found = true

            # If we still haven't seen a free block, we can go ahead and
            # increment the left pointer to reduce the search space
            elseif !free_block_found
                if !block.processed
                    checksum += sum(block.fileid .* (collect(0:block.size-1) .+ block.address))
                    block.processed = true
                end

                left_dense_idx += 1
            end
        end

        # If we didn't manage to find a free space for this file,
        # we can process it an move on
        if !curr_block.processed
            checksum += sum(curr_block.fileid .* (collect(0:curr_block.size-1) .+ curr_block.address))
            curr_block.processed = true
            right_dense_idx -= 1
        end
    end

    println(checksum)
end

main()