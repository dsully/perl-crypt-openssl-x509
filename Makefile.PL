# $Id: Makefile.PL 10 1998-12-16 23:02:45Z daniel $

use inc::Module::Install;

name('Crypt-OpenSSL-X509');
license('perl');
perl_version('5.005');
all_from('X509.pm');

cc_lib_links('crypto');
cc_optimize_flags('-g -Wall');

auto_install();
WriteAll();
