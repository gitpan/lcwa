
use ExtUtils::MakeMaker;

require "./Long.pm";

WriteMakefile(
	VERSION   => $Getopt::Long::VERSION,
	NAME      => "Getopt::Long",
);

