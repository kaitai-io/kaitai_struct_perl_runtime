use strict;
use warnings;
use Kaitai::Struct;
use Kaitai::Stream;
use HelloWorld;

# File
my $obj_1 = HelloWorld->from_file('README.md');

print $obj_1->{one}, "\n";

$obj_1->{_io}->close(); # Call Kaitai::Stream::close()

# Memory buffer
my $data = "AAAA";
my $fd;

open($fd, '<', \$data) or die "Cannot open: $!";
binmode($fd);

my $obj_2 = HelloWorld->new(Kaitai::Stream->new($fd));

print $obj_2->{one}, "\n";

close($fd);
