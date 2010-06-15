use strict;
use warnings;
use Test::More tests => 5;
use Geo::Coder::Bing;

new_ok('Geo::Coder::Bing' => ['Your Bing Maps key']);
new_ok('Geo::Coder::Bing' => ['Your Bing Maps key', debug => 1]);
new_ok('Geo::Coder::Bing' => [key => 'Your Bing Maps key']);
new_ok('Geo::Coder::Bing' => [key => 'Your Bing Maps key', debug => 1]);

can_ok('Geo::Coder::Bing', qw(geocode ua));
