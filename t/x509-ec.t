
use Test::More tests => 6;

BEGIN { use_ok('Crypt::OpenSSL::X509') };

my $x509 = Crypt::OpenSSL::X509->new_from_file('certs/thawte-ec.pem');
isa_ok($x509, 'Crypt::OpenSSL::X509');

my $type = $x509->pubkey_type;

SKIP: {
	skip 'Test irrelevant without ec-support in openssl', 4 unless defined($type);
	is($type, 'ec', 'ec type');
	is($x509->sig_alg_name, 'ecdsa-with-SHA384', 'sig algo');
	ok($x509->bit_length == 384, 'bit length');
	is($x509->curve, 'secp384r1', 'curve');
}
