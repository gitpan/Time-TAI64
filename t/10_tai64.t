use strict;
use Test;
plan tests => 5;

eval "use Time::TAI64 qw(:tai64)";
ok( !@$ );

#
## Convert current time to/from
##

my $now = time;
my $tai = unixtai64($now);
my $new = tai64unix($tai);

ok( length($tai), "17", 'Invalid Length');
ok( int($now), $new, 'Invalid Conversion' );

#
## Generate well known TAI64 strings
##

ok( unixtai64(1), '@4000000000000001' );
ok( tai64unix('@4000000000000001'), 1 );

