#####################################################################
##
##  lcwa_urlcheck.pl -- URL Checks
##
#####################################################################

#   check if URL is acceptable according
#   to configuraed rules and patterns
sub URL_Acceptable {
    my ($url) = @_;
    my ($pat, $ok, $urlobj, @path);

    #  convert URL string to an URL object
    $urlobj = new URI::URL $url;

    #  first implicit check:
    #  only HTTP URLs are acceptable 
    #  because our clients can only 
    #  handle those ones.
    if ($urlobj->scheme ne 'http') {
        return 0;
    }

    #  check for path depth
    @path = $urlobj->path_components;
    if (not ($CFG->{URL_DEPTH}->{MIN} <= $#path and
                                         $#path <= $CFG->{URL_DEPTH}->{MAX})) {
        return 0;
    }

    #  match against restrict patterns:
    #  ALL HAVE TO MATCH, ELSE NOT ACCEPTABLE
    if ($#{$CFG->{URL_RESTRICT}} != -1) {
        foreach $pat (@{$CFG->{URL_RESTRICT}}) {
            if ($url !~ m|$pat|) {
                return 0;
            }
        }
    }

    #  match against include patterns:
    #  AT LEAST ONE HAS TO MATCH, ELSE NOT ACCEPTABLE
    if ($#{$CFG->{URL_INCLUDE}} != -1) {
        $ok = 0;
        foreach $pat (@{$CFG->{URL_INCLUDE}}) {
            if ($url =~ m|$pat|) {
                $ok = 1;
            }
        }
        if ($ok == 0) {
            return 0;
        }
    }

    #  match against exclude patterns:
    #  ALL HAVE NOT TO MATCH, ELSE NOT ACCEPTABLE
    if ($#{$CFG->{URL_EXCLUDE}} != -1) {
        $ok = 1;
        foreach $pat (@{$CFG->{URL_EXCLUDE}}) {
            if ($url =~ m|$pat|) {
                $ok = 0;
            }
        }
        if ($ok == 0) {
            return 0;
        }
    }

    #  URL is acceptable...
    return 1;
}

1;
