#####################################################################
##
##  lcwa_prop.pl -- Console Propeller Message
##
#####################################################################

@propchr  = ( '|', '/', '-', '\\' );
$propcnt  = 0;
$proplast = 0;
$proppeer = "";

sub Prop {
    my ($active, $peer, $urlSeen, $urlAccept, $urlDone, $urlLast) = @_;
    my ($line, $p, $url);
   
    if ($CFG->{VERBOSE} == 1) {
        if ($urlDone > $proplast) {
            $proplast = $urlDone;
            $proppeer = $peer;
            $propcnt = ($propcnt + 1) % 4;
        }
        $p = $propchr[$propcnt];
        if (length($urlLast) > 40) {
            $url = substr($urlLast, 0, 40) . "..";
        }
        else {
            $url = sprintf("%-42s", $urlLast);
        }
        $url = sprintf("%02d %s %s", $active, $peer, $url);
        $line = sprintf("\r                             %s\r" .
                        "S:%06d A:%06d D:%06d %s\b", 
                        $url, $urlSeen, $urlAccept, $urlDone, $p);
        print STDERR $line;
    }
}

1;
