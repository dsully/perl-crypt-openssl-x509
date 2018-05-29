use Config;
if (my $libs = `pkg-config --libs libcrypto 2>nul`) {
  # strawberry perl has pkg-config
  $self->{LIBS} = [ $libs ];
}
else {
  $self->{LIBS} = ['-llibeay32'] if $Config{cc} =~ /cl/; # msvc with ActivePerl
  $self->{LIBS} = ['-leay32']    if $Config{gccversion}; # gcc
}
