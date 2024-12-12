import qualified Data.HashSet as HashSet
import Data.Maybe (listToMaybe)
import Data.List (nub)
import Data.List (sort)

allCoordinates :: [[Char]] -> [(Int, Int)]
allCoordinates matrix = 
  [(i, j) | i <- [0 .. rows - 1], j <- [0 .. cols - 1]]
  where
    rows = length matrix
    cols = case listToMaybe matrix of
        Just x  -> length x
        Nothing -> error "Matrix is empty!"

ySize :: [[Char]] -> Int
ySize matrix = case listToMaybe matrix of
        Just x  -> length x
        Nothing -> 0

findOneAreaImpl :: [[Char]] -> (Int, Int) -> HashSet.HashSet(Int, Int) -> Char -> HashSet.HashSet(Int, Int) -> HashSet.HashSet(Int, Int)
findOneAreaImpl areaMap (x, y) visited lfc foundSoFar
    | x < 0 || y < 0 || x >= length areaMap || y >= ySize areaMap = foundSoFar
    | (areaMap !! x) !! y /= lfc = foundSoFar
    | HashSet.member (x, y) visited = foundSoFar
    | HashSet.member (x, y) foundSoFar = foundSoFar
    | otherwise = foldl (\acc (nx, ny) -> findOneAreaImpl areaMap (nx, ny) visited lfc acc)
                        updatedFound
                        neighbors
    where
        updatedFound = HashSet.insert (x, y) foundSoFar
        neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]

findOneArea :: [[Char]] -> (Int, Int) -> HashSet.HashSet(Int, Int) -> HashSet.HashSet(Int, Int)
findOneArea areaMap (x, y) visited
    | HashSet.member (x, y) visited = HashSet.empty
    | otherwise = findOneAreaImpl areaMap (x, y) visited ((areaMap !! x) !! y) HashSet.empty

findAllAreasImpl :: [[Char]] -> [(Int, Int)] -> HashSet.HashSet(Int, Int) -> [HashSet.HashSet(Int, Int)]
findAllAreasImpl _ [] _ = []
findAllAreasImpl areaMap (s: xs) visited =
    let area = findOneArea areaMap s visited
        newVisited = HashSet.union visited area
    in area : findAllAreasImpl areaMap xs newVisited

findAllAreas :: [[Char]] -> [HashSet.HashSet(Int, Int)]
findAllAreas areaMap = filter (not . HashSet.null) (findAllAreasImpl areaMap (allCoordinates areaMap) HashSet.empty)

calculateAreaScoreByArea :: HashSet.HashSet(Int, Int) -> Int
calculateAreaScoreByArea area = HashSet.size area

neighboursInAreaCount :: HashSet.HashSet(Int, Int) -> (Int, Int) -> Int
neighboursInAreaCount area (x, y) = length (filter id [
   HashSet.member (x + 1, y) area,
   HashSet.member (x - 1, y) area,
   HashSet.member (x, y + 1) area,
   HashSet.member (x, y - 1) area])

calculateAreaScoreByCirc :: HashSet.HashSet(Int, Int) -> Int
calculateAreaScoreByCirc area = sum [4 - neighboursInAreaCount area pos | pos <- HashSet.toList area]

calculateAreaScore :: HashSet.HashSet(Int, Int) -> Int
calculateAreaScore area = calculateAreaScoreByArea area * calculateAreaScoreByCirc area

calculateAreasScore :: [HashSet.HashSet(Int, Int)] -> Int
calculateAreasScore areas = sum [calculateAreaScore area | area <- areas]

countGroups :: [Int] -> Int
countGroups [] = 0
countGroups [_] = 1
countGroups (x1:x2:xs) = (if x2 - x1 > 1 then 1 else 0) + countGroups (x2:xs)


sidesUsed :: ((Int, Int) -> Int) -> HashSet.HashSet(Int, Int) -> [Int]
sidesUsed dir area = nub $ (map dir (HashSet.toList area))

wallsIdsOfElIds :: [Int] -> [Int]
wallsIdsOfElIds xs = nub $ concatMap (\x -> [x, x + 1]) xs

wallsUsed :: ((Int, Int) -> Int) -> HashSet.HashSet(Int, Int) -> [Int]
wallsUsed dir area = wallsIdsOfElIds $ sidesUsed dir area

elInElId :: (Int, Int) -> HashSet.HashSet(Int, Int) -> Int -> [(Int, Int)]
elInElId (dx, dy) area elOrderId = filter (\(x, y) -> (x * dx, y * dy) == (dx * elOrderId, dy * elOrderId)) (HashSet.toList area)

oppositeDelta :: (Int, Int) -> (Int, Int)
oppositeDelta (1, 0) = (0, 1)
oppositeDelta (0, 1) = (1, 0)
oppositeDelta _ = (0, 0)

oppositeDir :: (Int, Int) -> ((Int, Int) -> Int)
oppositeDir (1, 0) = snd
oppositeDir (0, 1) = fst
oppositeDir _ = fst

withNoMaching :: (Int, Int) -> [(Int, Int)] -> [(Int, Int)] -> [(Int, Int)]
withNoMaching (dx, dy) lhs rhs = filter(\(x,y) -> not (HashSet.member (x * opDx, y * opDy) rhsSet)) lhs
    where
        (opDx, opDy) = oppositeDelta (dx, dy)
        rhsSet = HashSet.fromList $ map (\(x, y) -> (x * opDx, y * opDy)) rhs

groupsOnWall :: (Int, Int) -> HashSet.HashSet(Int, Int) -> Int -> Int
groupsOnWall delta area wallId = countGroups (sort $ map (oppositeDir delta) (withNoMaching delta under over)) +
                                 countGroups (sort $ map (oppositeDir delta) (withNoMaching delta over under))
    where
        under = elInElId delta area wallId
        over = elInElId delta area (wallId - 1)


sideScoreInDir :: ((Int, Int) -> Int) -> (Int, Int) -> HashSet.HashSet(Int, Int) -> Int
sideScoreInDir dir delta area = sum $ map (\wallId -> (groupsOnWall delta area wallId)) (wallsUsed dir area)

calculateAreaScoreBySides :: HashSet.HashSet(Int, Int) -> Int
calculateAreaScoreBySides area = (sideScoreInDir fst (1, 0) area)  + (sideScoreInDir snd (0, 1) area)

calculateDiscountedAreaScore :: HashSet.HashSet(Int, Int) -> Int
calculateDiscountedAreaScore area = calculateAreaScoreBySides area * calculateAreaScoreByArea area

calculateDiscountedAreasScore :: [HashSet.HashSet(Int, Int)] -> Int
calculateDiscountedAreasScore areas = sum [calculateDiscountedAreaScore area | area <- areas]

solve1 :: String -> Int
solve1 = calculateAreasScore . findAllAreas . lines

solve2 :: String -> Int
solve2 = calculateDiscountedAreasScore . findAllAreas . lines

main :: IO ()
main = do
    input <- readFile "input.txt"
    putStrLn ("Part 1: " ++ show (solve1 input))
    putStrLn ("Part 2: " ++ show (solve2 input))
