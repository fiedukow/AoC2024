
my %GLOBAL_CACHE = ();

sub iterateOnce {
    my ($n) = @_;
    if ($n == 0) {
        return (1);
    }
    if (length($n) % 2 == 0) {
        return (int(substr($n, 0, length($n) / 2)), int(substr($n, length($n) / 2, length($n))));
    }
    return ($n * 2024);
}

sub countIterateN {
    my ($v, $n) = @_;
    if (exists $GLOBAL_CACHE{"$v,$n"}) {
        return $GLOBAL_CACHE{"$v,$n"};
    }
    my @numbers = iterateOnce($v);
    if ($n == 1) {
        $GLOBAL_CACHE{"$v,$n"} = scalar @numbers;
        return scalar @numbers
    }
    my $sumOfChildren = 0;
    foreach my $num (@numbers) {
        $sumOfChildren += countIterateN($num, $n-1);
    }
    $GLOBAL_CACHE{"$v,$n"} = $sumOfChildren;
    return $sumOfChildren;
}

open(my $fh, '<', 'input.txt') or die "Cannot open file: $!";
my @numbers = split ' ', <$fh>;
close($fh);

my $total = 0;
foreach my $num (@numbers) {
    $total += countIterateN($num, 75);
}

print "Total is: $total\n"
