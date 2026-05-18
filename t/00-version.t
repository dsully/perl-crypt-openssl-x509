use Test::More tests => 1;
my $openssl_bin = $ENV{OPENSSL_PREFIX} ? "$ENV{OPENSSL_PREFIX}/bin/openssl" : 'openssl';
if ( $ENV{OPENSSL_PREFIX} && !-x $openssl_bin ) {
    diag "WARNING: $openssl_bin not found or not executable";
}
my $version = qx($openssl_bin version);
diag "Running Crypt::OpenSSL::X509 test suite against $version";
ok(1);
