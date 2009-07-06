use strict;
use warnings;
use Test::More tests => 2;
use Geo::Coder::Bing;

my $geo = Geo::Coder::Bing->new;
isa_ok($geo, 'Geo::Coder::Bing', 'new');
can_ok('Geo::Coder::Bing', qw(geocode ua));
