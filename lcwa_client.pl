
#####################################################################
##
##  Processing
##
#####################################################################

sub ProcessURL {
    my ($url) = @_;
    my ($response, $return, @urls, $data, $method, $mtime, $bytes);

    #  only when we can expect MIME-type text/html 
    #  we actually retrieve the hole file, because
    #  only those files can have <a> anchors
    if ($url =~ m|/$| or
        $url =~ m|\.[sp]html?$| or
        $url =~ m|\.[s]cgi$|) {
        $method = "GET";
    }
    else {
        $method = "HEAD";
    }

    #  now retrieve the document
    $response = &HTTP_Fetch_URL($method, $url);
    
    #  Oooppss... actually HTML contents, then
    #  we change our mind and retrieve it again.
    #  Now with a GET request.
    if ($method eq "HEAD" and $response->content_type eq "text/html") {
        $method = "GET";
        $response = &HTTP_Fetch_URL($method, $url);
    }

    if ($response->is_success) {

        #   determine mtime/bytes
        $mtime = $response->last_modified;
        $bytes = $response->content_length;
        if ($bytes eq '' and $method eq "GET") {
            $bytes = length($response->content);
        }
        if ($mtime eq '') {
            # last chance: try to determine MTime via mod_peephole
            # if the webserver is an Apache webserver
            if ($response->server =~ m|Apache|) {
                if (&PeepholingWorks($url)) {
                    ($mtime, $bytes) = &PeepholeURL($url);
                }
            }
        }
        $mtime = "-" if ($mtime eq '');
        $bytes = "-" if ($bytes eq '');

        #   create result
        $result = "$url OK:".$response->code." ".$mtime."/".$bytes;

        #   determine URLs in contents
        @urls = ();
        if ($response->content_type eq "text/html") {
            @urls = &GetURLsFromHTML($response);
        }
    }
    elsif ($response->is_redirect) {
        $result = "$url REDIRECT:" . $response->code;
        @urls = ($response->header("Location"));
    }
    elsif ($response->is_error) {
        $result = "$url ERROR:" . $response->code;
        @urls = ();
    }

    return ($result, @urls);
}



#####################################################################
##
##  lcwa_client.pl -- Client
##
#####################################################################

sub Client {
    my ($chSend, $chRecv) = @_;
    my ($rc, $result, @URLS);

    #   inform about our startup
    &Log("Startup");
    &Send($chSend, "STARTUP");
    $rc = &Recv($chRecv);

    while (1) {
        &Send($chSend, "POP");
        $rc = &Recv($chRecv);
        if ($rc =~ m|^WAIT (\d+)|) {
            sleep($1);
        }
        elsif ($rc eq 'EMPTY') {
            last;
        }
        elsif ($rc =~ m|^URL (.+)$|) {
            #   indicate we are working
            &Send($chSend, "BUSY");
            $rc = &Recv($chRecv);

            #   lets rock on the URL
            ($result, @URLS) = &ProcessURL($1);

            #   send back the result
            &Send($chSend, "RESULT $result");
            $rc = &Recv($chRecv);

            #   optionally send back some new URLs
            foreach $url (@URLS) {
                &Send($chSend, "PUSH $url");
                $rc = &Recv($chRecv);
            }

            #   inidcate we are ready again
            &Send($chSend, "READY");
            $rc = &Recv($chRecv);
        }
    }

    #   inform server about our exit and die gracefully
    &Send($chSend, "EXIT");
    &Log("Exit");
    $rc = &Recv($chRecv);
    sleep(2);
    return;
}

1;
