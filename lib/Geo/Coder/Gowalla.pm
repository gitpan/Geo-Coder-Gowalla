package Geo::Coder::Gowalla;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

sub new {
    my ($class, %params) = @_;

    my $self = bless \ %params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
        $self->{compress} ||= 0;
    }
    if (exists $self->{compress} ? $self->{compress} : 1) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    croak q('https' requires LWP::Protocol::https)
        if $self->{https} and not $self->ua->is_protocol_supported('https');

    return $self;
}

sub response { $_[0]->{response} }

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
    my ($self, @params) = @_;
    my %params = (@params % 2) ? (location => @params) : @params;

    my $raw = delete $params{raw};
    $_ = Encode::encode('utf-8', $_) for values %params;
    my $location = delete $params{location} or return;

    my $uri = URI->new('http://api.gowalla.com/spots');
    $uri->query_form(
        l => $location,
        %params,
    );
    $uri->scheme('https') if $self->{https};

    my $res = $self->{response} = $self->ua->get(
        $uri,
        accept => 'application/json',
        exists $self->{apikey} ? (x_gowalla_api_key => $self->{apikey}) : (),
    );
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $data = eval { from_json($res->decoded_content) };
    return unless $data;
    return $data if $raw;

    my @results = @{ $data->{spots} || [] };
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::Gowalla - Geocode addresses with the Gowalla Spots API

=head1 SYNOPSIS

    use Geo::Coder::Gowalla;

    my $geocoder = Geo::Coder::Gowalla->new(
        # apikey => 'Your Gowalla API key',
    );
    my $location = $geocoder->geocode(
        location => '610 W 5th Street, Suite 604, Austin, TX 78701',
    );

=head1 DESCRIPTION

The C<Geo::Coder::Gowalla> module provides an interface to the geocoding
functionality of the Gowalla Spots API.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Gowalla->new(
        # apikey => 'Your Gowalla API key',
        # https  => 1,
        # debug  => 1,
    )

Creates a new geocoding object.

Accepts the following named arguments:

=over

=item * I<apikey>

A Gowalla API key. (optional)

Gowalla allows higher rate limits when an API key is provided.
An API key can be obtained here: L<https://gowalla.com/api/keys>

=item * I<ua>

A custom LWP::UserAgent object. (optional)

=item * I<compress>

Enable compression. (default: 1, unless I<debug> is enabled)

=item * I<https>

Use https protocol for securing network traffic. (default: 0)

=item * I<debug>

Enable debugging. This prints the headers and content for requests and
responses. (default: 0)

=back

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
        "_image_url_200":
            "http://static.gowalla.com/categories/121-b3390d3267c29dbbbd67ccfff852177f-200.png",
        "_image_url_50":
            "http://static.gowalla.com/categories/121-903d9ce4f33b0284aacfeacd58118a19-100.png",
        "activity_url": "/spots/6476224/events",
        "address": {
            "locality": "Austin",
            "region": "TX"
        },
        "checkins_count": 217,
        "checkins_url": "/checkins?spot_id=6476224",
        "description": " ",
        "foursquare_id": null,
        "highlights_url": "/spots/6476224/highlights",
        "image_url":
            "http://static.gowalla.com/categories/121-903d9ce4f33b0284aacfeacd58118a19-100.png",
        "items_count": 10,
        "items_url": "/spots/6476224/items",
        "lat": "30.269263558",
        "lng": "-97.749352878",
        "name": "Gowalla Office 1B",
        "photos_count": 84,
        "radius_meters": 75,
        "spot_categories": [{
            "name": "Corporate Office",
            "url": "/categories/121"
        }],
        "strict_radius": false,
        "trending_level": 0,
        "url": "/spots/6476224",
        "users_count": 121
    }

=head2 response

    $response = $geocoder->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<https://gowalla.com/api/docs>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-Gowalla>. I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Gowalla

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-gowalla>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-Gowalla>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Gowalla>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Gowalla>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Gowalla/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
