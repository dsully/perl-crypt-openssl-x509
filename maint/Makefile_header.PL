use Config;
use Crypt::OpenSSL::Guess qw(openssl_lib_paths openssl_inc_paths);

my $libs = ' -lssl -lcrypto';
if ($Config{osname} eq 'aix') {
  $libs = $libs . ' -lz';
}

my %args = (
  LIBS => [openssl_lib_paths(). $libs],
  INC => openssl_inc_paths(),
);

#my $api_ver = '0x00908000L';  # (version 0.9.8)
#my $api_ver = '0x10000000L';  # (version 1.0.0)
my $api_ver = '0x10100000L';  # (version 1.1.0)

$args{CCFLAGS} = "$Config::Config{ccflags} -DOPENSSL_API_COMPAT=$api_ver";

my $cc_option_flags = " -O2 -g";

if ($Config::Config{cc} =~ /gcc/i) {
  $cc_option_flags .= $ENV{AUTHOR_TESTING} ? ' -Wall -Werror' : ' -Wall';
} else {
  $cc_option_flags .= '';
}

if ($Config{gccversion} =~ /llvm/i) {
  $cc_option_flags .= ' -Wall -Wno-deprecated-declarations';

  if ($Config{gccversion} =~ /llvm 12/i) {
    $cc_option_flags .= ' -Wno-compound-token-split-by-macro';
  }

  if ($Config{gccversion} =~ /llvm 13/i) {
    $cc_option_flags .= ' -Wno-compound-token-split-by-macro';
  }

  if ($Config{gccversion} =~ /llvm 14/i) {
    $cc_option_flags .= ' -Wno-compound-token-split-by-macro';
  }

  if ($Config{perl_version} <= 20) {
    $cc_option_flags .= ' -Wno-error=pointer-bool-conversion';
  }
}

if ($Config{myuname} =~ /sunos|solaris/i) {
  $args{OPTIMIZE} = $cc_option_flags;
} else {
  $args{OPTIMIZE} = $cc_option_flags;
}

# Crypt::OpenSSL::Guess can silently return empty or wrong include/lib
# paths (e.g. https://github.com/dsully/perl-crypt-openssl-x509/issues/67),
# which otherwise surfaces only much later as a wall of "undefined
# reference" linker errors with no indication that OpenSSL is the cause.
# Do a throwaway compile+link here so we can fail fast with a clear
# diagnostic instead.
unless ($ENV{PERL_CRYPT_OPENSSL_X509_SKIP_OPENSSL_CHECK}) {
  require File::Temp;

  my $dir = File::Temp::tempdir(CLEANUP => 1);
  my $src = "$dir/openssl_check.c";
  my $obj = "$dir/openssl_check$Config{obj_ext}";
  my $exe = "$dir/openssl_check$Config{exe_ext}";

  open my $fh, '>', $src or die "Can't write $src: $!";
  print {$fh} <<'C_SRC';
#include <openssl/x509.h>
#include <openssl/err.h>

int main(void) {
    X509 *x = X509_new();
    if (x) {
        X509_free(x);
    }
    ERR_clear_error();
    return 0;
}
C_SRC
  close $fh;

  my $inc  = $args{INC} || '';
  my $libs = $args{LIBS}[0] || '';
  my $cc   = $Config{cc};
  my $ld   = $Config{ld} || $cc;

  my $compile_cmd = qq{$cc -c $inc -o "$obj" "$src"};
  my $link_cmd    = qq{$ld -o "$exe" "$obj" $libs};

  my $log = `$compile_cmd 2>&1`;
  my $compile_ok = $? == 0 && -e $obj;

  my $link_ok = 0;
  if ($compile_ok) {
    $log .= `$link_cmd 2>&1`;
    $link_ok = $? == 0 && -e $exe;
  }

  unless ($link_ok) {
    warn <<"DIAG";

*** OpenSSL could not be found or linked ***

Crypt::OpenSSL::X509 needs OpenSSL's headers and libraries (libssl /
libcrypto) to build. A trial compile/link against them just failed:

  compile: $compile_cmd
  link:    $link_cmd

--- output ---
$log--------------

Guessed include flags: @{[ $inc  || '(none)' ]}
Guessed library flags: @{[ $libs || '(none)' ]}

This usually means OpenSSL's development headers/libraries are not
installed, or Crypt::OpenSSL::Guess could not find them on this system.

Try:
  * installing your OS's OpenSSL "-dev"/"-devel" package, or
  * setting \$ENV{OPENSSL_PREFIX} to your OpenSSL installation, e.g.:
      OPENSSL_PREFIX=/usr/local/opt/openssl perl Makefile.PL

See https://github.com/dsully/perl-crypt-openssl-x509/issues/67 for
background on this failure mode.

(Set \$ENV{PERL_CRYPT_OPENSSL_X509_SKIP_OPENSSL_CHECK}=1 to skip this
check and proceed anyway.)
DIAG

    die "OpenSSL not found or not linkable - aborting Makefile.PL\n";
  }
}
