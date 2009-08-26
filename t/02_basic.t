use strict;
use Test::More qw(no_plan);

use_ok "PicoEV";

my $pev = PicoEV::Loop->create(10);
ok($pev);
isa_ok($pev, 'PicoEV::Loop');
