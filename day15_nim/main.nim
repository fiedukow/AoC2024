import os
import options

type
  Element = enum
    Wall = '#', Floor = '.', Robot = '@', Box = 'O'

type
  Dir = enum
    Left = '<', Right = '>', Up = '^', Down = 'v'

type
  Gameplay = object
    map: seq[seq[Element]]
    robotPos: (int, int)

proc newGameplay(map: seq[seq[Element]]): Gameplay =
  var myMap = map
  var robotPos = (0, 0)
  for i, value in myMap.pairs:
    for j, elem in value:
      if myMap[i][j] == Robot:
        robotPos = (i, j)
        myMap[i][j] = Floor

  Gameplay(map: myMap, robotPos: robotPos)

proc print(self: Gameplay) =
  for i, row in self.map.pairs:
    for j, col in row.pairs:
      if (i, j) == self.robotPos:
        stdout.write('@')
      else:
        stdout.write(cast[char](col))
    stdout.write('\n')

proc at(self: Gameplay, pos: (int, int)): Element =
  self.map[pos[0]][pos[1]]

proc setAt(self: var Gameplay, pos: (int, int), newVal: Element) =
  self.map[pos[0]][pos[1]] = newVal

proc move(self: var Gameplay, dir: Dir) =
  let shift = case dir:
    of Left: (0, -1)
    of Right: (0, 1)
    of Up: (-1, 0)
    of Down: (1, 0)

  var nextRobotPos = (self.robotPos[0] + shift[0], self.robotPos[1] + shift[1])
  var nextPos = nextRobotPos
  while self.at(nextPos) != Floor and self.at(nextPos) != Wall:
    nextPos = (nextPos[0] + shift[0], nextPos[1] + shift[1])

  if self.at(nextPos) != Floor:
    return

  if nextPos != nextRobotPos:
    self.setAt(nextPos, Box)
  self.robotPos = nextRobotPos
  self.setAt(nextRobotPos, Floor)
  

proc score(self: Gameplay): int =
  var score = 0
  for i, row in self.map.pairs:
    for j, col in row.pairs:
      if self.at((i,j)) == Box:
        score += 100 * i + j
  return score

var readingMap = true

var map = newSeq[seq[Element]]()
var directions = newSeq[Dir]()

for line in lines("input.txt"):
  if readingMap:
    var mapLine = newSeq[Element]()
    if line.len == 0:
      readingMap = false
      continue
    for ch in line:
      let elem = Element(ch)
      mapLine.add(elem)
    map.add(mapLine)
  else:
    for ch in line:
      directions.add(Dir(ch))


var gameplay = newGameplay(map)

for move in directions:
  gameplay.move(move)

gameplay.print()
echo gameplay.score()