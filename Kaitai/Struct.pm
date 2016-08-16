package Kaitai::Struct;

use strict;
use warnings;
use Kaitai::Stream;

sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;

    my $_io = shift;
    my $self = {_io => $_io};
    bless $self;

    return $self;
}

1;
