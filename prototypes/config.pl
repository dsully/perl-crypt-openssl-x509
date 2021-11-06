use warnings;
use strict;

use Config;

foreach my $key (keys %Config::Config) {
    print "$key = ".$Config::Config{$key}."\n";
}


