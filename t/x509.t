
use Test::More tests => 9;

BEGIN { use_ok('Crypt::OpenSSL::X509') };

ok(my $x509 = Crypt::OpenSSL::X509->new_from_file('certs/vsign1.pem'), 'new_from_file()');

ok($x509->serial() eq '325033CF50D156F35C81AD655C4FC825', 'serial()');

ok($x509->fingerprint_md5() eq '51:86:E8:1F:BC:B1:C3:71:B5:18:10:DB:5F:DC:F6:20', 'fingerprint_md5()');

ok($x509->issuer() eq 'C=US, O=VeriSign, Inc., OU=Class 1 Public Primary Certification Authority', 'issuer()');
ok($x509->subject() eq 'C=US, O=VeriSign, Inc., OU=Class 1 Public Primary Certification Authority', 'subject()');

ok($x509->hash() eq '2edf7016', 'hash()');

ok($x509 = Crypt::OpenSSL::X509->new_from_file('certs/thawte.pem'), 'new_from_file()');

ok($x509->email() eq 'server-certs@thawte.com', 'email()');
