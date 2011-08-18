use strict;
use warnings;
use Encode qw(decode encode);
use Geo::Coder::Gowalla;
use Test::More;

my $debug = $ENV{GEO_CODER_GOWALLA_DEBUG};
unless ($debug) {
    diag "Set GEO_CODER_GOWALLA_DEBUG to see request/response data";
}

my $has_ssl = LWP::UserAgent->is_protocol_supported('https');

my $geocoder = Geo::Coder::Gowalla->new(
    token => $ENV{GOWALLA_APIKEY},
    debug => $debug,
);
my %options = (per_page => 5);

{
    my $address = '610 W 5th Street, Suite 604, Austin, TX 78701';
    my $location = $geocoder->geocode($address, %options);
    like(
        $location->{lat},
        qr/^30\.26/,
        "approximate latitude code for $address",
    );
    like(
        $location->{lng},
        qr/^-97\.74/,
        "approximate longitude code for $address"
    );
}

{
    my @locations = $geocoder->geocode('Main Street, Los Angeles, CA');
    ok(@locations > 1, 'there are many Main Streets in Los Angeles, CA');
}

{
    my $address = qq(Ch\xE2teau d Uss\xE9, 37420);
    my $location = $geocoder->geocode($address, %options);
    like(
        $location->{lat},
        qr/^47\.25/,
        "approximate latitude code for $address",
    );
    like(
        $location->{lng},
        qr/^0\.2923/,
        "approximate longitude code for $address"
    );
}

SKIP: {
    skip 'no SSL support', 1 unless $has_ssl;
    my $geocoder = Geo::Coder::Gowalla->new(
        debug => $debug,
        https  => 1,
    );
    my $address = '610 W 5th Street, Suite 604, Austin, TX 78701';
    my $location = $geocoder->geocode($address, %options);
    like(
        $location->{lat},
        qr/^30\.26/,
        "approximate latitude code for $address",
    );
    like(
        $location->{lng},
        qr/^-97.74/,
        "approximate longitude code for $address"
    );
}

done_testing;
