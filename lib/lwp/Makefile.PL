
require 5.004;  # LWP needs this perl version

use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'libwww-perl',
   VERSION_FROM  => 'lib/LWP.pm',
   'clean'       => { FILES => '$(EXE_FILES)' },
   'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

# Determine things that should *not* be installed
sub MY::libscan {
    my($self, $path) = @_;
    return '' if $path =~ m/.(pl|dtd|sgml)$/;
    return '' if $path =~ m:\bCVS/:;
    return '' if $path =~ m/~$/;
    $path;
}

