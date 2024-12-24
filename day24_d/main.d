import std.regex;
import std.stdio;
import std.file;
import std.container;
import std.typecons;
import std.conv;
import std.format;
import std.algorithm;

abstract class BoolExpr {
  abstract bool value(BoolExpr[string] repository);
  abstract string[] inputs();
  abstract string opName();
}

class StaticBoolExpr: BoolExpr {
  bool staticValue;
  this(bool value) {
    this.staticValue = value;
  }

  override bool value(BoolExpr[string] repository) {
    return staticValue;
  }

  override string[] inputs() {
    return [];
  }

  override string opName() {
    return "CONST";
  }
}

class Gate: BoolExpr {
  string lhs;
  string rhs;
  bool function(bool, bool) op;
  string opName_;

  this(string lhs, string rhs, bool function(bool, bool) op, string opName) {
    this.lhs = lhs;
    this.rhs = rhs;
    this.op = op;
    this.opName_ = opName;
  }

  override bool value(BoolExpr[string] repository) {
    return op(
      repository[lhs].value(repository),
      repository[rhs].value(repository)
    );
  }

  override string[] inputs() {
    return [lhs, rhs];
  }

  override string opName() {
    return this.opName_;
  }
}

bool andOperation(bool a, bool b) {
    return a && b;
}

bool orOperation(bool a, bool b) {
    return a || b;
}

bool xorOperation(bool a, bool b) {
    return a != b;
}

void order(ref string a, ref string b) {
  if (a > b) {
    swap(a, b);
  }

  // known variable first
  if (b[0] == 'x') {
    swap(a, b);
  }

  if (b[0] == 'y' && a[0] != 'x') {
    swap(a, b);
  }
}

BoolExpr createGate(string lhs, string rhs, string op) {
  order(lhs, rhs);

  switch(op) {
    case "AND": return new Gate(lhs, rhs, &andOperation, "AND");
    case "OR": return new Gate(lhs, rhs, &orOperation, "OR");
    case "XOR": return new Gate(lhs, rhs, &xorOperation, "XOR");
    default: assert(false);
  }
}

Nullable!string findWithInputs(BoolExpr[string] repository, string[] inputs, string opName, string debug_forId) {
  foreach (outputVar, expr; repository) {
    if (sort(inputs) == sort(expr.inputs()) && expr.opName() == opName) {
      writeln(inputs[0], " ", opName, " ", inputs[1], " -> ", outputVar, " | ", debug_forId);
      return Nullable!string(outputVar);
    }
  }
  writeln(inputs[0], " ", opName, " ", inputs[1], " -> NULL", " | ", debug_forId);
  return Nullable!string.init;
}

int countBits(BoolExpr[string] repository) {
  int total = 0;
  foreach (i; 0 .. 100) {
    string zId = format("z%02d", i);
    if (zId in repository) {
      total++;
    }
  }
  return total;
}

bool isRanamesConsistent(bool[string][string] renames) {
  bool cons = true;
  foreach (key, v; renames) {
    if (v.length > 1) {
      writeln("Inconsistent ", key, " candidates: ", to!string(v));
      cons = false;
    }
  }
  return cons;
}

bool[string][string] renameProposals(BoolExpr[string] repository) {
  bool[string][string] renames;
  renames["c00"]["bdj"] = true;
  string lastCarry = "bdj";

  int total = countBits(repository) - 1;

  foreach (i; 1 .. total) {
    string xId = format("x%02d", i);
    string yId = format("y%02d", i);
    string zId = format("z%02d", i);
    string aId = format("a%02d", i);
    string bId = format("b%02d", i);
    string cId = format("c%02d", i);
    string pcId = format("c%02d", i - 1);
    string tId = format("t%02d", i);

    // c00 = bdj
    // y01 XOR x01 -> twd | a01
    // y01 AND x01 -> gwd | b01
    // twd (a01) AND bdj (c00) -> cbq | t01
    // cbq (t01) OR gwd (b01) -> rhr | c01
    // twd (a01) XOR bdj (c00) -> z01

    // y01 XOR x01 -> twd | a01
    string aOId = findWithInputs(repository, [xId, yId], "XOR", aId).get;
    renames[aId][aOId] = true;

    // y01 AND x01 -> gwd | b01
    string bOId = findWithInputs(repository, [xId, yId], "AND", bId).get;
    renames[bId][bOId] = true;

    // twd (a01) AND bdj (c00) -> cbq | t01
    string tOId = findWithInputs(repository, [aOId, lastCarry], "AND", tId).get;
    renames[tId][tOId] = true;

    // cbq (t01) OR gwd (b01) -> rhr | c01
    string cOId = findWithInputs(repository, [tOId, bOId], "OR", cId).get;
    renames[cId][cOId] = true;

    // twd (a01) XOR bdj (c00) -> z01
    BoolExpr zExpr = repository[zId];
    if (aOId != zExpr.inputs()[0] && lastCarry != zExpr.inputs()[0]) {
      writeln("Expected: ", aOId, " (", aId, ") XOR ", lastCarry, " (", pcId, ") -> ", zId);
      writeln("Got: ", zExpr.inputs()[0], " ", zExpr.opName(), " ", zExpr.inputs()[1], " -> ", zId);
      assert(false);
    }
    if (aOId != zExpr.inputs()[1] && lastCarry != zExpr.inputs()[1]) {
      writeln("Expected: ", aOId, " (", aId, ") XOR ", lastCarry, " (", pcId, ") -> ", zId);
      writeln("Got: ", zExpr.inputs()[0], " ", zExpr.opName(), " ", zExpr.inputs()[1], " -> ", zId);
      assert(false);
    }
    // renames[aId] ~= zExpr.inputs()[0];
    // renames[aId] ~= zExpr.inputs()[0];
    // renames[pcId] ~= zExpr.inputs()[1];
    // renames[pcId] ~= zExpr.inputs()[1];

    lastCarry = cOId;

    assert(isRanamesConsistent(renames));
  }

  return renames;
}

void main() {
  string content = readText("input.txt");
  auto inputRegex = regex(`(\w\w\w): ([01])`);
  auto gateRegex = regex(`(\w\w\w) (OR|XOR|AND) (\w\w\w) -> (\w\w\w)`);
  BoolExpr[string] repository;
    
  foreach (match; matchAll(content, inputRegex)) {
    string id = match.captures[1];
    bool value = match.captures[2] == "1";

    repository[id] = new StaticBoolExpr(value);
  }

  foreach (match; matchAll(content, gateRegex)) {
    string lhs = match.captures[1];
    string rhs = match.captures[3];
    string op = match.captures[2];
    string outVar = match.captures[4];

    repository[outVar] = createGate(lhs, rhs, op);
  }

  string wholeBinNumber = "";
  foreach (i; 1 .. 101) {
    string zId = format("z%02d", 100 - i);
    if (zId in repository) {
      wholeBinNumber ~= repository[zId].value(repository) ? "1" : "0";
    }
  }

  writeln("Part 1: " ~ to!string(to!long(wholeBinNumber, 2)));

  writeln(renameProposals(repository));
}

// Structure 1 - 99:
// c00 = bdj
// y01 XOR x01 -> twd | a01
// y01 AND x01 -> gwd | b01
// twd (a01) AND bdj (c00) -> cbq | t01
// cbq (t01) OR gwd (b01) -> rhr | c01
// twd (a01) XOR bdj (c00) -> z01


// x00 XOR y00 -> a00
// c00 XOR a00 -> z00
// c00 AND a00 -> c01