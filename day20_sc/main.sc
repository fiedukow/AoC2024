
import scala.io.Source
import scala.collection.mutable.Queue
import scala.collection.mutable.HashSet
import util.control.Breaks._

enum Tile:
  case Floor, Wall

class Gameplay(gridStrings: Array[String]):
  val (gameMap, start, end) = {
    var startPos: (Int, Int) = (0, 0)
    var endPos: (Int, Int) = (0, 0)
    
    val map = gridStrings.zipWithIndex.map { 
      case (row, y) => row.zipWithIndex.map {
        case ('.', _) => Tile.Floor
        case ('#', _) => Tile.Wall
        case ('S', x) => startPos = (x, y); Tile.Floor
        case ('E', x) => endPos = (x, y); Tile.Floor
        case _        => assert(false, "Unexpected input!")
      }.toArray
    }

    (map, startPos, endPos)
  }

  def isInBound(pos: (Int, Int)): Boolean = 
    pos._1 >= 0 && pos._1 < gameMap.length && pos._2 >= 0 && pos._2 < gameMap(0).length

  def isCheating(pos: (Int, Int)): Boolean = 
    isInBound(pos) && gameMap(pos._2)(pos._1) == Tile.Wall

  def isWalkable(pos: (Int, Int)): Boolean =
    isInBound(pos) && gameMap(pos._2)(pos._1) == Tile.Floor

  def neightboursOf(pos: (Int, Int)): Array[(Int, Int)] =
    Array(
      (pos._1 + 1, pos._2),
      (pos._1 - 1, pos._2),
      (pos._1, pos._2 + 1),
      (pos._1, pos._2 - 1),
    )

  def walkableOptions(pos: (Int, Int)): Array[(Int, Int)] =
    neightboursOf(pos).filter(nPos => isWalkable(nPos))

  def cheatingOptions(pos: (Int, Int)): Array[(Int, Int)] =
    neightboursOf(pos).filter(nPos => isCheating(nPos))


  def findShortestPath(): List[((Int, Int), Int)] =
    var toScan = Queue[List[((Int, Int), Int)]](List((start, 0)))
    
    while (!toScan.isEmpty) {
      val current = toScan.dequeue();
      val currentStep :: pathSoFar = current
      val (currentPos, currentTime) = currentStep
      if (currentPos == end) {
        return current
      }
      if (!(pathSoFar.map(_._1) contains currentPos)) {
        val newOptions = walkableOptions(currentPos).map {
          nPos => (nPos, currentTime + 1) :: currentStep :: pathSoFar
        }
        toScan.enqueueAll(newOptions)
      }
    }

    return List()

  def cheatCandidates(pos: (Int, Int), cheatLimit: Int): List[(Int, Int)] =
    (
      for {
        x <- -cheatLimit to cheatLimit
        y <- -cheatLimit to cheatLimit
      } yield (x, y)
    )
    .toList
    .filter((dx, dy) => (math.abs(dx) + math.abs(dy)) <= cheatLimit)
    .map((dx, dy) => (pos._1 + dx, pos._2 + dy))

  def countCheatedOptions(cheatLimit: Int, timeSave: Int): Int =
    val path = findShortestPath()
    val timeOfBestPath = path.head._2

    println(s"Time of best path: ${timeOfBestPath}")
    val timeLimit = timeOfBestPath - timeSave
    var i = 0

    val result = path.flatMap(
      (pathPoint, costSoFar) =>
        println(s"Checking ${i}")
        i += 1
        cheatCandidates(pathPoint, cheatLimit)
          .filter((cx, cy) => 
            path.find((pos, _) => pos == (cx, cy)) match {
              case Some((_, finalCost)) =>
                val (_, finalCostFromBeg) = path.find((pos, _) => pos == (cx, cy)).get
                val finalCost = timeOfBestPath - finalCostFromBeg
                val jumpCost = math.abs(pathPoint._1 - cx) + math.abs(pathPoint._2 - cy)
                // println(s"${pathPoint._1} ${pathPoint._2} candidate ${cx} ${cy} jumpCost = ${jumpCost}, finalCost = ${finalCost}, costSoFar = ${costSoFar}, total = ${(costSoFar + finalCost + jumpCost)}, limit = ${timeLimit}")
                (costSoFar + finalCost + jumpCost) <= timeLimit
              case None => false
            }
          ).map(
            goodCandidate => (pathPoint, goodCandidate)
          )
    )
    // println(s"${result}")    
    return result.distinct.length

  def solve(cheatSave: Int) = 
    val timeNoCheat = findShortestPath()
    val timeLimit = timeNoCheat(0)._2 - cheatSave
    

val lines: Array[String] = Source.fromFile("input.txt").getLines().toArray
val game = Gameplay(lines)
println(s"${game.countCheatedOptions(20, 100)}")