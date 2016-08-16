package HelloWorld;

use strict;
use warnings;
use Kaitai::Struct;
use Kaitai::Stream;

our @ISA = 'Kaitai::Struct'; # Base class

# Class method, may be considered as 'static'
sub from_file {
    my $class = shift;
    my $filename = shift;
    my $fd;

    open($fd, '<', $filename) or return undef;
    binmode($fd);
    return new($class, Kaitai::Stream->new($fd));
}

# Constructor
sub new {
    my $class = shift;
    my $_io = shift;
    my $_parent = shift;
    my $_root = shift;
    my $self = Kaitai::Struct->new($_io); # Call constructor of a base class

    bless $self, $class;
    $self->{_parent} = $_parent;
    $self->{_root} = $_root || $self;
    $self->{one} = $self->{_io}->read_u1();

    return $self;
}

1;
