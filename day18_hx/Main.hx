import sys.io.File;
import haxe.format.JsonPrinter;

typedef Pos = {x:Int, y:Int};
typedef PosAndStep = {x:Int, y:Int, step:Int};


class GameMap {
  static public inline var WIDTH = 71;
  static public inline var HEIGHT = 71;

  public var bytesBlockedAt: Map<Int, Array<Array<Bool>>>;
  public var finalBlocked: Array<Array<Bool>>;
  public var numberOfLines: Int;

  public static function emptyArrayOfBools(): Array<Array<Bool>>  {
    var res: Array<Array<Bool>> = new Array<Array<Bool>>();
    for (i in 0...HEIGHT) {
      res[i] = new Array<Bool>();
      for (j in 0...WIDTH) {
        res[i][j] = false;
      }
    }
    return res;
  }

  public function new(bytesPos:Array<Pos>) {
    bytesBlockedAt = new Map<Int, Array<Array<Bool>>>();
    var current: Array<Array<Bool>> = emptyArrayOfBools();
    for (i => pos in bytesPos) {
      bytesBlockedAt[i] = new Array<Array<Bool>>();
      for (j in 0...HEIGHT) {
        bytesBlockedAt[i][j] = current[j].copy();
      }
      current[pos.y][pos.x] = true;
    }
    numberOfLines = bytesPos.length;
    finalBlocked = current;
  }

  public function accessibleAtStep(pos: Pos, step: Int): Bool {
    if (!bytesBlockedAt.exists(step)) {
      return !finalBlocked[pos.y][pos.x];
    }
    return !bytesBlockedAt[step][pos.y][pos.x];
  }

  public function addIfValid(pos: Pos, array: Array<PosAndStep>, step: Int, atMemory: Int) {
    if (pos.x < 0 || pos.x >= WIDTH || pos.y < 0 || pos.y >= HEIGHT) {
      return;
    }
    if (!accessibleAtStep(pos, atMemory)) {
      return;
    }
    array.push({x: pos.x, y: pos.y, step: step});
  }

  public function validNeighbours(pos: PosAndStep, atMemory: Int): Array<PosAndStep> {
    var res = new Array<PosAndStep>();
    addIfValid({x: pos.x - 1, y: pos.y}, res, pos.step + 1, atMemory);
    addIfValid({x: pos.x + 1, y: pos.y}, res, pos.step + 1, atMemory);
    addIfValid({x: pos.x, y: pos.y - 1}, res, pos.step + 1, atMemory);
    addIfValid({x: pos.x, y: pos.y + 1}, res, pos.step + 1, atMemory);
    return res;
  }

  public function solve(atMemory: Int): Int {
    var startPoint = { x: 0, y: 0 };
    var endPoint = { x: WIDTH-1, y: HEIGHT-1 };

    var visited = emptyArrayOfBools();
    var current = { x: 0, y: 0, step: 0 };
    var toCheck = [{x: 0, y: 0, step: 0}];

    while (toCheck.length > 0) {
      current = toCheck.shift();
      if (visited[current.y][current.x]) {
        continue;
      }
      visited[current.y][current.x] = true;

      if (current.x == endPoint.x && current.y == endPoint.y) {
        return current.step;
      }

      toCheck = toCheck.concat(validNeighbours(current, atMemory));
    }
    return -1;
  }

  public function solve2(): Int {
    var L = 0;
    var H = numberOfLines;
    var MID = 0;
    while (L < H) {
      MID = (L + H) >> 1;
      if (solve(MID) < 0) {
        H = MID;
      } else {
        L = MID + 1;
      }
    }
    return MID;
  }
}

class Main {
  static public function main() {
    var content = File.getContent("input.txt");
    var lines = content.split("\n");
    var coords = lines.map(l -> l.split(",").map(v -> Std.parseInt(v))).map(coordPair -> {x: coordPair[0], y: coordPair[1]});

    var gameMap = new GameMap(coords);
    trace(gameMap.solve(1024));
    trace(coords[gameMap.solve2()]);
  }
}