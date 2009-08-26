use strict;
use blib;
use Data::Dumper;
use IO::Socket::INET;
use PicoEV;

print STDERR "This example is half-baked. It'snot finished, got it?\n";

my $sock = IO::Socket::INET->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 9999,
    Listen    => 5,
    Blocking  => 0,
);
my $pev = PicoEV::Loop->create(10);
$pev->add($sock, 3, 0, sub {
    warn Dumper(\@_);
}, [ qw(1 2 3) ] );

while(1) {
    $pev->once(1);
    print "1\n";
}