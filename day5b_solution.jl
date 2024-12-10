include("util/graph/GraphUtils.jl")
using .GraphUtils

function checkupdate(rules::AbstractGraph{<:Integer}, update::Vector{<:Integer})
    # Because the relationship is transitive (A->B and B->C implies A->C),
    # we should make our graph transitive to save time when checking updates.
    # That way, we can check a vertex directly for the rules implied by its connected vertices
    # instead of traversing the graph.
    # However, this is only true locally, as I found out the hard way - the overall dependency
    # graph is actually cyclical 😑
    # So, we need to take the subgraph that applies to this update and compute that closure.
    rule_pages = filter(x -> hasvertex(rules, x), update)
    local_rules = transitive_closure(subgraph(rules, rule_pages))

    # We iterate through the update in reverse, comparing the set of
    # pages that must come after the current page to the set of unchecked
    # pages preceding it. We need not check the pages after,
    # since, if some later page should've come before the current page,
    # that later page would've already been iterated through and
    # the mistake caught by the check against its successors.
    # That is, if a page p comes before a page q in the update,
    # and if there were a rule that p must come after q (q->p),
    # we would have encountered that discrepancy when
    # checking page q earlier.
    unchecked_set = Set{Int}(update)
    for page in Iterators.reverse(update)
        pop!(unchecked_set, page)

        if hasvertex(local_rules, page)
            after_list = successors(local_rules, page)
            if !isempty(unchecked_set ∩ Set{Int}(after_list))
                return false
            end
        end
    end

    return true
end

function fixupdate!(rules::AbstractGraph{<:Integer}, update::Vector{<:Integer})
    rule_pages = filter(x -> hasvertex(rules, x), update)
    rule_page_indices = findall(x -> hasvertex(rules, x), update)
    local_rules = transitive_closure(subgraph(rules, rule_pages))

    # Pretty simple solution: use the topological sort of the graph to get who has priority!
    page_topo = topological_sort(local_rules)
    for (i, page) in zip(rule_page_indices, page_topo)
        update[i] = page
    end

    return update[ceil(Int, length(update)/2)]
end

function main()
    # Represent the rules as a graph, where A->B implies that A must come before B.
    # There are 1176 rules (edges) which reference 49 pages (vertices), so we use a dense graph
    # backed by an adjacency matrix.
    rules = DenseDiGraph{Int}()

    reading_rules = true
    total = 0
    open("day5b_input.txt", "r") do f
        while ! eof(f)
            line = readline(f)

            if reading_rules
                if isempty(line)
                    reading_rules = false
                else
                    split_string = split(line, '|')
                    before = parse(Int, split_string[1])
                    after = parse(Int, split_string[2])
                    addedge!(rules, before, after)
                end
            else
                split_string = split(line, ',')
                update = parse.(Int, split_string)
                if !checkupdate(rules, update)
                    total += fixupdate!(rules, update)
                end
            end
        end
    end

    println(total)
end

main()