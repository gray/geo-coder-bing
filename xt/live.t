use strict;
use warnings;
use Encode;
use Geo::Coder::Bing;
use Test::More tests => 9;

my $debug = $ENV{GEO_CODER_BING_DEBUG};
unless ($debug) {
    diag "Set GEO_CODER_BING_DEBUG to see request/response data";
}

my $geocoder = Geo::Coder::Bing->new(debug => $debug);
{
    my $address = 'Hollywood & Highland, Los Angeles, CA';
    my $location = $geocoder->geocode($address);
    is(
        $location->{Address}{PostalCode},
        90028,
        "correct zip code for $address"
    );
}
{
    my @locations = $geocoder->geocode('Main Street');
    ok(@locations > 1, 'there are many Main Streets');
}
{
    my $address = qq(Ch\xE2teau d Uss\xE9, 37420, FR);

    my $location = $geocoder->geocode($address);
    ok($location, 'latin1 bytes');
    is($location->{Address}{CountryRegion}, 'France', 'latin1 bytes');

    $location = $geocoder->geocode(decode('latin1', $address));
    ok($location, 'UTF-8 characters');
    is($location->{Address}{CountryRegion}, 'France', 'UTF-8 characters');

    $location = $geocoder->geocode(
        encode('utf-8', decode('latin1', $address))
    );
    ok($location, 'UTF-8 bytes');
    is($location->{Address}{CountryRegion}, 'France', 'UTF-8 bytes');
}
{
    my $address = decode('latin1', qq(Schm\xF6ckwitz, Berlin, Germany));
    my $expected = decode('latin1', qq(Schm\xF6ckwitz, BE, Germany));

    my $location = $geocoder->geocode($address);
    is(
        $location->{Address}{FormattedAddress}, $expected,
        'decoded character encoding of response'
    );
}
