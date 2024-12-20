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
    // print_r($pos);
    return $pos[0] >= 0 && $pos[1] >= 0 && $pos[0] < count($map) && $pos[1] < count($map[0]);
}

function gcf($a, $b) {
    if ($b == 0) return $a; 
    return gcf($b, $a % $b);
}

function mulVec($vec, $m) {
    return [$vec[0] * $m, $vec[1] * $m];
}

function addVec($v1, $v2) {
    return [$v1[0] + $v2[0], $v1[1] + $v2[1]];
}

function negVec($v) {
    return [-$v[0], -$v[1]];
}

function antinodesOfPair($map, $pair) {
    $x1 = $pair[0][0];
    $x2 = $pair[1][0];
    $y1 = $pair[0][1];
    $y2 = $pair[1][1];

    $xd = $x2 - $x1;
    $yd = $y2 - $y1;

    $gcf_d = gcf(abs($xd), abs($yd));
    if ($gcf_d > 1) {
        print("GCF $gcf_d\n");
    }
    $xd = $xd / $gcf_d;
    $yd = $yd / $gcf_d;

    print("$xd / $yd\n");

    $v1 = [$x1, $y1];
    $v2 = [$x2, $y2];
    $vd = [$xd, $yd];

    $retval = [];
    $candidate = $v1;
    while (isInMap($map, $candidate)) {
        $retval[] = $candidate;
        $candidate = addVec($candidate, negVec($vd));
    }
    while (isInMap($map, $candidate)) {
        $retval[] = $candidate;
        $candidate = addVec($candidate, negVec($vd));
    }
    $candidate = $v1;
    while (isInMap($map, $candidate)) {
        $retval[] = $candidate;
        $candidate = addVec($candidate, $vd);
    }
    return $retval;
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
print_r($asText);
echo "Count is: $uniqCnt\n";

?>