use strict;
use warnings;
use Encode;
use Geo::Coder::Bing;
use Test::More tests => 6;

my $geocoder = Geo::Coder::Bing->new;
{
    my $address = 'Hollywood & Highland, Los Angeles, CA';
    my $location = $geocoder->geocode($address);
    is $location->{Address}{PostalCode}, 90028,
        "correct zip code for $address";
}
{
    my @locations = $geocoder->geocode('Main Street');
    ok(@locations > 1, 'there are many Main Streets');
}
{
    my $address = qq(Ch\xc3\xa2teau d Uss\xc3\xa9, 37420, France);

    my $location = $geocoder->geocode($address);
    ok $location, 'UTF-8 bytes';
    is $location->{Address}{CountryRegion}, 'France', "UTF-8 bytes";

    $location = $geocoder->geocode(decode_utf8($address));
    ok $location, 'UTF-8 characters';
    is $location->{Address}{CountryRegion}, 'France', "UTF-8 characters";
}
