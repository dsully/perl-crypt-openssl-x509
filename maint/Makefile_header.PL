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

my $cc_option_flags = " -DOPENSSL_API_COMPAT=$api_ver -O2 -g";

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
