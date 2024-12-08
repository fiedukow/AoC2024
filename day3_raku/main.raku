my $file-content = "input.txt".IO.slurp;


my $muls = $file-content.match(/mul\((\d+)","(\d+)\)/, :g);
say $muls.map({ $_[0] * $_[1] }).sum;


grammar Calculator {
    token TOP { [ <mul> | <enable> | <disable> | <whatever> ]+ }
    rule  mul { 'mul(' <num> ',' <num> ')' }
    rule  enable { 'do()' }
    rule  disable { 'don\'t()' }
    rule  garbage { <whatever> }
    token num { \d+ }
    token whatever { . }
};

class ParserActions {
    has Bool $enabled = True;
    has Int $sum = 0;

    method mul       ($/) {
        if !$enabled {
            return;
        }
        my ($num1, $num2) = $<num>.map({ $_.Int });
        $sum += $num1 * $num2;
    }
    method enable    ($/) { $enabled = True; }
    method disable   ($/) { $enabled = False; }

    method result() { return $sum; }
}

my $sumTool = ParserActions.new;
Calculator.parse($file-content, :actions($sumTool));

say $sumTool.result();
