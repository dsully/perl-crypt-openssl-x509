use inc::Module::Install;

use Config;

name('Crypt-OpenSSL-X509');
license('perl');
perl_version('5.005');
all_from('X509.pm');

homepage 'https://github.com/dsully/perl-crypt-openssl-x509';
repository 'https://github.com/dsully/perl-crypt-openssl-x509';
bugtracker 'https://github.com/dsully/perl-crypt-openssl-x509/issues';

requires_external_cc();

    inc '-I/usr/include/openssl -I/usr/local/include/ssl -I/usr/local/ssl/include';

    libs '-L/usr/lib -L/usr/local/lib -L/usr/local/ssl/lib -lcrypto';

    if ($Config::Config{myuname} =~ /darwin/i) {
      cc_optimize_flags('-O2 -g -Wall -Werror -Wno-deprecated-declarations');
    } elsif ($Config::Config{myuname} =~ /sunos|solaris/i) {
      # Any SunStudio flags?
    } else {
      cc_optimize_flags('-O2 -g -Wall -Werror');
    }

auto_install();
WriteAll();
