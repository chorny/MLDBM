#!/usr/bin/perl -w
use Fcntl;
use MLDBM;
use Data::Dumper;
tie %o, MLDBM, 'testmldbm', O_CREAT|O_RDWR, 0640 or die $!;
print "1..1\n";

$c = [\'c'];
$b = {};
$a = [1, $b, $c];
$b->{a} = $a;
$b->{b} = $a->[1];
$b->{c} = $a->[2];
@o{qw(a b c)} = ($a, $b, $c);
$first = Data::Dumper->Dump([@o{qw(a b c)}], [qw(a b c)]);
$second = <<'EOT';
$a = [
       1,
       {
         a => $a,
         b => $a->[1],
         c => [
                \'c'
              ]
       },
       $a->[1]{c}
     ];
$b = {
       a => [
              1,
              $b,
              [
                \'c'
              ]
            ],
       b => $b,
       c => $b->{a}[2]
     };
$c = [
       \'c'
     ];
EOT
print $first;
if ($first eq $second) { print "ok 1\n" }
else { print "not ok 1\n" }
