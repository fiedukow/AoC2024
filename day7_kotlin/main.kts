import java.io.File

val fileName = "input.txt"

data class InputLine(var expectedSum: Long, var numbers: Array<Long>)

val inputs: MutableList<InputLine> = mutableListOf()

File(fileName).forEachLine { line ->
    val parsedLine = line.split(": ")
    val input = InputLine(parsedLine[0].toLong(), parsedLine[1].split(" ").map { it.toLong() }.toTypedArray())
    inputs.add(input)
}

fun isDoableOperation(base: Long, tail: List<Long>, target: Long): Boolean {
    if (tail.isEmpty()) { return base == target }
    if (base > target) { return false }
    return isDoableOperation(base + tail.first(), tail.drop(1), target) ||
            isDoableOperation(base * tail.first(), tail.drop(1), target) ||
            isDoableOperation((base.toString() + tail.first().toString()).toLong(), tail.drop(1), target)
}

fun isDoableOperation(input: InputLine): Boolean {
    return isDoableOperation(input.numbers.first(), input.numbers.drop(1), input.expectedSum)
}

inputs.map { if (isDoableOperation(it)) it.expectedSum else 0 }.sum()