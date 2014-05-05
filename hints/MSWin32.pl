use Config;
$self->{LIBS} = ['-llibeay32'] if $Config{cc} =~ /cl/;
$self->{LIBS} = ['-leay32']    if $Config{cc} =~ /gcc/;
