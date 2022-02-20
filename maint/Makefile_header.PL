use Config;
use File::Spec;

my %args;

if ($^O ne 'MSWin32' and my $prefix = `brew --prefix --installed openssl\@1.1 2>@{[File::Spec->devnull]}`) {
  chomp $prefix;
  $args{INC} = "-I$prefix/include";
  $args{LIBS} = ["-L$prefix/lib -lcrypto -lssl"];
} else {
  $args{INC} = '-I/usr/local/opt/openssl/include -I/usr/local/include/openssl -I/usr/include/openssl -I/usr/local/include/ssl -I/usr/local/ssl/include';
  $args{LIBS} = ['-L/usr/local/opt/openssl/lib -L/usr/local/lib -L/usr/lib -L/usr/local/ssl/lib -lcrypto -lssl'];
}

if ($^O eq 'MSWin32') {
  if (my $libs = `pkg-config --libs libcrypto 2>nul`) {
    # strawberry perl has pkg-config
    $args{LIBS} = [ $libs ];
  } else {
    $args{LIBS} = ['-llibeay32'] if $Config{cc} =~ /cl/; # msvc with ActivePerl
    $args{LIBS} = ['-leay32']    if $Config{gccversion}; # gcc
  }
}

my $cc_option_flags = '-O2 -g -Wall -Werror';

if ($Config{gccversion} =~ /llvm/i) {
  if ( $^O eq 'darwin' && $Config{gccversion} =~ /LLVM 12.0.5/) {
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
  # Any SunStudio flags?
} else {
  $args{OPTIMIZE} = $cc_option_flags;
}
