use strict;
use Test;
plan tests => 3;

eval "use Time::TAI64 qw(:tai64na)";
ok( !$@ );

eval "use Time::HiRes qw(time)";
my $unless_TimeHiRes = $@ ? 'Time::HiRes not installed' : '';

skip( $unless_TimeHiRes,
  length(unixtai64na(time)) == 33
);

skip( $unless_TimeHiRes,
  sub {
    use Time::HiRes qw(time);

    my $now = sprintf "%.9f",time;
    my $tai = unixtai64na($now);
    my $new = sprintf "%.9f",tai64naunix($tai);
    return ($now == $new);
  }
);

