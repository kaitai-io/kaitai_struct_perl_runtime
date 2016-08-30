package Kaitai::Struct;

use strict;
use warnings;
use Kaitai::Stream;

sub new {
    my ($invocant, $_io) = @_;
    my $class = ref($invocant) || $invocant;
    my $self = {_io => $_io};

    bless $self;
    return $self;
}

1;
