requires 'Convert::ASN1', '0.33';

on 'configure' => sub {
  requires 'ExtUtils::MakeMaker' => '0';
  requires 'Config' => '0';
  requires 'Crypt::OpenSSL::Guess' => '0';
};

on 'test' => sub {
  requires 'Test::Pod', '>= 1.00';
};
