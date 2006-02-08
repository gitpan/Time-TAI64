use strict;
use Test::More
 tests => 5;

BEGIN { use_ok("Time::TAI64",qw/:tai64/); }
BEGIN {
#
## Convert current time to/from
##

my $now = time;
my $tai = unixtai64($now);
my $new = tai64unix($tai);

is( length($tai), 17, 'Invalid Length');
is( int($now), $new, 'Invalid Conversion' );

#
## Generate well known TAI64 strings
##

is( unixtai64(1), '@4000000000000001' );
is( tai64unix('@4000000000000001'), 1 );

}
