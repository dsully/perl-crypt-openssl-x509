requires 'Convert::ASN1', '0.33';
requires 'version', '0.77';

on 'configure' => sub {
  requires 'ExtUtils::MakeMaker' => '0';
  requires 'Config' => '0';
  requires 'Crypt::OpenSSL::Guess' => '0';
  requires 'ExtUtils::CBuilder' => '0';
  requires 'File::Temp' => '0';
};

on 'test' => sub {
  requires 'Test::Pod', '>= 1.00';
};
