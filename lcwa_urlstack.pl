#####################################################################
##
##  lcwa_urlstack.pl -- Shared URL Stack
##
#####################################################################

#   the global stack variable
#   (only used in server process)
@STACK = ();

sub Stack_Init {
    @STACK = ();
}

sub Stack_SWAPINOUT {
    # here add SWAPPING with $CFG->{SWAPFILE}
    # when your in-core URL-stack is too large
    # (e.g. when using this agent on the Internet ;-)
    return;
}

sub Stack_PUSH {
    my ($url) = @_;
    my ($rc);

    #   first really make sure this is a new URL
    #   and also is acceptable accoring to the
    #   configured rules
    if (&Brain_AlreadySeenURL($url)) {
        &Log("URL $url ALREADY SEEN: IGNORED");
        return 0;
    }
    if (not &URL_Acceptable($url)) {
        &Log("URL $url NOT ACCEPTABLE: IGNORED");
        return 0;
    }

    #   ok, now push it on the stack
    push(@STACK, $url);
    &Stack_SWAPINOUT;

    #   and remember that we have seen it now
    &Brain_RememberURL($url);

    #   say URL was really pushed...
    return 1;
}

sub Stack_POP {
    my ($rc);

    if ($#STACK == -1) {
        #   now more elements, stack is empty
        return '';
    }

    if ($CFG->{ALGORITHM} eq 'd') {
        #   deep search, 
        #   we retrieve from top/start of stack
        $rc = pop(@STACK);
    }
    elsif ($CFG->{ALGORITHM} eq 'w') {
        #   width search, 
        #   we retrieve from bottom/end of stack
        $rc = shift(@STACK);
    }
    else {
        #   random search, 
        #   we retrieve from any point of stack
        if ($#STACK == 0) {
            $rc = pop(@STACK);
        }
        else {
            my $i = rand($#STACK+1);
            $i = ($i % $#STACK) if ($i < 0 or $i > $#STACK);
            $rc = splice(@STACK, $i, 1);
        }
    }
    &Stack_SWAPINOUT;
    return $rc;
}

sub Stack_Cleanup {
    @STACK = ();
}

1;
