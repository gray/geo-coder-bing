package Geo::Coder::Bing;

use strict;
use warnings;

use Carp qw(carp croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.09';
$VERSION = eval $VERSION;

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (key => @params) : @params;

    my $key = $params{key};
    unless ($key) {
        carp 'Provide a Bing Maps key to use the new REST API';
    }

    my $self = bless { key => $key }, $class;

    if ($params{ua}) {
        $self->ua($params{ua});
    }
    else {
        $self->{ua} = LWP::UserAgent->new(agent => "$class/$VERSION");
    }

    if ($params{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }

    if ($params{https}) {
        croak q('https' requires Crypt::SSLeay or IO::Socket::SSL)
            unless eval { require Net::HTTPS; 1 };

        $self->{https} = 1;
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

sub geocode {
    return $_[0]->{key} ? &_geocode_rest : &_geocode_ajax;
}

sub _geocode_rest {
    my ($self, @params) = @_;
    my %params = (@params % 2) ? (location => @params) : @params;

    my $location = $params{location} or return;
    $location = Encode::encode('utf-8', $location);

    my $proto = $self->{https} ? 'https' : 'http';
    my $uri = URI->new("$proto://dev.virtualearth.net/REST/v1/Locations");
    $uri->query_form(
        key => $self->{key},
        q   => $location,
    );

    my $res = $self->ua->get($uri);
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $content = $res->decoded_content;
    return unless $content;

    my $data = eval { from_json($content) };
    return unless $data;

    my @results = @{ $data->{resourceSets}[0]{resources} || [] };
    return wantarray ? @results : $results[0];
}

# Support AJAX API for backwards compatibility.

sub _geocode_ajax {
    my ($self, @params) = @_;
    my %params = (@params % 2) ? (location => @params) : @params;

    my $location = $params{location} or return;
    $location = Encode::encode('utf-8', $location);

    my $proto = $self->{https} ? 'https' : 'http';
    my $uri = URI->new("$proto://dev.virtualearth.net/");
    $uri->path_segments(qw(
        services v1 geocodeservice geocodeservice.asmx Geocode
    ));
    $uri->query_form(
        format => 'json',

        # Note: the quotes around the location parameter are required.
        query  => qq("$location"),

        # These are all required, even if empty.
        map { $_ => '' } qw(
            addressLine adminDistrict count countryRegion culture
            curLocAccuracy currentLocation district entityTypes landmark
            locality mapBounds postalCode postalTown rankBy
        ),
    );

    my $res = $self->ua->get($uri);
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $content = $res->decoded_content;
    return unless $content;

    # Workaround invalid data.
    $content =~ s[ \}\.d $ ][}]x;

    my $data = eval { from_json($content) };
    return unless $data;

    my @results = @{ $data->{d}{Results} || [] };
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::Bing - Geocode addresses with the Bing Maps API

=head1 SYNOPSIS

    use Geo::Coder::Bing;

    my $geocoder = Geo::Coder::Bing->new(key => 'Your Bing Maps key');
    my $location = $geocoder->geocode(
        location => 'Hollywood and Highland, Los Angeles, CA'
    );

=head1 DESCRIPTION

The C<Geo::Coder::Bing> module provides an interface to the Bing Maps
geocoding service.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Bing->new('Your Bing Maps key')
    $geocoder = Geo::Coder::Bing->new(
        key   => 'Your Bing Maps key',
        https => 1,
    )

Creates a new geocoding object.

A Bing Maps key can be obtained here:
L<http://msdn.microsoft.com/en-us/library/ff428642.aspx>.

Accepts an optional B<https> parameter for securing network traffic.

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all locations results.

Each location result is a hashref; a typical example looks like:

    {
        __type =>
            "Location:http://schemas.microsoft.com/search/local/ws/rest/v1",
        address => {
            addressLine   => "Hollywood Blvd & N Highland Ave",
            adminDistrict => "CA",
            countryRegion => "United States",
            formattedAddress =>
                "Hollywood Blvd & N Highland Ave, Los Angeles, CA 90028",
            locality   => "Los Angeles",
            postalCode => 90028,
        },
        bbox => [
            "34.0977008647939", "-118.344888641665",
            "34.1054262999352", "-118.332449571785",
        ],
        confidence => "High",
        entityType => "RoadIntersection",
        name  => "Hollywood Blvd & N Highland Ave, Los Angeles, CA 90028",
        point => {
            coordinates => [ "34.1015635823646", "-118.338669106725" ],
            type        => "Point",
        },
    }

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 NOTES

Starting with version 0.08, this module uses the REST API instead of the
AJAX API. Backwards compatibility has been maintained, but its usage by this
module is now deprecated, hence a warning is issued when a key is not
provided to the constructor. Also note that the structure of the data
returned from both APIs differs slightly.

=head1 SEE ALSO

L<http://msdn.microsoft.com/en-us/library/ff701713.aspx>

L<Geo::Coder::Google>, L<Geo::Coder::Mapquest>, L<Geo::Coder::Multimap>,
L<Geo::Coder::Yahoo>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-Bing>. I will be
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

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Bing>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Bing>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2010 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
