package Time::TAI64;

=head1 NAME

Time::TAI64 - Perl extension for converting TAI64 strings into standard unix timestamps.

=head1 SYNOPSIS

Generate TAI64 timestamps

  use Time::TAI64;
  use Time::HiRes qw(time);

  $now = time; # High precision
  printf "%s\n", unixtai64n($now);

Print out human readable logs

  use Time::TAI64;

  open FILE, "/var/log/multilog/stats";
  while(my $line = <FILE>) {
    my($tai,$log) = split(' ',$line,2);
    printf "%s %s\n",tai64nlocal($tai),$log;
  }
  close FILE;
 
=head1 DESCRIPTION

This is a package provides routines to convert TAI64 strings, like timestamps produced
by B<multilog>, into values that can be processed by other perl functions to
display the timestamp in human-readable form and/or use in mathematical
computations.

=cut

use strict;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $AUTOLOAD);

require 5.008;
require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw ( );
@EXPORT_OK = qw(
 tai2unix
 tai2strftime
 tai64unix
 tai64nunix
 tai64naunix
 tai64nlocal
 tai64nsyslog
 unixtai64
 unixtai64n
 unixtai64na
);

$EXPORT_TAGS{'tai64'}   = [ qw( tai64unix unixtai64 ) ];
$EXPORT_TAGS{'tai64n'}  = [ qw( tai64nunix unixtai64n tai64nlocal ) ];
$EXPORT_TAGS{'tai64na'} = [ qw( tai64naunix unixtai64na ) ];
$EXPORT_TAGS{'all'}     = [ 
 @{ $EXPORT_TAGS{'tai64'} },
 @{ $EXPORT_TAGS{'tai64n'} },
 @{ $EXPORT_TAGS{'tai64na'} },
 qw/ tai2unix tai2strftime /
];

use POSIX qw(strftime);
$VERSION = '2.02';

#-----------
#
## Internal Routines
##
#-----------

#-----------
#
## h2i: hex to integer
##   returns the integer from a hexdigit.
##   returns -1 on error.
#-----------
sub _h2i ($) {
        my $c = shift;
        my $oc = ord($c);
        my $rv;

        return ($oc - ord('0')) if $c =~ m/\d/;
        return ($oc - ord('A') + 10) if $c =~ m/[A-F]/;
        return ($oc - ord('a') + 10) if $c =~ m/[a-f]/;
        return -1;
}

#-----------
#
## td: tai_part to decimal
##   returns the decimal portion of the hex-part
##     upto $l hex-digits.
##   returns 0 if the hex-part is invalid.
#-----------
sub _td ($$) {
	my $s = shift;
	my $l = shift;
	my $d = 0;
	for my $ix (0 .. $l*2-1) {
		my $pw = 4 * ($l*2 - $ix - 1);
		my $b = &_h2i(substr($s,$ix,1));
		return 0 if ($b < 0);
		$d |= $b << $pw;
	}
	return $d ;
}

#-----------
#
## t8d: tai_part to decimal
## t4d: tai_part to decimal
##   returns the decimal portion of the hex-part
##   returns 0 if the hex-part is invalid.
#-----------
sub _t8d ($) {
        my $s = shift;
        return 0 unless length($s) == 16;
        my $d = _td($s,8);
        return $d;
}
sub _t4d ($) {
	my $s = shift;
	return 0 unless length($s) == 8;
	my $d = _td($s,4);
	return $d;
}

#-----------
#
## decode_tai64:
##   returns the number of seconds;
##
#-----------
sub _decode_tai64 ($) {
        my $tok = shift;
        return (0) unless $tok =~ m/^\@40000000/;
        my $secs = _t4d(substr($tok,9,8));
        return($secs);
}

#-----------
#
## decode_tai64n:
##   returns a two element array containing the number
##   of seconds and nanoseconds respectively.
#-----------
sub _decode_tai64n ($) {
        my $tok = shift;
        return (0,0) unless $tok =~ m/^\@40000000/;
        my $secs = _t4d(substr($tok,9,8));
        my $nano = _t4d(substr($tok,17,8));
        return($secs,$nano);
}

#-----------
#
## decode_tai64na:
##   returns a three element array containing the number
##   of seconds, nanoseconds, and attoseconds respectively.
#-----------
sub _decode_tai64na ($) {
        my $tok = shift;
        return (0,0,0) unless $tok =~ m/^\@40000000/;
        my $secs = _t4d(substr($tok,9,8));
        my $nano = _t4d(substr($tok,17,8));
	my $atto = _t4d(substr($tok,25,8));
        return($secs,$nano,$atto);
}

#-----------
#
## encode_tai64:
##   returns a 16 character string tai64 encoded
##   using the timestamp supplied, preceded by '@'.
#-----------
sub _encode_tai64 ($) {
	my $s = shift;
	my @t = ();
	push @t, '@40000000';
	push @t, sprintf("%08x",$s);
	return (join('',@t));
}

#-----------
#
## encode_tai64n:
##   returns a 24 character string tai64n encoded
##   using the timestamp supplied, preceded by '@'.
#-----------
sub _encode_tai64n ($$) {
	my($s,$n) = @_;
	my @t = ();
	push @t, _encode_tai64($s);
	push @t, sprintf("%08x",$n);
	return (join('',@t));
}

#-----------
#
## encode_tai64na:
##   returns a 32 character string tai64na encoded
##   using the timestamp supplied, preceded by '@'.
#-----------
sub _encode_tai64na ($$$) {
	my($s,$n,$a) = @_;
	my @t = ();
	push @t, _encode_tai64n($s,$n);
	push @t, sprintf("%08x",$a);
	return (join('',@t));
}

=head1 EXPORTS

The following functions are available to the user:

=over 4

=item tai2unix ( $tai_string )

This method converts a tai64, tai64n, or tai64na string into a unix
timestamp.  If successfull, this function returns an integer value
containing the number of seconds since Jan 1, 1970 as would perl's
C<time> function. If an error occurs, the function returns a 0.

=cut

sub tai2unix ($) {
	my $tok = shift;
	return int(tai64unix($tok))   if length($tok) == 17;
	return int(tai64nunix($tok))  if length($tok) == 25;
	return int(tai64naunix($tok)) if length($tok) == 33;
	return 0;
}
 
=item tai64unix ( $tai64_string )

This method converts the tai64 string given as its only parameter and
if successfull, returns a value for I<timestamp> that is compatible
with the value returned from C<time>.

=cut

sub tai64unix ($) {
	my $tok = shift;
	return 0 unless (length($tok) == 17);
	my $s = &_decode_tai64($tok);
	return $s;
}

=item tai64nunix ( $tai64n_string )

This method converts the tai64n string given as its only parameter
and if successfull, returns a value for I<timestamp> that is compatible
with the value returned from C<Time::HiRes::time>. 

=cut

sub tai64nunix ($) {
        my $tok = shift;
	return 0 unless (length($tok) == 25);
        my($s,$n) = &_decode_tai64n($tok);
        $s += ($n/1e9);
        return $s;
}

=item tai64naunix ( $tai64na_string )

This method converts the tai64na string given as its only parameter
and if successfull, returns a value for I<timestamp> that is compatible
with the value returned from C<Time::HiRes::time>. 

=cut

sub tai64naunix ($) {
	my $tok = shift;
	return 0 unless (length($tok) == 33);
	my ($s,$n,$a) = &_decode_tai64na($tok);
	$n += ($a/1e9);
	$s += ($n/1e9);
	return $s;
}

=item tai64strftime ( $tai64_string, $format_string )

This method converts the tai64, tai64n, or tai64na string given as its
first parameter and, returns a formatted string of the converted I<timestamp>
as formatted by its second parameter using strftime conventions.

If this second parameter is ommited, it defaults to "%a %b %d %H:%M:%S %Y"
which should print the timestamp as:
Mon Nov  1 12:00:00 2004

=cut

sub tai2strftime ($) {
	my $tok = shift;
	my $fmt = shift || "%a %b %d %H:%M:%S %Y";
	my $secs = &tai2unix($tok);
	return ($secs == 0) ? '' : strftime($fmt,localtime($secs));
}

=item tai64nlocal ( $tai64n_string )

This utility returns a string representing the tai64n timestamp
converted to local time in ISO format: YYYY-MM-DD HH:MM:SS.SSSSSSSSS.

The reason to include this funtion is to provide compatibility with the
command-line version included in B<daemontools>.

=cut

sub tai64nlocal ($) {
        my $tok  = shift;
        my ($secs,$nano) = _decode_tai64n($tok);
        return ($secs == 0) ? '' : join('.',
		strftime("%F %H:%M:%S",localtime($secs)),
		sprintf("%09d",$nano));
}

=item unixtai64 ( I<timestamp> )

This method converts a unix timestamp into a TAI64 string.

=cut

sub unixtai64 ($) {
	my $secs = shift;
	return '' if ($secs == 0);
	return &_encode_tai64(int($secs));
}

=item unixtai64n ( I<timestamp> )

=item unixtai64n ( I<seconds> , I<nanoseconds> )

This methods returns a tai64n string using the parameters supplied by the user
making the following assumptions:

=over 6

=item *

If I<seconds> and I<nanoseconds> are given, these values are used to compute
the tai64n string. If I<nanoseconds> evaluates to more than 1 second, the value
of both I<seconds> and I<nanoseconds> are reevaluated. Both I<seconds> and I<nanoseconds>
are assumed to be integers, any fractional part is truncated.

=item *

If I<timestamp> is an integer, I<nanoseconds> is assumed to be 0.

=item *

If I<timestamp> is a C<real> number, the integer part is used for the I<seconds>
and the fractional part is converted to I<nanoseconds>.

=back

=cut

sub unixtai64n ($;$) {
	my($secs,$nano) = @_;

	if (defined($nano)) {
		if ($nano >= 1e9) {
			my $a = $nano / 1e9;
			$secs += int($a);
			$nano  = $a - 1;
		}
	} else {
		$nano = ($secs - int($secs)); 
		$nano *= 1e9;
	}

	return '' if ($secs == 0 && $nano == 0);
	return &_encode_tai64n(int($secs),int($nano));
}

=item unixtai64na ( I<timestamp> )

=item unixtai64na ( I<seconds> , I<nanoseconds> , I<attoseconds> )

This method returns a tai64na string unsing the parameters supplied by the
user making the following assumptions:

=over 6

=item *

If I<seconds>, I<nanoseconds> and I<attoseconds> are given, these values are
used to compute the tai64na string. If either I<nanoseconds> evaluates to
more than 1 second, or I<attoseconds> evaluates to more than 1 nanosecond,
then I<seconds>, I<nanoseconds>, and I<attoseconds> are reevaluated. These
values are assumed to be integers, any fractional part is truncated.

=item *

If I<timestamp> is an integer, both I<nanoseconds> and I<attoseconds> are
assumed to be 0.

=item *

If I<timestamp> is a C<real> number, the integer part is used for the I<seconds>
and the fractional part is converted to I<nanoseconds> amd I<attoseconds>.

=back

=cut

sub unixtai64na ($;$$) {
	my($secs,$nano,$atto) = @_;

	if (defined($nano)) {
		if ($nano >= 1e9) {
			$secs += int($nano / 1e9);
			$nano  = ($nano % 1e9);
		}
	} else {
		$nano = ($secs - int($secs)); 
		$nano *= 1e9;
	}

	if (defined($atto)) {
		if ($atto >= 1e9) {
			$nano += int($atto / 1e9);
			$atto  = ($atto % 1e9);
		}
	} else {
		$atto = ($nano - int($nano)); 
		$atto *= 1e9;
	}

	return '' if ($secs == 0 and $nano == 0 and $atto == 0);
	return &_encode_tai64na(int($secs),int($nano),int($atto));
}

#-----
# Make PERL Happy!!

1;

__END__

=head1 SEE ALSO

http://pobox.com/~djb/libtai/tai64.html
http://cr.yp.to/daemontools.html

=head1 AUTHOR

Jorge Valdes, E<lt>jvaldes@intercom.com.svE<gt>

=head1 HISTORY

This module was started by AMS, but would not have been completed
if Iain Truskett hadn't taken over. After his death, Jorge Valdes
assumed ownership and rewrote it in Perl.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jorge Valdes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=head1 AVAILABILITY

The lastest version of this library is likely to be available from
CPAN.

=cut
