use warnings;
use strict;
use version;
use Data::Dumper;

my $old = '1.909';
my $new = '1.910';

my $ver_1 = version->parse($old);
my $ver_2 = version->parse($new);

print STDERR Dumper $ver_1;

print STDERR Dumper $ver_2;

if ($ver_1 > $ver_2) {
    print "$old is higher than $new\n";
} else {
    print "$new is higher than $old\n";
}

exit 0;
