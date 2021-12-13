use Test::More tests => 17;

BEGIN { use_ok('Crypt::OpenSSL::X509') };

my @files = <certs/*.pem>;
foreach my $file (@files) {
    
  if ($file eq 'certs/broken-utf8.pem') {
    next;
  }

  ok(my $x509 = Crypt::OpenSSL::X509->new_from_file($file), 'new_from_file()');
  my $san = $x509->subjectaltname;

  ok ($san, 'subjectaltname call succeeded');

  # Mostly for debugging but this could be commented out
  foreach my $sanname (@$san) {
    for (keys %$sanname){
      print("    Found $_: ", $sanname->{$_}, "\n");
    }
  }
}


