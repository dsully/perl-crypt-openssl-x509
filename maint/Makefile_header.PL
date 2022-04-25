use Config;
use Crypt::OpenSSL::Guess qw(openssl_lib_paths openssl_inc_paths);

my %args = (
  LIBS => [openssl_lib_paths().' -lssl -lcrypto'],
  INC => openssl_inc_paths(),
);

my $cc_option_flags = '-O2 -g';

if ($Config::Config{cc} =~ /gcc/i) {
  $cc_option_flags .= $ENV{AUTHOR_TESTING} ? ' -Wall -Werror' : ' -Wall';
} else {
  $cc_option_flags .= '';
}

if ($Config{gccversion} =~ /llvm/i) {
  if ( $^O eq 'darwin' && $Config{gccversion} =~ /LLVM 12.0.[0-5]/) {
    $cc_option_flags .= ' -Wno-deprecated-declarations -Wno-compound-token-split-by-macro';
  } else {
    $cc_option_flags .= ' -Wno-deprecated-declarations';
  }

  if ($Config{gccversion} =~ /llvm 13/i) {
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
