#####################################################################
##
##  lcwa_peephole.pl -- Peepholing with Apache
##
#####################################################################

%PEEPHOLEABLE = ();

sub PeepholingWorks {
    my ($url) = @_;
    my ($server, $testurl, $response, $info);

    #   determine server out of URL
    $url = new URI::URL($url);
    $server = $url->host . ":" . $url->port;

    #   if no information is already known
    #   then determine it now
    if ($PEEPHOLEABLE{$server} eq '') {
        $testurl = "http://$server/peep/";
        $response = &HTTP_Fetch_URL("GET", $url);
        if ($response->is_success) {
            $PEEPHOLEABLE{$server} = 1;
        }
        else {
            $PEEPHOLEABLE{$server} = 0;
        }
    }

    #   return the result
    return $PEEPHOLEABLE{$server};
}

sub PeepholeURL {
    my ($url) = @_;
    my ($response, $mtime, $bytes);

    #   create peepholing URL
    $url = new URI::URL($url);
    $url->path("/peep" . $url->path);

    #   fetch the peephole page
    $response = &HTTP_Fetch_URL("GET", $url->as_string);

    $mtime = "-";
    $bytes = "-";
    if ($response->is_success) {
        #   grep out the informations
        if ($response->content =~ m|MTime:\s+(\d+)|is) {
            $mtime = $1;
        }
        if ($response->content =~ m|Bytes:\s+(\d+)|is) {
            $bytes = $1;
        }
    }
    return ($mtime, $bytes);
}

1;
