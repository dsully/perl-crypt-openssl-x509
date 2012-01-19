
use Test::More tests => 56;

BEGIN { use_ok('Crypt::OpenSSL::X509') };

ok(my $x509 = Crypt::OpenSSL::X509->new_from_file('certs/vsign1.pem'), 'new_from_file()');

ok($x509->serial() eq '325033CF50D156F35C81AD655C4FC825', 'serial()');

ok($x509->fingerprint_md5() eq '51:86:E8:1F:BC:B1:C3:71:B5:18:10:DB:5F:DC:F6:20', 'fingerprint_md5()');
ok($x509->fingerprint_sha1() eq '78:E9:DD:06:50:62:4D:B9:CB:36:B5:07:67:F2:09:B8:43:BE:15:B3', 'fingerprint_sha1()');

ok($x509->exponent() eq '10001', 'exponent()');
ok($x509->pub_exponent() eq '10001', 'pub_exponent()'); # Alias

ok($x509->issuer() eq 'C=US, O=VeriSign, Inc., OU=Class 1 Public Primary Certification Authority', 'issuer()');
ok($x509->subject() eq 'C=US, O=VeriSign, Inc., OU=Class 1 Public Primary Certification Authority', 'subject()');

ok($x509->is_selfsigned(), 'is_selfsigned()');

# For some reason the hash hash changed with v1.0.0
# Verified with the openssl binary.
if (Crypt::OpenSSL::X509::OPENSSL_VERSION_NUMBER >= 0x10000000) {
  ok($x509->hash() eq '24ad0b63', 'hash()');
} else {
  ok($x509->hash() eq '2edf7016', 'hash()');
}

ok($x509 = Crypt::OpenSSL::X509->new_from_file('certs/thawte.pem'), 'new_from_file()');

ok($x509->email() eq 'server-certs@thawte.com', 'email()');

is($x509->version, '02', 'version');

is($x509->sig_alg_name, 'md5WithRSAEncryption', 'version');

is($x509->bit_length, 1024, 'bit_length()');

ok($x509->num_extensions() eq '1', 'num_extensions()');

ok($exts = $x509->extensions_by_oid(), 'extension_by_oid()');

ok($x509->has_extension_oid("2.5.29.19"), 'has_extension_oid(2.5.29.19)');

is($$exts{"2.5.29.19"}->object()->name(),"X509v3 Basic Constraints", "Extension->object()->name()");

ok($$exts{"2.5.29.19"}->is_critical(), "basic constraints is critical");
ok($$exts{"2.5.29.19"}->basicC("ca"), 'basicConstraints CA: TRUE 2.4.1');

ok($x509_b = Crypt::OpenSSL::X509->new_from_file('certs/balt.pem'), 'new_from_file()');
ok(my $exts_b = $x509_b->extensions_by_name(), "extensions_by_name()");
ok(not($$exts_b{'subjectKeyIdentifier'}->is_critical()), "subjectKeyIdentifier not critical");
my $subkeyid = (join ":", map{sprintf "%X", ord($_)} split //, $$exts_b{'subjectKeyIdentifier'}->keyid_data());
ok($subkeyid eq "E5:9D:59:30:82:47:58:CC:AC:FA:8:54:36:86:7B:3A:B5:4:4D:F0", "Extension{subjectKeyID}->keyid_data()");

ok($$exts_b{'keyUsage'}->is_critical(), "keyUsage is critical");
my %key_hash = $$exts_b{'keyUsage'}->hash_bit_string();
ok($key_hash{'Certificate Sign'}, "Extension->hash_bit_string()");

isa_ok($x509->subject_name(), "Crypt::OpenSSL::X509::Name", 'subject_name()');
isa_ok($x509->issuer_name(), "Crypt::OpenSSL::X509::Name", 'issuer_name()');
is($x509->subject_name()->as_string(), 'C=ZA, ST=Western Cape, L=Cape Town, O=Thawte Consulting cc, OU=Certification Services Division, CN=Thawte Server CA, emailAddress=server-certs@thawte.com', 'subject_name()->as_string()');
is($x509->issuer_name()->as_string(), 'C=ZA, ST=Western Cape, L=Cape Town, O=Thawte Consulting cc, OU=Certification Services Division, CN=Thawte Server CA, emailAddress=server-certs@thawte.com', 'issuer_name()->as_string()');

ok(my $subject_name_entries = $x509->subject_name()->entries(), 'subject_name()->entries()');
is(@$subject_name_entries[0]->as_string(),"C=ZA",'Name_Entry->as_string()');
is(@$subject_name_entries[2]->as_long_string(),"localityName=Cape Town",'Name_Entry->as_long_string()');
is(@$subject_name_entries[1]->type(),"ST",'Name_Entry->type');
is(@$subject_name_entries[1]->long_type(),"stateOrProvinceName",'Name_Entry->long_type');
is(@$subject_name_entries[1]->value(),"Western Cape",'Name_Entry->value');

ok($x509->subject_name()->has_entry("ST"),'Name->has_entry');
ok($x509->subject_name()->has_long_entry("stateOrProvinceName"),'Name->has_entry');
ok($x509->subject_name()->has_oid_entry("2.5.4.3"),'Name->has_oid_entry([CN])');
ok(not($x509->subject_name()->has_oid_entry("0.9.2342.19200300.100.1.25")),'not Name->has_oid_entry([DC])');
is($x509->subject_name()->get_index_by_type("ST"),1,'Name->get_index_by_type');
is($x509->subject_name()->get_index_by_long_type("localityName"),2,'Name->get_index_by_long_type');

isa_ok($x509->subject_name()->get_entry_by_type("ST"),"Crypt::OpenSSL::X509::Name_Entry",'Name->get_entry_by_type');
ok($x509->subject_name()->get_entry_by_type("ST")->is_printableString(),'Name_Entry->is_printableString');
ok(not($x509->subject_name()->get_entry_by_type("ST")->is_asn1_type(Crypt::OpenSSL::X509::V_ASN1_UTF8STRING)),'Name_Entry->is_asn1_type');

# Check new_from_string / as_string round trip.
{
  my $x509 = Crypt::OpenSSL::X509->new_from_string(
    Crypt::OpenSSL::X509->new_from_file('certs/balt.pem')->as_string(1),
  1);

  ok($x509);
  ok($x509->serial() eq '020000B9', 'serial()');
}

{
  ok(my $x509 = Crypt::OpenSSL::X509->new_from_file('certs/dsa.pem'));
  ok($x509->issuer() eq 'C=CH, ST=Some-State, O=DSA Test Certificate, CN=IAmABogusCertificate');
  ok($x509->subject() eq 'C=CH, ST=Some-State, O=DSA Test Certificate, CN=IAmABogusCertificate');
  ok($x509->dsa_p() eq 'AB2F32F72343D41B46892042EABADE8EB600BCDA554A1332970E99B7718608F47302EF8EBD27B34B0E853FF0367F12EBD8E1FFCEC459A973D9C31DFB337EEB817A8F3FFB3BACCD47D267415964130FF244C46345FCBD8515B47A3FA72D5734093B32D425AEE7393AAAF90A864429B2E65C0B5218DA7DD463747A084B1DCDB04F');
  ok($x509->dsa_q() eq 'CB45AF5DDC60055CB37ABDB07D5EDFE6B6813F4F');
  ok($x509->dsa_g() eq '550BAF94A758CE60A346F062881BEA66322106B18A464C1D1FA1D77775FF7F38083C374A07C01BFAD012EDC1CB0A1F8EDEB4A445208F69759786E490838CE2E2CDBA6C40496B85E318079A22F215D544D06DBFCF51C697B52DD600A413D3CAA16ED0C36FD38EC7F78C3B717C256D5BF89B7651759763B9D1FD65923BF42B4E48');
  ok($x509->dsa_y() eq '702B3FF15250593BA8D586F50EF50358209D4C9587966EA212349E0B3C25D38A1EC425B1B0BD500E465C309AA4BCF0348C62BCCE23F5E20F23E6A0751DBB8256D74D2FD986C83120AB25CA4CBBAAC8479D47DECB60DB5779D1759DB383C4E4A6028BB9B02EFC9EEBD6CC624DB519DCB3A3FB3A386DE9F954A5A241A3DCEEB2D');
}
