use 5.00503;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Crypt::OpenSSL::X509',
	'VERSION_FROM'	=> 'X509.pm',
	'PREREQ_PM'		=> {},
	($] >= 5.005 ?
	(ABSTRACT_FROM => 'X509.pm',
	AUTHOR     => 'Dan Sully <daniel@cpan.org>') : ()),
	'LIBS'		=> ['-lcrypto'],
	'DEFINE'	=> '-DPERL5 -Wall',
	'INC'		=> '',
);
