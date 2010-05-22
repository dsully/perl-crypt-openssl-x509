# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

use Config;

sub search_lib {
    my ($lib) = @_;
    unless ($lib =~ /^-l/) {
        warn "search_lib: illegal arguments, \`$lib\'.\n";
        return undef;
    }
    my $libbase = 'lib' . substr($lib, 2) . $Config{lib_ext};
    my $libbase_so = 'lib' . substr($lib, 2) . "." . $Config{so};
    for my $path (split(' ', $Config{libpth})) {
        if (-f $path . '/' . $libbase) {
            print "$path/$libbase\n";
            print "Found '$path/$libbase'.\n";
            return $lib;
        } elsif (-f $path . '/' . $libbase_so) {
            print "$path/$libbase_so\n";
            print "Found `$_/$libbase_so'.\n";
            return $lib;
        }
    }
    return undef;
}

if (!defined search_lib('-lcrypto')) {
        warn "* libcrypto is not installed or not in the default lib path. Aborting.\n";
        exit;
}

use inc::Module::Install;

name('Crypt-OpenSSL-X509');
license('perl');
perl_version('5.005');
all_from('X509.pm');

requires_external_cc();

if (-d "/usr/include/openssl") {
	cc_inc_paths('/usr/include/openssl');
	cc_lib_paths('/usr/lib');
} elsif (-d "/usr/local/include/ssl") {
	cc_inc_paths('/usr/local/include/ssl');
	cc_lib_paths('/usr/local/lib/ssl');
} elsif (-d "/usr/local/ssl/include") {
	cc_inc_paths('/usr/local/ssl/include');
	cc_lib_paths('/usr/local/ssl/lib');
}

cc_lib_links('crypto');
cc_optimize_flags('-g -Wall -Werror');

auto_install();
WriteAll();
