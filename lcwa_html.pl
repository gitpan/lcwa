#####################################################################
##
##  lcwa_html.pl -- HTML Content Parsing
##
#####################################################################

#   parse out all URLs of a HTML page
sub GetURLsFromHTML {
    my ($response) = @_;
    my (@urls, %TAGS, %list, $content, $intag, $key, $link);

    #   define list of tags and attributes
    %TAGS = (
        "body"  => "background",
        "img"   => "src",
        "a"     => "href",
        "frame" => "src",
    );

    #   extract URLs
    $content = $response->content;
    loop: while ($content =~ s|<([^>]*)>||) {
        $intag=$1;
        $key;
        foreach $key (keys(%TAGS)) {
            if ($intag =~ m|^\s*$key\s+|i) {
                if ($intag =~ m|\s+$TAGS{$key}\s*=\s*"([^"]*)"|i) {
                    $link = $1;
                    $link =~ s|[\n\r]||sg;
                    $list{$link} = 1;
                    next loop;
                }
                elsif ($intag =~ m|\s+$TAGS{$key}\s*=\s*([^\s]+)|i) {
                    $link = $1;
                    $link =~ s|[\n\r]||sg;
                    $list{$link} = 1;
                    next loop;
                }
            }
        }
    }

    #   cleanup
    @urls = ();
    foreach $url (keys(%list)) {
        $url =~ s|#.+$||;
        if ($url ne '') {
            $u = new URI::URL $url, $response->base;
            push(@urls, $u->abs);
        }
    }
    return @urls;
}


1;
