import 'dart:io';
import 'dart:convert';
import 'dart:math';

const VERY_LARGE_NUMBER = 10000000000000;

class Button {
  final int xShift;
  final int yShift;

  Button(this.xShift, this.yShift);

  Map<String, dynamic> toJson() {
    return {
      'xShift': xShift,
      'yShift': yShift,
    };
  }
}

int unsafeParse(String? s) {
  return int.parse(s ?? "0");
}

class Machine {
  List<Button> buttons = [];
  List<int> costs = [3, 1];
  int targetX = 0;
  int targetY = 0;

  Machine(Match regexMatch) {
    buttons = [
      Button(unsafeParse(regexMatch.group(1)), unsafeParse(regexMatch.group(2))),
      Button(unsafeParse(regexMatch.group(3)), unsafeParse(regexMatch.group(4))),
    ];
    targetX = unsafeParse(regexMatch.group(5)) + VERY_LARGE_NUMBER;
    targetY = unsafeParse(regexMatch.group(6)) + VERY_LARGE_NUMBER;
  }

  Map<String, dynamic> toJson() {
    return {
      'buttons': buttons.map((button) => button.toJson()).toList(),
      'targetX': targetX,
      'targetY': targetY,
    };
  }

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(this);
  }

  int onlySolutionCost() {
    int fClicksN = targetY * buttons[1].xShift - targetX * buttons[1].yShift;
    int fClicksD = buttons[0].yShift * buttons[1].xShift - buttons[0].xShift * buttons[1].yShift;
    if (fClicksN % fClicksD != 0) {
      return 0;
    }
    int fClicks = fClicksN ~/ fClicksD;

    int sClicksN = targetY * buttons[0].xShift - targetX * buttons[0].yShift;
    int sClicksD = buttons[1].yShift * buttons[0].xShift - buttons[1].xShift * buttons[0].yShift;
    if (sClicksN % sClicksD != 0) {
      return 0;
    }

    int sClicks = sClicksN ~/ sClicksD;
    return 3 * fClicks + sClicks;
  }
}


void main() async {
  String content = await File('input.txt').readAsString();

  RegExp regex = RegExp(r'Button A: X\+(\d+), Y\+(\d+)\nButton B: X\+(\d+), Y\+(\d+)\nPrize: X=(\d+), Y=(\d+)', multiLine: true);
  Iterable<Match> matches = regex.allMatches(content);

  var machines = matches.map((match) => Machine(match));
  int sumOfCost = 0;
  for (var m in machines) {
    sumOfCost += m.onlySolutionCost();
  }
  print('Minimal cost is ${sumOfCost}');
}