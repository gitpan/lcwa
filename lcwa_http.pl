#####################################################################
##
##  lcwa_http.pl -- URL Fetching via HTTP
##
#####################################################################

#   define our own Web user agent 
#   which has disabled auto-redirects
package LWP::MyUA;
@ISA = qw(LWP::UserAgent);
sub redirect_ok { return 0; }
package main;

#   init
sub HTTP_Fetch_Init {
}

#   actually fetch the URL
sub HTTP_Fetch_URL {
    my ($method, $url) = @_;
    my ($ua, $headers, $request, $response);

    #   create an user agent object
    $ua = new LWP::MyUA $Vers::LCWA_WebID, "rse\@engelschall.com";

    #   create a request
    $url = new URI::URL($url);
    $headers = new HTTP::Headers;
    $request = new HTTP::Request($method, $url, $headers);

    #   perfrom the request
    $response = $ua->request($request);
    
    return $response;
}

#   cleanup
sub HTTP_Fetch_Cleanup {
}

1;
