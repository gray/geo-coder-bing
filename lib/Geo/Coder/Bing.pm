package Geo::Coder::Bing;

use strict;
use warnings;

use Carp qw(croak);
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.03';

sub new {
    my ($class, %params) = @_;

    my $self = bless {}, $class;

    if ($params{ua}) {
        $self->ua($params{ua});
    }
    else {
        $self->{ua} = LWP::UserAgent->new(agent => "$class/$VERSION");
    }

    return $self;
}

sub ua {
    my ($self, $ua) = @_;
    if ($ua) {
        croak q('ua' must be (or derived from) an LWP::UserAgent')
            unless ref $ua and $ua->isa(q(LWP::UserAgent));
        $self->{ua} = $ua;
    }
    return $self->{ua};
}

my $URI;

sub _construct_uri {
    return $URI if $URI;

    $URI = URI->new('http://dev.virtualearth.net/');
    $URI->path_segments(qw(
        services v1 geocodeservice geocodeservice.asmx Geocode
    ));
    $URI->query_form(
        format => 'json',

        # These are all required, even if empty.
        map { $_ => '' } qw(
            addressLine adminDistrict count countryRegion culture
            curLocAccuracy currentLocation district entityTypes landmark
            locality mapBounds postalCode postalTown rankBy
        ),
    );

    return $URI;
}

sub geocode {
    my $self = shift;

    my $location = @_ % 2 ? $_[0] : $_[0] eq 'location' ? $_[1] : '';
    return unless $location;

    my $uri = ($URI ||= _construct_uri)->clone;
    $uri->query_form(query => qq("$location"), $uri->query_form);

    my $res = $self->ua->get($uri);
    return unless $res->is_success;

    my $data = eval { decode_json($res->decoded_content) };
    return unless $data;

    my @results = @{ $data->{Results} || [] };
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::Bing - Geocode addresses with the Bing Maps API

=head1 SYNOPSIS

    use Geo::Coder::Bing;

    my $geocoder = Geo::Coder::Bing->new;
    my $location = $geocoder->geocode(
        location => 'Hollywood and Highland, Los Angeles, CA'
    );

=head1 DESCRIPTION

The C<Geo::Coder::Bing> module provides an interface to the Bing Maps
geocoding service, via the Ajax API.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Bing->new()

Creates a new geocoding object.

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and
in list context it returns all locations results.

Each location result is a hashref; a typical example looks like:

    {
        'BestLocation' => {
            'Precision'   => 0,
            'Coordinates' => {
                'Longitude' => '-118.338669106725',
                'Latitude'  => '34.1015635823646'
            }
        },
        'Locations' => [
            {
                'Precision'   => 0,
                'Coordinates' => {
                    'Longitude' => '-118.338669106725',
                    'Latitude'  => '34.1015635823646'
                }
            }
        ],
        'CountryRegion' => 244,
        'Address'       => {
            'PostalCode'    => '90028',
            'CountryRegion' => 'United States',
            'AdminDistrict' => 'CA',
            'FormattedAddress' =>
                'Hollywood Blvd & N Highland Ave, Los Angeles, CA 90028',
            'Locality'    => 'Los Angeles',
            'AddressLine' => 'Hollywood Blvd & N Highland Ave',
            'PostalTown'  => '',
            'District'    => ''
        },
        'MatchCode' => 1,
        'Type'      => 155,
        'Shape'     => undef,
        'BestView'  => {
            'Type'            => 0,
            'NorthEastCorner' => {
                'Longitude' => '-118.323121333557',
                'Latitude'  => '34.1112203763297'
            },
            'SouthWestCorner' => {
                'Longitude' => '-118.354216879894',
                'Latitude'  => '34.0919067883995'
            },
            'Center'          => {
                'Longitude' => '-118.338669106725',
                'Latitude'  => '34.1015641333754'
            }
        },
        'MatchConfidence' => 0,
        'Name' => 'Hollywood Blvd & N Highland Ave, Los Angeles, CA 90028'
    }

If the location contains non-ASCII characters, ensure it is a Unicode-
flagged string or consists of UTF-8 bytes.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<http://www.microsoft.com/maps/isdk/ajax/>

L<Geo::Coder::Google>, L<Geo::Coder::Yahoo>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Coder-Bing>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Bing

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-bing>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-Bing>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Bing>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Bing>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Bing>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
