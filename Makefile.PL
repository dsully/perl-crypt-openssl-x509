# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

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
cc_optimize_flags('-g -Wall');

auto_install();
WriteAll();
