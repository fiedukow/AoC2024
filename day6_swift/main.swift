import Foundation

let filePath = "input.txt"

enum Direction {
    case up
    case down
    case left
    case right

    static func fromChar(_ c: UInt8) -> Self? {
        if c == ">".first!.asciiValue {
            return .right
        }
        if c == "<".first!.asciiValue {
            return .left
        }
        if c == "^".first!.asciiValue {
            return .up
        }
        if c == "v".first!.asciiValue {
            return .down
        }
        return nil
    }

    func rotatedRight() -> Self {
        switch self {
            case .up:
                return .right
            case .down:
                return .left
            case .left:
                return .up
            case .right:
                return .down
        }
    }
}

enum Place {
    case floor
    case wall
    case ward(Direction)

    static func fromChar(_ c: UInt8) -> Self? {
        if c == ".".first!.asciiValue {
            return .floor
        }
        if c == "#".first!.asciiValue {
            return .wall
        }
        guard let dir = Direction.fromChar(c) else {
            return nil
        }
        return .ward(dir)
    }
}

extension String {
    func asArrayOfPlaces() -> [Place] {
        self.utf8.map { Place.fromChar($0)! }
    }
}

struct Pos: Hashable {
    var x: Int
    var y: Int

    func move(inDir dir: Direction) -> Self {
        switch dir {
            case .up:
                return .init(x: x-1, y: y)
            case .down:
                return .init(x: x+1, y: y)
            case .left:
                return .init(x: x, y: y-1)
            case .right:
                return .init(x: x, y: y+1)
        }
    }
}

struct WardState: Hashable {
    var pos: Pos
    var dir: Direction
}

class Gameplay {
    var area: [[Place]]
    var visited: Set<Pos> = .init()
    var ward: WardState

    var isGameDone = false

    init(area: [[Place]]) {
        self.area = area
        ward = self.area.findWard()!
    }

    func playMove() {
        visited.insert(ward.pos)
        let newPos = ward.pos.move(inDir: ward.dir)
        let atPos = area.atPos(newPos)
        guard let atPos else {
            isGameDone = true
            return
        }
        switch atPos {
            case .floor:
                ward = .init(pos: newPos, dir: ward.dir)
            case .wall:
                ward = .init(pos: ward.pos, dir: ward.dir.rotatedRight())
            case .ward:
                assertionFailure("other ward unexpected")
        }
    }
    
    func playGame() {
        while !isGameDone {
            playMove()
        }
    }
}

class Gameplay2 {
    var area: [[Place]]
    var visited: Set<WardState> = .init()
    var ward: WardState

    var isInLoop = false
    var isGameDone = false

    init(area: [[Place]]) {
        self.area = area
        ward = self.area.findWard()!
    }

    func playMove(_ debugMode: Bool = false) {
        if visited.contains(ward) {
            isInLoop = true
            isGameDone = true
            return
        }
        visited.insert(ward)
        let newPos = ward.pos.move(inDir: ward.dir)
        if debugMode {
        print("going to \(newPos)")
        }
        let atPos = area.atPos(newPos)
        guard let atPos else {
            isGameDone = true
            return
        }
        switch atPos {
            case .floor:
                ward = .init(pos: newPos, dir: ward.dir)
            case .wall:
                ward = .init(pos: ward.pos, dir: ward.dir.rotatedRight())
            case .ward:
                assertionFailure("other ward unexpected")
        }
    }
    
    func playGame(_ debugMode: Bool = false) {
        while !isGameDone {
            playMove(debugMode)
        }
    }
}

extension Array where Element == [Place] {
    mutating func findWard() -> WardState? {
        for (i, line) in self.enumerated() {
            for (j, spot) in line.enumerated() {
                if case let .ward(direction) = spot {
                    self[i][j] = .floor
                    return .init(pos: .init(x: i, y: j), dir: direction)
                } 
            }
        }
        return nil
    }

    func atPos(_ pos: Pos) -> Place? {
        guard pos.x >= 0, pos.y >= 0, pos.x < self.count, pos.y < self[0].count else {
            return nil
        }
        return self[pos.x][pos.y]
    }
}

if let fileHandle = FileHandle(forReadingAtPath: filePath) {
    defer { fileHandle.closeFile() }

    let content = String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8)!
    let lines = content.split(separator: "\n")
    let area = lines.map { String($0).asArrayOfPlaces() }

    let game: Gameplay = .init(area: area)
    game.playGame()
    print(game.visited.count)

    var count = 0
    for (i, line) in area.enumerated() {
        for (j, _) in line.enumerated() {
            var newMap = Array(area)
            if case .ward = newMap[i][j] {
                continue;
            }
            newMap[i][j] = .wall
            // print("\(i), \(j)")
            let game: Gameplay2 = .init(area: newMap)
            game.playGame()
            if game.isInLoop {
                count += 1
            }
        }
        print(i)
    }

    print(count)
}
