#!@PATH_PERL@
eval 'exec @PATH_PERL@ -S $0 ${1+"$@"}'
    if $running_under_some_shell;
##   _                    
##  | | _____      _____ 
##  | |/ __\ \ /\ / / __|
##  | | (__ \ V  V / (__
##  |_|\___| \_/\_/ \___|
##                        
##  lcwc -- Last Changes Web Client
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

#   root path and URL to this package
$path_dir_root = "/e/sww/html/lc";
 $url_dir_root = "/e/sww/lc";

#   url to ourself !
$url_prg_ourselfabs = "http://sww.sdm.de/e/sww/lc/lc.cgi";
$url_prg_ourselfrel = "lc.cgi";

$path_dir_db = "$path_dir_root/lc.var/db";

#   path to the "du" program
$path_prg_du = "/bin/du";

$path_html_header = "$path_dir_root/lc.page.head.html";
$path_html_footer = "$path_dir_root/lc.page.foot.html";

#
#  SUB-PROCEDURES
#

#   process the CGI/1.0 environment variables
sub ProcessCGIEnv {
    #   split the QUERY_STRING variable
    @pairs = split(/&/, $ENV{'QUERY_STRING'});
    foreach $pair (@pairs) {
        ($name, $value) = split(/=/, $pair);
        $name =~ tr/A-Z/a-z/;
        $name = 'QUERY_STRING_' . $name;
        $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
        eval "\$$name = \"$value\"";
    }
}

#   emulate the C-library ctime() function
@dow = ( 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' );
@moy = ( 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' );
sub ctime {
    local($time) = $_[0];
    local($str);

    local($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
        localtime($time);
    $str = sprintf("%s %s %2d %02d:%02d:%02d 19%s%s",
        $dow[$wday], $moy[$mon], $mday, $hour, $min, $sec, $year,
        $isdst ? " DST" : "");
    return $str;
}

#   get database size and creation time
sub GetDBInfo {
    local($dburls, $dbsize, $dbtime);
	local(*FP);

    #   get number of URLs
	open(FP, "<$path_dir_db/db.times.nums");
	$dburls = <FP>;
	$dburls =~ s|^\s+||;
	$dburls =~ s|\s+$||;
	$dburls =~ s|\n$||;
	close(FP);

    #   get current database size
    $dbsize = `$path_prg_du -sk $path_dir_db/`;
    $dbsize =~ s|^([0-9]+)[ \t]+.*|\1|;
    #$dbsize = sprintf("%2.1f", $dbsize / 1024);
	$dbsize = sprintf("%d", $dbsize * 1024);

    #   get current database creation time
    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) =
         stat("$path_dir_db/db.times.urls");
    $dbtime  = &ctime($mtime);

    return ($dburls, $dbsize, $dbtime);
}

#   print the Content-Type: header
sub PrintContentType {
    print "Content-type: text/html\n";
    print "\n";
}

sub PrintCommonHeader {
	local(*FP);
	open(FP, "<$path_html_header");
	while (<FP>) {
		print $_;
	}
	close(FP);
}

sub PrintCommonFooter {
	local(*FP);
	open(FP, "<$path_html_footer");
	while (<FP>) {
		print $_;
	}
	close(FP);
}

sub PrintQueryForm {
    local($query) = @_[0];
    print <<"EOT"
    <table border=0 cellpadding=5 cellspacing=2>
	<tr><td>
        <form action="$url_prg_ourselfrel" method="get">
        <table cellpadding=0 cellspacing=0>
        <tr>
		<td colspan=3>
        Current Database: <b>$dburls</b> URLs, <b>$dbsize Bytes</b><br>
		Created on <b>$dbtime</b>.
		</td>
        </tr>
        <tr>
        <td align=right>
             <b>Changes since: </b>
		</td>
		<td align=left>
            <input type="text" name="query" value="$query" size="10">
		    <b>(hours)</b>
            <b><i><font color=\"#d02020\"><input type="submit"
			value="Lookup!"></font></i></b>
            <input type="reset" value="Reset">
		</td>
		</tr>
		<tr>
        <td align=right>
            <strong>Limit URLs to:</strong>
		</td>
		<td align=left>
          <input type="text" name="limit" value="$limit" size="30">
		  <b>(regex)</b>
		</td>
        </tr>
        </table>
        </form>
	</td></tr>
    </table>
EOT
    ;
}

#
#   MAIN-PROCEDURE
#

&ProcessCGIEnv;
$| = 1;

if ($QUERY_STRING_query eq '') {

    #
    #   we were called without a query= attribute, i.e.
    #   no query results occur and we just give out a fresh query form
    #

    ($dburls, $dbsize, $dbtime) = &GetDBInfo;
	$query = "24";
	$limit = "";

    &PrintContentType;
    &PrintCommonHeader;
    &PrintQueryForm($query);
    &PrintCommonFooter;

}
else {

    #
    #   we were called with a query= attribute, i.e.
    #   we give out a prefilled query form and append the query results
    #

    ($dburls, $dbsize, $dbtime) = &GetDBInfo;

    #   get the real query string
    $query = $QUERY_STRING_query;
    $query =~ s|\+| |g;

    #   get the URL limit
    $limit = $QUERY_STRING_limit;
    $limit =~ s|\+| |g;

    &PrintContentType;
    &PrintCommonHeader;
    &PrintQueryForm($query);

    #   print out the fulltext search results.
    #   this is done via ht://dig, but reformat on-the-fly
    #   the large HTML output of the "htsearch" program to a more
    #   compact Yahoo! style
    print "<br>\n";
    print "<p>\n";
    chdir("$path_dir_db");

    $now = time();
	$diff = $query * 60 * 60;
	$when = $now - $diff;

	open(FP, "<$path_dir_db/db.times.urls");
	%R = ();
	while ($line = <FP>) {
		($url, $rc, $info) = ($line =~ m|^(\S+)\s+(\S+)\s+(\S+)\n?$|);
		next if ($rc ne 'OK:200');
		($time, $bytes) = ($info =~ m|^(\d+)/(\d+)$|);

		if (($limit eq '' or $url =~ m|$limit|o) and $time >= $when) {
			if (length($url) > 70) {
				$txt=substr($url, 0, 70)."...";
			}
			else {
				$txt=$url;
			}
			$R{$time} = "${url}:::${txt}:::${bytes}";
		}
	}
	close(FP);

    print "<ul>\n";
	foreach $time (reverse(sort(keys(%R)))) {
		($url, $txt, $bytes) = ($R{$time} =~ m|^(\S+):::(\S+):::(\S+)$|);
		print "<li><a href=\"$url\">$txt</a><br>\n";
		print "last modified: <font size=-1 face=\"Helvetica,Arial\"><b>" . &ctime($time) . "</b></font>\n";
		print "size: <font size=-1 face=\"Helvetica,Arial\"><b>" . $bytes .  "</b></font> bytes<br>\n";
	}
    print "</ul>\n";

    &PrintCommonFooter;
}

#   exit gracefully and let the server be happy ;-)
exit(0);

##EOF##
