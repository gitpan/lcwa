
#####################################################################
##
##  Result Output
##
#####################################################################

sub mkResultEntry {
    my ($url, $rc, $info) = @_;
    my ($fh);
    
    $fh = $CFG->{DBFILE}->{FH};
    $fh->printf("%s %s %s\n", $url, $rc, $info);
    return;
}


#####################################################################
##
##  Server
##
#####################################################################

sub Server {
    my ($chRecv, @chSend, $running, $working, $peer, $active, $urlSeen, $urlAccept, $urlDone, $urlLast, $rc);

    &Log("Startup");
    &Brain_Init;
    &Stack_Init;

    $urlSeen = 0;
    $urlDone = 0;
    $urlLast = "";

    foreach $url (@{$CFG->{START_URLS}}) {
        $rc = &Stack_PUSH($url);
        $urlAccept++ if $rc == 1;
        $urlSeen++;
        $urlLast = $url;
    }

    $chRecv = $IO->{CHANNEL}->{PIPE}->{SERVER};
    $running = new Bit::Vector(1+$CFG->{CLIENTS});
    $working = new Bit::Vector(1+$CFG->{CLIENTS});
    $active = 0;

    #   start receiver loop
    while (($peer, $cmd) = &Recv($chRecv)) {
        $chSend = $IO->{CHANNEL}->{NAME_TO_PIPE}->{$peer};

        &Prop($working->Norm, $peer, $urlSeen, $urlAccept, $urlDone, $urlLast);

        if ($cmd eq "STARTUP") {
            #   client startup
            $running->Bit_On(&name2index($peer));
            &Send($chSend, "OK");
        }
        elsif ($cmd eq "EXIT") {
            #   client exit
            $running->Bit_Off(&name2index($peer));
            &Send($chSend, "OK");
            last if ($running->Norm == 0)
        }
        elsif ($cmd eq 'BUSY') {
            #   client now active
            $working->Bit_On(&name2index($peer));
            &Send($chSend, "OK");
        }
        elsif ($cmd eq 'READY') {
            #   client now inactive
            $working->Bit_Off(&name2index($peer));
            &Send($chSend, "OK");
        }
        elsif ($cmd =~ m|^POP$|) {
            #   stack pop
            if ($url = &Stack_POP()) {
                &Send($chSend, "URL $url");
                $active++;
            }
            else {
                if ($active > 0) {
                    &Send($chSend, "WAIT 5");
                }
                else {
                    &Send($chSend, "EMPTY");
                }
            }
        }
        elsif ($cmd =~ m|^PUSH\s+(\S+)\s*$|) {
            #   stack push
            $rc = &Stack_PUSH($1);
            $urlAccept++ if $rc == 1;
            $urlSeen++;
            &Send($chSend, "OK");
        }
        elsif ($cmd =~ m|^RESULT\s+(\S+)\s+(.+?)\s*$|) {
            #   processing result
            $url = $1;
            $rc  = $2;
            if ($rc =~ m|^(OK:\d+)\s+(.+)\s*$|) {
                &mkResultEntry($url, $1, $2);
            }
            else {
                &mkResultEntry($url, $rc, "-");
            }
            &Send($chSend, "OK");
            $urlDone++;
            $urlLast = $1;
            $active--;
        }
    }

    &Stack_Cleanup;
    &Brain_Cleanup;
    sleep(2);
    &Log("Exit");
}


1;
