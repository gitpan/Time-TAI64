use strict;
use Test;

plan tests => 5;

eval "use Time::TAI64 qw(:all)";
ok( !$@ );

eval "use Time::HiRes qw(time)";
my $unless_TimeHiRes = $@ ? 'Time::HiRes not installed' : '';

ok( length(unixtai64(int(time))), 17 );

skip( $unless_TimeHiRes,
  length(unixtai64n(time)) == 25
);

skip( $unless_TimeHiRes,
  length(unixtai64na(time)) == 33
);

skip( $unless_TimeHiRes,
  sub {
    use POSIX qw(strftime);
    use Time::HiRes qw(time);

    my $now = sprintf "%.6f",time;
    my $secs = int($now);
    my $nano = ($now - $secs) * 1e9;
    my $tai = unixtai64n($now);
    my $str1 = tai64nlocal($tai);
    my $str2 = strftime("%Y-%m-%d %H:%M:%S",localtime($now));
    $str2 .= sprintf(".%09d",$nano);
    return ($str1 eq $str2);
  }
);

