use warnings;
use strict;
use version;
use Data::Dumper;

my $old = '2.0.0';
my $new = '1.915';

my $ver_1 = version->parse($old);
my $ver_2 = version->parse($new);

print STDERR Dumper $ver_1;

print STDERR Dumper $ver_2;

if ($ver_1 > $ver_2) {
    print "using version: $old is higher than $new\n";
} else {
    print "using version: $new is higher than $old\n";
}

if ($old gt $new) {
    print "not using version: $old is higher than $new\n";
} else {
    print "not using version: $new is higher than $old\n";
}


if ($ver_1 gt $new) {
    print "combined using version: $old is higher than $new\n";
} else {
    print "combined not using version: $new is higher than $old\n";
}


exit 0;
