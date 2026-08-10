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
  unless (eval { require ExtUtils::CBuilder; require File::Temp; 1 }) {
    warn "Skipping OpenSSL link check: ExtUtils::CBuilder unavailable ($@)\n";
  } else {
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $src = "$dir/openssl_check.c";

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
    close $fh or die "Can't write $src: $!";

    my $trial_inc  = $args{INC} || '';
    my $trial_libs = $args{LIBS}[0] || '';

    my $builder = ExtUtils::CBuilder->new(quiet => 1);

    my @extra_compiler_flags = grep { $_ ne '-Werror' } $builder->split_like_shell(
      join ' ', grep { defined && length } $trial_inc, $args{CCFLAGS}, $args{OPTIMIZE}
    );

    require ExtUtils::Liblist;
    my (undef, undef, $ldloadlibs) = ExtUtils::Liblist->ext($trial_libs, 0);

    # A real XS module build implicitly gets Perl's own system libraries
    # (e.g. -lws2_32 on Windows, needed by OpenSSL's static libs for
    # Winsock symbols) via linking against libperl. This standalone trial
    # program doesn't link against libperl, so without adding them back
    # explicitly, the trial can fail with unresolved system symbols on a
    # platform where the real build would succeed. $Config{perllibs} (or
    # $Config{libs}) is the portable source for this, but isn't reliably
    # populated on every Windows perl distribution, so also fall back to
    # OpenSSL's own well-known Windows system dependencies explicitly
    # (harmless no-ops elsewhere: unused/duplicate flags, never referenced).
    my $perllibs = defined $Config{perllibs} ? $Config{perllibs} : $Config{libs};
    my @platform_libs = $^O =~ /MSWin32|msys|cygwin/i
      ? qw(-lws2_32 -lgdi32 -lcrypt32 -luser32 -ladvapi32)
      : ();
    my @extra_linker_flags = $builder->split_like_shell(
      join ' ', grep { defined && /\S/ } $ldloadlibs, $perllibs, @platform_libs
    );

    my $ok = eval {
      my $obj = $builder->compile(
        source               => $src,
        extra_compiler_flags => \@extra_compiler_flags,
      );
      $builder->link_executable(
        objects            => [$obj],
        extra_linker_flags => \@extra_linker_flags,
      );
      1;
    };
    my $err = $@ || '(no error captured)';
    $err =~ s/ at \S+ line \d+\.?\n?\z//;

    unless ($ok) {
      warn <<"DIAG";

*** OpenSSL could not be found or linked ***

Crypt::OpenSSL::X509 needs OpenSSL's headers and libraries (libssl /
libcrypto) to build. A trial compile/link against them just failed
(any compiler/linker output should appear above this message):

  $err
Guessed include flags: @{[ $trial_inc  || '(none)' ]}
Guessed library flags: @{[ $trial_libs || '(none)' ]}

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
}
