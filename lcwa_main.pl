#!@PATH_PERL@
eval 'exec @PATH_PERL@ -S $0 ${1+"$@"}'
    if $running_under_some_shell;
##   _                    
##  | | _____      ____ _ 
##  | |/ __\ \ /\ / / _` |
##  | | (__ \ V  V / (_| |
##  |_|\___| \_/\_/ \__,_|
##                        
##  lcwa -- Last Changes Web Agent
##
##  ======================================================================
##
##  Copyright (c) 1997 Ralf S. Engelschall, All rights reserved.
##
##  This program is free software; it may be redistributed and/or modified
##  only under the terms of either the Artistic License or the GNU General
##  Public License, which may be found in the distribution of this program.
##  Look at the files ARTISTIC and COPYING.
##
##  This program is distributed in the hope that it will be useful, but
##  WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
##  Artistic License or the GNU General Public License for more details.
##
##  ======================================================================
##
##  lcwa_main.pl -- Main procedure
##

require 5.004;
require "lcwa_boot.pl";

use Getopt::Long;
use Date::Format;
use IO::Handle;
use IO::File;
use IO::Pipe;
use NDBM_File;
use Fcntl;
use Bit::Vector;
use LWP::UserAgent;
use URI::URL;
use HTTP::Request;
use HTTP::Response;

require "lcwa_vers.pl";
require "lcwa_msg.pl";
require "lcwa_brain.pl";
require "lcwa_html.pl";
require "lcwa_http.pl";
require "lcwa_urlstack.pl";
require "lcwa_urlcheck.pl";
require "lcwa_peephole.pl";
require "lcwa_prop.pl";
require "lcwa_chio.pl";
require "lcwa_client.pl";
require "lcwa_server.pl";

package main;

#####################################################################
##
##  Configuration
##
#####################################################################

sub usage {
    print STDERR "Usage: lcwa [options] [url ...]\n";
    print STDERR "   where options are\n";
    print STDERR "   -D file       database file (uses stdout when missing)\n";
    print STDERR "   -c num        number of used crawling clients\n";
    print STDERR "   -a type       crawling algorithm (d=depth, w=width=default)\n";
    print STDERR "   -d [+]num     restrict crawling depth\n";
    print STDERR "   -r pattern    restrict crawling URLs\n";
    print STDERR "   -i pattern    explictly include URLs for crawling\n";
    print STDERR "   -e pattern    explictly exclude URLs for crawling\n";
    print STDERR "   -b file       use file temporarily for storing the crawling brain\n";
    print STDERR "   -s file       use file temporarily for swapping out the crawling stack\n";
    print STDERR "   -l file       use file for log messages\n";
    print STDERR "   -v level      verbose mode\n";
    print STDERR "   -V            display version id\n";
    exit(1);
}

sub version {
    print STDERR $Vers::LCWA_Hello . "\n";
    exit(0);
}

$opt_D = '-';
$opt_c = 2;
$opt_a = 'w';
$opt_d = -1;
@opt_r = ();
@opt_i = ();
@opt_e = ();
$opt_b = 'lcwa.brain.tmp';
$opt_s = 'lcwa.swap.tmp';
$opt_l = 'lcwa.log';
$opt_q = 0;
$opt_h = 0;
$opt_v = -1;
$opt_V = 0;

@OPTSPEC = (
    "D|dbfile=s",
    "c|clients=i",
    "a|algorithm=s",
    "d|depth=s",
    "r|restrict=s@",
    "i|include=s@",
    "e|exclude=s@",
    "b|brainfile=s",
    "s|swapfile=s",
    "l|logfile=s",
    "q|quiet",
    "h|help",
    "v|verbose=i",
    "V|version"
);

$Getopt::Long::bundling = 1;
$Getopt::Long::getopt_compat = 0;

&usage if (not Getopt::Long::GetOptions(@OPTSPEC));
&usage if ($opt_h);
&version if ($opt_V);

$CFG = {};

$CFG->{CLIENTS}      = $opt_c;
$CFG->{URL_DEPTH}    = {};
$CFG->{URL_RESTRICT} = \@opt_r;
$CFG->{URL_INCLUDE}  = \@opt_i;
$CFG->{URL_EXCLUDE}  = \@opt_e;
$CFG->{ALGORITHM}    = $opt_a;
$CFG->{BRAINFILE}    = $opt_b;
$CFG->{SWAPFILE}     = $opt_s;
$CFG->{LOGFILE}      = $opt_l;
$CFG->{QUIET}        = $opt_q;
$CFG->{VERBOSE}      = $opt_v;
$CFG->{START_URLS}   = [];
$CFG->{DBFILE}       = {};

if ($#ARGV == -1 or ($#ARGV == 0 and $ARGV[0] eq "-")) {
    while (<STDIN>) {
        if (m|^\s*(\S+)\s*\n?$|) {
            push(@{$CFG->{START_URLS}}, $1);
        }
    }
}
else {
    @{$CFG->{START_URLS}} = @ARGV;
}

my $max = 0;
foreach $url (@{$CFG->{START_URLS}}) {
    my $urlobj = new URI::URL $url;
    my @path = $urlobj->path_components;
    if ($max < $#path) {
        $max = $#path;
    }
}
if ($opt_d == -1) {
    $CFG->{URL_DEPTH}->{MIN} = 1;
    $CFG->{URL_DEPTH}->{MAX} = 999999;
}
elsif ($opt_d =~ m|^([0-9]+)$|) {
    $CFG->{URL_DEPTH}->{MIN} = $1;
    $CFG->{URL_DEPTH}->{MAX} = $1;
}
elsif ($opt_d =~ m|^<([0-9]+)$|) {
    $CFG->{URL_DEPTH}->{MIN} = 1;
    $CFG->{URL_DEPTH}->{MAX} = $1-1;
}
elsif ($opt_d =~ m|^>([0-9]+)$|) {
    $CFG->{URL_DEPTH}->{MIN} = $1+1;
    $CFG->{URL_DEPTH}->{MAX} = 999999;
}
elsif ($opt_d =~ m|^([0-9]+)-([0-9]+)$|) {
    $CFG->{URL_DEPTH}->{MIN} = $1;
    $CFG->{URL_DEPTH}->{MAX} = $2;
}
elsif ($opt_d =~ m|^\+([0-9]+)$|) {
    $CFG->{URL_DEPTH}->{MIN} = $max;
    $CFG->{URL_DEPTH}->{MAX} = $max+$1;
}
elsif ($opt_d =~ m|^-([0-9]+)$|) {
    $CFG->{URL_DEPTH}->{MIN} = $max;
    $CFG->{URL_DEPTH}->{MAX} = $max-$1;
}

$CFG->{DBFILE}->{NAME} = $opt_D;
if ($CFG->{DBFILE}->{NAME} eq '-') {
    $fh = new IO::Handle;
    $fh->fdopen(fileno(STDOUT), 'w');
}
else {
    $fh = new IO::File;
    $fh->open($CFG->{DBFILE}->{NAME}, 'w');
}
$fh->autoflush(1); 
$CFG->{DBFILE}->{FH} = $fh;


#####################################################################
##
##  Exit Handler
##
#####################################################################

sub exit_handler { 
    my ($sig) = @_;
    my ($fh, $myself);

    $myself = $IO->{PROCESS}->{PID_TO_NAME}->{$$};
    print STDERR "*** LCWA/$myself: Caught a SIG$sig -- shutting down.\n";

    if ($myself eq "SRV") {
        $fh = $CFG->{DBFILE}->{FH};
        $fh->close;
        &Brain_Cleanup;
    }
    exit(0);
}

$SIG{'INT'}  = \&exit_handler;
$SIG{'QUIT'} = \&exit_handler;
$SIG{'TERM'} = \&exit_handler;


#####################################################################
##
##  Startup
##
#####################################################################

$IO = {};
$IO->{CHANNEL} = {};
$IO->{PROCESS} = {};

#   create the channels:
#
#   the channel from the clients to the server is shared one 
#   for all clients and which is duplicated through fork() while 
#   the channel from the server to the each client is a private one
#   which is explicitly created.
#

$IO->{CHANNEL}->{PIPE} = {};
$IO->{CHANNEL}->{PIPE_TO_NAME} = {};
$IO->{CHANNEL}->{NAME_TO_PIPE} = {};

my $pipe = new IO::Pipe;
$IO->{CHANNEL}->{PIPE}->{SERVER} = $pipe;
$IO->{CHANNEL}->{PIPE_TO_NAME}->{&ChID($pipe)} = "SRV";
$IO->{CHANNEL}->{NAME_TO_PIPE}->{"SRV"} = $pipe;

$IO->{CHANNEL}->{PIPE}->{CLIENT} = [];
for (my $i = 0; $i < $CFG->{CLIENTS}; $i++) {
    my $pipe = new IO::Pipe;
    my $name = sprintf("C%02d", $i);
    $IO->{CHANNEL}->{PIPE}->{CLIENT}->[$i] = $pipe;
    $IO->{CHANNEL}->{PIPE_TO_NAME}->{&ChID($pipe)} = $name;
    $IO->{CHANNEL}->{NAME_TO_PIPE}->{$name} = $pipe;
}

#   run the clients:
#
#   via pre-forking where each client gets its
#   channels to use

$IO->{PROCESS}->{PID}  = {};
$IO->{PROCESS}->{PID_TO_NAME} = {};
$IO->{PROCESS}->{NAME_TO_PID} = {};

$IO->{PROCESS}->{PID}->{SERVER} = $$;
$IO->{PROCESS}->{PID_TO_NAME}->{$$} = "SRV";
$IO->{PROCESS}->{NAME_TO_PID}->{"SRV"} = $$;

$IO->{PROCESS}->{PID}->{CLIENT} = [];
for (my $i = 0; $i < $CFG->{CLIENTS}; $i++) {
    my $id = sprintf("C%02d", $i);
    if (my $pid = fork()) {
        #   PARENT
        $IO->{PROCESS}->{PID}->{CLIENT}->[$i] = $pid;
        $IO->{PROCESS}->{PID_TO_NAME}->{$pid} = $id;
        $IO->{PROCESS}->{NAME_TO_PID}->{$id} = $pid;
    }
    else {
        #   CHILD
        $0 = "LCWA [$id]";
        $IO->{PROCESS}->{PID}->{CLIENT}->[$i] = $$;
        $IO->{PROCESS}->{PID_TO_NAME}->{$$} = $id;
        $IO->{PROCESS}->{NAME_TO_PID}->{$id} = $$;

        #   adjust the channel for the client side
        my $chSend = $IO->{CHANNEL}->{PIPE}->{SERVER};
        my $chRecv = $IO->{CHANNEL}->{PIPE}->{CLIENT}->[$i];
        $chSend->writer();
        $chRecv->reader();
        autoflush $chSend 1;

        #   run the client procedure
        &Client($chSend, $chRecv);
        exit(0);
    }
}

#   adjust the channels for the server side
for (my $i = 0; $i < $CFG->{CLIENTS}; $i++) {
    my $chSend = $IO->{CHANNEL}->{PIPE}->{CLIENT}->[$i];
    $chSend->writer();
    autoflush $chSend 1;
}
my $chRecv = $IO->{CHANNEL}->{PIPE}->{SERVER};
$chRecv->reader();


#   run server
$0 = "LCWA [S]";
&Server;

#   die gracefully
exit(0);


##EOF##
