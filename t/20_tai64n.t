use strict;
use Test;
plan tests => 12;

eval "use Time::TAI64 qw(:tai64n)";
ok( !$@ );

eval "use Time::HiRes qw(time)";
my $unless_TimeHiRes = $@ ? 'Time::HiRes not installed' : '';

#
## Test Basic Stuff
##

ok( length(unixtai64n(time)), "25", "Invalid Length" );

skip( $unless_TimeHiRes,
  sub {
    my $now = sprintf "%.6f",time;
    my $tai = unixtai64n($now);
    my $new = sprintf "%.6f",tai64nunix($tai);
    return ($now == $new);
  }
);

skip( $unless_TimeHiRes,
  sub {
    my $now = sprintf "%.6f",time;
    my $tai = unixtai64n($now);
    my $a = scalar(localtime($now));
    my $b = tai64nlocal($tai);
    return ($a eq $b);
  }
);

#
## Well Known TAI64N Strings
##

ok( unixtai64n(1), '@400000000000000100000000', 'unixtai64n(1)'  );
ok( unixtai64n(1,500_000_000), '@40000000000000011dcd6500', 'unixtai64n(1,500_000_000)' );
ok( unixtai64n(1.194785), '@40000000000000010b9c2ee8', 'unixtai64n(1.194785)' );
ok( unixtai64n(1.784526), '@40000000000000012ec2eab0', 'unixtai64n(1.784526)' );

ok( sprintf("%.6f",tai64nunix('@400000000000000100000000')), "1.000000" );
ok( sprintf("%.6f",tai64nunix('@40000000000000011dcd6500')), "1.500000" );
ok( sprintf("%.6f",tai64nunix('@40000000000000010b9c2ee8')), "1.194785" );
ok( sprintf("%.6f",tai64nunix('@40000000000000012ec2eab0')), "1.784526" );
