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

sub _io {
    my ($self) = @_;
    return $self->{_io};
}

sub _parent {
    my ($self) = @_;
    return $self->{_parent};
}

sub _root {
    my ($self) = @_;
    return $self->{_root};
}

1;
