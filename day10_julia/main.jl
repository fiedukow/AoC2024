matrix = [collect(chomp(line)) for line in eachline("input.txt")]
matrix = map(row -> map(x -> Int(x) - Int('0'), row), matrix)

function inBound(pos, map)
    pos[1] > 0 && pos[2] > 0 && pos[1] <= size(map)[1] && pos[2] <= size(map[1])[1]
end

function endPoints(startingAt, fromPos, map)
    if !inBound(fromPos, map)
        return []
    end

    startingPointVal = map[fromPos[1]][fromPos[2]]
    if startingPointVal != startingAt
        return []
    end

    if startingPointVal == 9
        return [fromPos]
    end

    vcat(
        endPoints(startingAt + 1, (fromPos[1] + 1, fromPos[2])    , map),
        endPoints(startingAt + 1, (fromPos[1] - 1, fromPos[2])    , map),
        endPoints(startingAt + 1, (fromPos[1],     fromPos[2] + 1), map),
        endPoints(startingAt + 1, (fromPos[1],     fromPos[2] - 1), map)
    )
end

function scoreFor(map, onlyUnique = true)
    sum = 0
    for i in eachindex(matrix)
        for j in eachindex(matrix[i])
            paths = endPoints(0, (i, j), map)
            if onlyUnique
                paths = unique(paths)
            end
            sum += size(paths)[1]
        end
    end
    return sum
end

print("$(scoreFor(matrix, false))\n")
