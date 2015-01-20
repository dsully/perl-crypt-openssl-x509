use Test::More tests => 1;
my $version = qx(openssl version);
diag "Running Crypt::OpenSSL::X509 test suite against $version";
ok(1);
