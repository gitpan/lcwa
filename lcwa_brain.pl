#####################################################################
##
##  lcwa_brain.pl -- Brainfile support
##
#####################################################################

sub Brain_Init {
    my (%h);

    unlink($CFG->{BRAINFILE} . ".db");
    tie(%h, 'NDBM_File', $CFG->{BRAINFILE}, O_RDWR|O_CREAT, 0640);
    $h{'CREATED'} = 1; # just make sure it gets created
    untie %h;
}

sub Brain_RememberURL {
    my ($url) = @_;
    my (%h);

    tie(%h, 'NDBM_File', $CFG->{BRAINFILE}, O_RDWR|O_CREAT, 0640);
    $h{$url} = 1;
    untie %h;
}

sub Brain_AlreadySeenURL {
    my ($url) = @_;
    my (%h, $seen);

    $seen = 0;
    tie(%h, 'NDBM_File', $CFG->{BRAINFILE}, O_RDONLY, 0640);
    $seen = 1 if ($h{$url} ne '');
    untie %h;
    return $seen;
}

sub Brain_Cleanup {
    unlink($CFG->{BRAINFILE} . ".db");
}

1;
