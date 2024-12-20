<?php

function buildMap($map) {
    $mapSizeX = count($map);
    $mapSizeY = count($map[0]);

    $charAntenas = [];
    // build hash map of character to all coords it appears on
    for ($i = 0; $i < $mapSizeX; $i++) {
        for ($j = 0; $j < $mapSizeY; $j++) {
            $c = $map[$i][$j];
            if ($c != '.') {
                $antenasSoFar = $charAntenas[$c] ?? [];
                $antenasSoFar[] = [$i, $j];
                $charAntenas[$c] = $antenasSoFar;
            }
        }
    }

    return $charAntenas;
}

function isInMap($map, $pos) {
    return $pos[0] >= 0 && $pos[1] >= 0 && $pos[0] < count($map) && $pos[1] < count($map[0]);
}

function antinodesOfPair($map, $pair) {
    $x1 = $pair[0][0];
    $x2 = $pair[1][0];
    $y1 = $pair[0][1];
    $y2 = $pair[1][1];

    $xd = $x2 - $x1;
    $yd = $y2 - $y1;

    return array_filter(
        [[$x1 - $xd, $y1 - $yd], [$x2 + $xd, $y2 + $yd]],
        fn($candidate) => isInMap($map, $candidate)
    );
}

function antinodesOf($map, $positions) {
    $allAntinodes = [];
    for ($i = 0; $i < count($positions) - 1; $i++) {
        for ($j = $i + 1; $j < count($positions); $j++) {
            $antinodes = antinodesOfPair($map, [$positions[$i], $positions[$j]]);     
            $allAntinodes = array_merge($allAntinodes, $antinodes);
        }
    }
    return $allAntinodes;
}


$file = new SplFileObject('input.txt');
$charMatrix = [];

while (!$file->eof()) {
    $line = $file->fgets();
    if ($line != "") {
        $charMatrix[] = str_split(rtrim($line, "\r\n"));
    }
}

$file = null;


$antenas = buildMap($charMatrix);

$antinodes = [];
foreach ($antenas as $antena => $positions) {
    $antinodes = array_merge($antinodes, antinodesOf($charMatrix, $positions));
}

function asString($node) {
    return "$node[0],$node[1]";
}

sort($antinodes);

$asText = array_map(fn($node) => asString($node), $antinodes);
$uniqCnt = count(array_unique($asText));
echo "Count is: $uniqCnt\n";

?>