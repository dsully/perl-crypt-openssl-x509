use lib '.';
use inc::Module::Install;
use Module::Install::AutoInstall;

use File::Spec;
use Config;

name('Crypt-OpenSSL-X509');
license('perl');
perl_version('5.008');
all_from('X509.pm');

homepage 'https://github.com/dsully/perl-crypt-openssl-x509';
repository 'https://github.com/dsully/perl-crypt-openssl-x509';
bugtracker 'https://github.com/dsully/perl-crypt-openssl-x509/issues';

requires_external_cc();

if ($^O ne 'MSWin32' and my $prefix = `brew --prefix openssl 2>@{[File::Spec->devnull]}`) {
  chomp $prefix;
  inc "-I$prefix/include";
  libs "-L$prefix/lib -lcrypto -lssl";
} else {
  inc '-I/usr/local/opt/openssl/include -I/usr/local/include/openssl -I/usr/include/openssl -I/usr/local/include/ssl -I/usr/local/ssl/include';
  libs '-L/usr/local/opt/openssl/lib -L/usr/local/lib -L/usr/lib -L/usr/local/ssl/lib -lcrypto -lssl';
}

my $cc_option_flags = '-O2 -g -Wall -Werror';

if ($Config::Config{gccversion} =~ /llvm/i) {
  if ($Config::Config{perl_version} <= 20) {
    $cc_option_flags .= ' -Wno-error=pointer-bool-conversion';
  }
}

if ($Config::Config{myuname} =~ /sunos|solaris/i) {
  # Any SunStudio flags?
} else {
  cc_optimize_flags($cc_option_flags);
}

auto_install();
WriteAll;
