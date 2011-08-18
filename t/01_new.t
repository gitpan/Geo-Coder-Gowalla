use strict;
use warnings;
use Test::More;
use Geo::Coder::Gowalla;

new_ok('Geo::Coder::Gowalla' => []);
new_ok('Geo::Coder::Gowalla' => [debug => 1]);

can_ok('Geo::Coder::Gowalla', qw(geocode response ua));

done_testing;
