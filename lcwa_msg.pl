#####################################################################
##
##  lcwa_msg.pl -- Messages
##
#####################################################################

sub Log {
    my ($str) = @_;
    my ($time, $myself);
    local (*LOG);

    $time = Date::Format::time2str("%D %T", time());
    $myself = $IO->{PROCESS}->{PID_TO_NAME}->{$$};
    open(LOG, ">>$CFG->{LOGFILE}");
    printf(LOG "[%s %s] %s\n", $time, $myself, $str);
    close(LOG);
}

sub Verbose {
    my ($level, $str) = @_;
    if ($level <= $CFG->{VERBOSE}) {
        print STDERR "$str\n";
    }
}

sub Warning {
    my ($str) = @_;

    if (not $CFG->{QUIET}) {
        print STDERR "WARNING: $str\n";
    }
}

1;
