#####################################################################
##
##  lcwa_chio.pl -- Channel I/O
##
#####################################################################

#   convert "S" and "CX" names to unique indexes from 0-(X+1)
sub name2index {
    my ($name) = @_;
    my ($index);

    if ($name eq "SRV") {
        $index = 0;
    }
    elsif ($name =~ m|^C(\d\d)$|) {
        $index = 1 + $1;
    }
    return $index;
}

#   convert indexes back to names
sub index2name {
    my ($index) = @_;
    my ($name);

    if ($index == 0) {
        $name = "SRV";
    }
    elsif ($index > 1) {
        $name = sprintf("C%02d", $index-1);
    }
    return $name;
}

#   send to channel: &Send($ch, "...");
sub Send {
    my ($ch, $str) = @_;
    my ($from, $to);

    $from = $IO->{PROCESS}->{PID_TO_NAME}->{$$};
    $to   = $IO->{CHANNEL}->{PIPE_TO_NAME}->{&ChID($ch)};
    $ch->printf("%s %s\n", $from, $str);
    $ch->flush;
    &Log("${from} --S-> ${to} <$str>");
    return;
}

#   receive from channel: ($from, $str) = &Recv($ch);
sub Recv {
    my ($ch) = @_;
    my ($from, $to, $str);

    $to = $IO->{PROCESS}->{PID_TO_NAME}->{$$};
    while (not defined($str = $ch->getline)) {
        sleep(1);
    }
    ($from, $str) = ($str =~ m|^(\S+) (.+)\n$|);
    &Log("${to} <-R-- ${from} <$str>");
    return ($from, $str);
}

#   determine channel id
sub ChID {
    my ($obj) = @_;
    my ($id);
    
    $id = sprintf("%x", $obj);
    return $id;
}

1;
