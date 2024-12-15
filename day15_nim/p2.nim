import os
import options

type
  Element = enum
    Wall = '#', Floor = '.', Robot = '@', LBox = '[', RBox = ']'

type
  Dir = enum
    Left = '<', Right = '>', Up = '^', Down = 'v'

proc shift(self: Dir): (int, int) =
  case self:
    of Left: (0, -1)
    of Right: (0, 1)
    of Up: (-1, 0)
    of Down: (1, 0)

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

proc canMoveLBox(self: Gameplay, dir: Dir, pos: (int, int)): bool =
  assert(self.at(pos) == LBox)

proc canMove(self: Gameplay, dir: Dir, pos: (int, int)): bool =
  case self.at(pos):
    of Wall: false
    of Floor: true
    of Robot: true
    of LBox:
      var newPos = (pos[0] + dir.shift()[0], pos[1] + dir.shift()[1])
      var rPos = (pos[0], pos[1] + 1)
      var rNewPos = (newPos[0], newPos[1] + 1)
      if newPos == rPos:
        return self.canMove(dir, rNewPos)
      if rNewPos == pos:
        return self.canMove(dir, newPos)

      return self.canMove(dir, (pos[0] + dir.shift()[0], pos[1] + dir.shift()[1])) and
        self.canMove(dir, (pos[0] + dir.shift()[0], pos[1] + dir.shift()[1] + 1))      
    of RBox: self.canMove(dir, (pos[0], pos[1] - 1))

proc move(self: var Gameplay, dir: Dir, pos: (int, int)) =
  case self.at(pos):
    of Wall: assert(false)
    of Floor: discard
    of Robot: assert(false)
    of LBox:
      var newPos = (pos[0] + dir.shift()[0], pos[1] + dir.shift()[1])
      var rPos = (pos[0], pos[1] + 1)
      var rNewPos = (newPos[0], newPos[1] + 1)
      if newPos != rPos:
        self.move(dir, newPos)
      if rNewPos != pos:
        self.move(dir, rNewPos)
      self.setAt(pos, Floor)
      self.setAt(rPos, Floor)
      self.setAt(rNewPos, RBox)
      self.setAt(newPos, LBox)
    of RBox: self.move(dir, (pos[0], pos[1] - 1))

proc move(self: var Gameplay, dir: Dir) =
    var nextRobotPos = (self.robotPos[0] + dir.shift()[0], self.robotPos[1] + dir.shift()[1])
    if not self.canMove(dir, nextRobotPos):
      return
    self.move(dir, nextRobotPos)
    self.robotPos = nextRobotPos

  
proc score(self: Gameplay): int =
  var score = 0
  for i, row in self.map.pairs:
    for j, col in row.pairs:
      if self.at((i,j)) == LBox:
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
      let elems: (Element, Element) = case ch:
        of '.': (Floor, Floor)
        of '#': (Wall, Wall)
        of 'O': (LBox, RBox)
        of '@': (Robot, Floor)
        else: (Wall, Wall) 
      mapLine.add(elems[0])
      mapLine.add(elems[1])
    map.add(mapLine)
  else:
    for ch in line:
      directions.add(Dir(ch))


var gameplay = newGameplay(map)

for move in directions:
  gameplay.move(move)

gameplay.print()
echo gameplay.score()