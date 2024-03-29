
package IO::Handle;

=head1 NAME

IO::Handle - supply object methods for I/O handles

=head1 SYNOPSIS

    use IO::Handle;

    $io = new IO::Handle;
    if ($io->fdopen(fileno(STDIN),"r")) {
        print $io->getline;
        $io->close;
    }

    $io = new IO::Handle;
    if ($io->fdopen(fileno(STDOUT),"w")) {
        $io->print("Some text\n");
    }

    use IO::Handle '_IOLBF';
    $io->setvbuf($buffer_var, _IOLBF, 1024);

    undef $io;       # automatically closes the file if it's open

    autoflush STDOUT 1;

=head1 DESCRIPTION

C<IO::Handle> is the base class for all other IO handle classes. It is
not intended that objects of C<IO::Handle> would be created directly,
but instead C<IO::Handle> is inherited from by several other classes
in the IO hierarchy.

If you are reading this documentation, looking for a replacement for
the C<FileHandle> package, then I suggest you read the documentation
for C<IO::File>

A C<IO::Handle> object is a reference to a symbol (see the C<Symbol> package)

=head1 CONSTRUCTOR

=over 4

=item new ()

Creates a new C<IO::Handle> object.

=item new_from_fd ( FD, MODE )

Creates a C<IO::Handle> like C<new> does.
It requires two parameters, which are passed to the method C<fdopen>;
if the fdopen fails, the object is destroyed. Otherwise, it is returned
to the caller.

=back

=head1 METHODS

See L<perlfunc> for complete descriptions of each of the following
supported C<IO::Handle> methods, which are just front ends for the
corresponding built-in functions:

    close
    fileno
    getc
    eof
    read
    truncate
    stat
    print
    printf
    sysread
    syswrite

See L<perlvar> for complete descriptions of each of the following
supported C<IO::Handle> methods:

    autoflush
    output_field_separator
    output_record_separator
    input_record_separator
    input_line_number
    format_page_number
    format_lines_per_page
    format_lines_left
    format_name
    format_top_name
    format_line_break_characters
    format_formfeed
    format_write

Furthermore, for doing normal I/O you might need these:

=over 

=item $io->fdopen ( FD, MODE )

C<fdopen> is like an ordinary C<open> except that its first parameter
is not a filename but rather a file handle name, a IO::Handle object,
or a file descriptor number.

=item $io->opened

Returns true if the object is currently a valid file descriptor.

=item $io->getline

This works like <$io> described in L<perlop/"I/O Operators">
except that it's more readable and can be safely called in an
array context but still returns just one line.

=item $io->getlines

This works like <$io> when called in an array context to
read all the remaining lines in a file, except that it's more readable.
It will also croak() if accidentally called in a scalar context.

=item $io->ungetc ( ORD )

Pushes a character with the given ordinal value back onto the given
handle's input stream.

=item $io->write ( BUF, LEN [, OFFSET }\] )

This C<write> is like C<write> found in C, that is it is the
opposite of read. The wrapper for the perl C<write> function is
called C<format_write>.

=item $io->flush

Flush the given handle's buffer.

=item $io->error

Returns a true value if the given handle has experienced any errors
since it was opened or since the last call to C<clearerr>.

=item $io->clearerr

Clear the given handle's error indicator.

=item $io->sync

C<sync> synchronizes a file's in-memory state  with  that  on the
physical medium. C<sync> does not operate at the perlio api level, but
operates on the file descriptor, this means that any data held at the
perlio api level will not be synchronized. To synchronize data that is
buffered at the perlio api level you must use the flush method. C<sync>
is not implemented on all platforms. See L<fsync(3c)>.

=item $io->flush

C<flush> causes perl to flush any buffered data at the perlio api level.
Any unread data in the buffer will be discarded, and any unwritten data
will be written to the underlying file descriptor.

=item $io->blocking ( [ BOOL ] )

If called with an argument C<blocking> will turn on non-blocking IO if
C<BOOL> is false, and turn it off if C<BOOL> is true.

C<blocking> will return the value of the previous setting, or the
current setting if C<BOOL> is not given. 

If an error occurs C<blocking> will return undef and C<$!> will be set.

=back


If the C functions setbuf() and/or setvbuf() are available, then
C<IO::Handle::setbuf> and C<IO::Handle::setvbuf> set the buffering
policy for an IO::Handle.  The calling sequences for the Perl functions
are the same as their C counterparts--including the constants C<_IOFBF>,
C<_IOLBF>, and C<_IONBF> for setvbuf()--except that the buffer parameter
specifies a scalar variable to use as a buffer.  WARNING: A variable
used as a buffer by C<setbuf> or C<setvbuf> must not be modified in any
way until the IO::Handle is closed or C<setbuf> or C<setvbuf> is called
again, or memory corruption may result! Note that you need to import
the constants C<_IOFBF>, C<_IOLBF>, and C<_IONBF> explicitly.

Lastly, there is a special method for working under B<-T> and setuid/gid
scripts:

=over

=item $io->untaint

Marks the object as taint-clean, and as such data read from it will also
be considered taint-clean. Note that this is a very trusting action to
take, and appropriate consideration for the data source and potential
vulnerability should be kept in mind.

=back

=head1 NOTE

A C<IO::Handle> object is a GLOB reference. Some modules that
inherit from C<IO::Handle> may want to keep object related variables
in the hash table part of the GLOB. In an attempt to prevent modules
trampling on each other I propose the that any such module should prefix
its variables with its own name separated by _'s. For example the IO::Socket
module keeps a C<timeout> variable in 'io_socket_timeout'.

=head1 SEE ALSO

L<perlfunc>, 
L<perlop/"I/O Operators">,
L<IO::File>

=head1 BUGS

Due to backwards compatibility, all filehandles resemble objects
of class C<IO::Handle>, or actually classes derived from that class.
They actually aren't.  Which means you can't derive your own 
class from C<IO::Handle> and inherit those methods.

=head1 HISTORY

Derived from FileHandle.pm by Graham Barr E<lt>F<gbarr@pobox.com>E<gt>

=cut

require 5.000;
use strict;
use vars qw($VERSION @EXPORT_OK @ISA);
use Carp;
use Symbol;
use SelectSaver;
use IO ();	# Load the XS module

require Exporter;
@ISA = qw(Exporter);

$VERSION = "1.18";

@EXPORT_OK = qw(
    autoflush
    output_field_separator
    output_record_separator
    input_record_separator
    input_line_number
    format_page_number
    format_lines_per_page
    format_lines_left
    format_name
    format_top_name
    format_line_break_characters
    format_formfeed
    format_write

    print
    printf
    getline
    getlines

    SEEK_SET
    SEEK_CUR
    SEEK_END
    _IOFBF
    _IOLBF
    _IONBF
);

################################################
## Constructors, destructors.
##

sub new {
    my $class = ref($_[0]) || $_[0] || "IO::Handle";
    @_ == 1 or croak "usage: new $class";
    my $io = gensym;
    bless $io, $class;
}

sub new_from_fd {
    my $class = ref($_[0]) || $_[0] || "IO::Handle";
    @_ == 3 or croak "usage: new_from_fd $class FD, MODE";
    my $io = gensym;
    shift;
    IO::Handle::fdopen($io, @_)
	or return undef;
    bless $io, $class;
}

#
# There is no need for DESTROY to do anything, because when the
# last reference to an IO object is gone, Perl automatically
# closes its associated files (if any).  However, to avoid any
# attempts to autoload DESTROY, we here define it to do nothing.
#
sub DESTROY {}


################################################
## Open and close.
##

sub _open_mode_string {
    my ($mode) = @_;
    $mode =~ /^\+?(<|>>?)$/
      or $mode =~ s/^r(\+?)$/$1</
      or $mode =~ s/^w(\+?)$/$1>/
      or $mode =~ s/^a(\+?)$/$1>>/
      or croak "IO::Handle: bad open mode: $mode";
    $mode;
}

sub fdopen {
    @_ == 3 or croak 'usage: $io->fdopen(FD, MODE)';
    my ($io, $fd, $mode) = @_;
    local(*GLOB);

    if (ref($fd) && "".$fd =~ /GLOB\(/o) {
	# It's a glob reference; Alias it as we cannot get name of anon GLOBs
	my $n = qualify(*GLOB);
	*GLOB = *{*$fd};
	$fd =  $n;
    } elsif ($fd =~ m#^\d+$#) {
	# It's an FD number; prefix with "=".
	$fd = "=$fd";
    }

    open($io, _open_mode_string($mode) . '&' . $fd)
	? $io : undef;
}

sub close {
    @_ == 1 or croak 'usage: $io->close()';
    my($io) = @_;

    close($io);
}

################################################
## Normal I/O functions.
##

# flock
# select

sub opened {
    @_ == 1 or croak 'usage: $io->opened()';
    defined fileno($_[0]);
}

sub fileno {
    @_ == 1 or croak 'usage: $io->fileno()';
    fileno($_[0]);
}

sub getc {
    @_ == 1 or croak 'usage: $io->getc()';
    getc($_[0]);
}

sub eof {
    @_ == 1 or croak 'usage: $io->eof()';
    eof($_[0]);
}

sub print {
    @_ or croak 'usage: $io->print([ARGS])';
    my $this = shift;
    print $this @_;
}

sub printf {
    @_ >= 2 or croak 'usage: $io->printf(FMT,[ARGS])';
    my $this = shift;
    printf $this @_;
}

sub getline {
    @_ == 1 or croak 'usage: $io->getline()';
    my $this = shift;
    return scalar <$this>;
} 

*gets = \&getline;  # deprecated

sub getlines {
    @_ == 1 or croak 'usage: $io->getlines()';
    wantarray or
	croak 'Can\'t call $io->getlines in a scalar context, use $io->getline';
    my $this = shift;
    return <$this>;
}

sub truncate {
    @_ == 2 or croak 'usage: $io->truncate(LEN)';
    truncate($_[0], $_[1]);
}

sub read {
    @_ == 3 || @_ == 4 or croak 'usage: $io->read(BUF, LEN [, OFFSET])';
    read($_[0], $_[1], $_[2], $_[3] || 0);
}

sub sysread {
    @_ == 3 || @_ == 4 or croak 'usage: $io->sysread(BUF, LEN [, OFFSET])';
    sysread($_[0], $_[1], $_[2], $_[3] || 0);
}

sub write {
    @_ == 3 || @_ == 4 or croak 'usage: $io->write(BUF, LEN [, OFFSET])';
    local($\) = "";
    print { $_[0] } substr($_[1], $_[3] || 0, $_[2]);
}

sub syswrite {
    @_ == 3 || @_ == 4 or croak 'usage: $io->syswrite(BUF, LEN [, OFFSET])';
    syswrite($_[0], $_[1], $_[2], $_[3] || 0);
}

sub stat {
    @_ == 1 or croak 'usage: $io->stat()';
    stat($_[0]);
}

################################################
## State modification functions.
##

sub autoflush {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $|;
    $| = @_ > 1 ? $_[1] : 1;
    $prev;
}

sub output_field_separator {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $,;
    $, = $_[1] if @_ > 1;
    $prev;
}

sub output_record_separator {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $\;
    $\ = $_[1] if @_ > 1;
    $prev;
}

sub input_record_separator {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $/;
    carp "input_record_separator is not supported on a per-handle basis"
	if ref($_[0]);
    $/ = $_[1] if @_ > 1;
    $prev;
}

sub input_line_number {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $.;
    carp "input_line_number is not supported on a per-handle basis"
	if ref($_[0]);
    $. = $_[1] if @_ > 1;
    $prev;
}

sub format_page_number {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $%;
    $% = $_[1] if @_ > 1;
    $prev;
}

sub format_lines_per_page {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $=;
    $= = $_[1] if @_ > 1;
    $prev;
}

sub format_lines_left {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $-;
    $- = $_[1] if @_ > 1;
    $prev;
}

sub format_name {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $~;
    $~ = qualify($_[1], caller) if @_ > 1;
    $prev;
}

sub format_top_name {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $^;
    $^ = qualify($_[1], caller) if @_ > 1;
    $prev;
}

sub format_line_break_characters {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $:;
    $: = $_[1] if @_ > 1;
    $prev;
}

sub format_formfeed {
    my $old = new SelectSaver qualify($_[0], caller);
    my $prev = $^L;
    $^L = $_[1] if @_ > 1;
    $prev;
}

sub formline {
    my $io = shift;
    my $picture = shift;
    local($^A) = $^A;
    local($\) = "";
    formline($picture, @_);
    print $io $^A;
}

sub format_write {
    @_ < 3 || croak 'usage: $io->write( [FORMAT_NAME] )';
    if (@_ == 2) {
	my ($io, $fmt) = @_;
	my $oldfmt = $io->format_name($fmt);
	write($io);
	$io->format_name($oldfmt);
    } else {
	write($_[0]);
    }
}

sub fcntl {
    @_ == 3 || croak 'usage: $io->fcntl( OP, VALUE );';
    my ($io, $op, $val) = @_;
    my $r = fcntl($io, $op, $val);
    defined $r && $r eq "0 but true" ? 0 : $r;
}

sub ioctl {
    @_ == 3 || croak 'usage: $io->ioctl( OP, VALUE );';
    my ($io, $op, $val) = @_;
    my $r = ioctl($io, $op, $val);
    defined $r && $r eq "0 but true" ? 0 : $r;
}

# this sub is for compatability with older releases of IO that used
# a sub called constant to detemine if a constant existed -- GMB
#
# The SEEK_* and _IO?BF constants were the only constants at that time
# any new code should just chech defined(&CONSTANT_NAME)

sub constant {
    no strict 'refs';
    my $name = shift;
    (($name =~ /^(SEEK_(SET|CUR|END)|_IO[FLN]BF)$/) && defined &{$name})
	? &{$name}() : undef;
}

1;
