package Kaitai::Stream;

use strict;
use warnings;
use Fcntl qw(SEEK_SET SEEK_END);
use Encode qw(decode);

sub new {
    my ($invocant, $_io) = @_;
    my $class = ref($invocant) || $invocant;
    my $self = {};

    if (ref $_io eq 'GLOB') {
        # _io is a file handle
        $self->{_io} = $_io;
    } elsif (ref $_io eq '') {
        # _io is a memory buffer
        my $fd;
        open $fd, '<', \$_io or return undef;
        binmode $fd;
        $self ->{_io} = $fd;
    } else {
        return undef;
    }

    bless $self;
    return $self;
}

sub close {
    my ($self) = @_;

    close($self->{_io});
}

# ========================================================================
# Stream positioning
# ========================================================================

sub is_eof {
    my ($self) = @_;

    return eof($self->{_io});
}

sub seek {
    my ($self, $pos) = @_;

    seek($self->{_io}, $pos, SEEK_SET);
}

sub pos {
    my ($self) = @_;

    return tell($self->{_io});
}

sub size {
    my ($self) = @_;

    my $pos = tell($self->{_io});
    CORE::seek($self->{_io}, 0, SEEK_END);
    my $size = tell($self->{_io});
    CORE::seek($self->{_io}, $pos, SEEK_SET);

    return $size;
}

# ========================================================================
# Reading
# ========================================================================

sub _read {
    my ($self, $len, $template) = @_;
    my $buf;

    read($self->{_io}, $buf, $len);
    return unpack($template, $buf);
}

# ========================================================================
# Integer numbers
# ========================================================================

# ------------------------------------------------------------------------
# Signed
# ------------------------------------------------------------------------

sub read_s1 {
    return &_read(@_, 1, 'c');
}

# ........................................................................
# Big-endian
# ........................................................................

sub read_s2be {
    return &_read(@_, 2, 's>');
}

sub read_s4be {
    return &_read(@_, 4, 'i>');
}

sub read_s8be {
    return &_read(@_, 8, 'q>');
}

# ........................................................................
# Little-endian
# ........................................................................

sub read_s2le {
    return &_read(@_, 2, 's<');
}

sub read_s4le {
    return &_read(@_, 4, 'i<');
}

sub read_s8le {
    return &_read(@_, 8, 'q<');
}

# ------------------------------------------------------------------------
# Unsigned
# ------------------------------------------------------------------------

sub read_u1 {
    return &_read(@_, 1, 'C');
}

# ........................................................................
# Big-endian
# ........................................................................

sub read_u2be {
    return &_read(@_, 2, 'S>');
}

sub read_u4be {
    return &_read(@_, 4, 'I>');
}

sub read_u8be {
    return &_read(@_, 8, 'Q>');
}

# ........................................................................
# Little-endian
# ........................................................................

sub read_u2le {
    return &_read(@_, 2, 'S<');
}

sub read_u4le {
    return &_read(@_, 4, 'I<');
}

sub read_u8le {
    return &_read(@_, 8, 'Q<');
}

# ========================================================================
# Floating point numbers
# ========================================================================

# ........................................................................
# Big-endian
# ........................................................................

sub read_f4be {
    return &_read(@_, 4, 'f>');
}

sub read_f8be {
    return &_read(@_, 8, 'd>');
}

# ........................................................................
# Little-endian
# ........................................................................

sub read_f4le {
    return &_read(@_, 4, 'f<');
}

sub read_f8le {
    return &_read(@_, 8, 'd<');
}

# ========================================================================
# Byte arrays
# ========================================================================

sub read_bytes {
    my ($self, $num_to_read) = @_;
    my $num_read;
    my $buf;

    $num_read = read($self->{_io}, $buf, $num_to_read);
    if ($num_read != $num_to_read) {
        die "Requested $num_to_read bytes, but got only $num_read bytes";
    }
    return $buf;
}

sub read_bytes_full {
    my ($self) = @_;
    my $buf;

    read($self->{_io}, $buf, $self->size());
    return $buf;
}

sub ensure_fixed_contents {
    my ($self, $expected) = @_;
    my $buf;
    
    read($self->{_io}, $buf, length($expected));
    if ($buf ne $expected) {
        die "Unexpected fixed contents: got '$buf', was waiting for '$expected'";
    }
    return $buf;
}

# ========================================================================
# Strings
# ========================================================================

sub read_str_eos {
    my ($self, $encoding) = @_;
    my $buf;

    read($self->{_io}, $buf, $self->size());
    return decode($encoding, $buf);
}

sub read_str_byte_limit {
    my ($self, $size, $encoding) = @_;
    my $buf;

    read($self->{_io}, $buf, $size);
    return decode($encoding, $buf);    
}

sub read_strz {
    my ($self, $encoding, $term, $include_term, $consume_term, $eos_error) = @_;
    my $buf = '';

    while (1) {
        my $char;

        read($self->{_io}, $char, 1);
        if ($char eq '') {
            if ($eos_error) {
                die "End of stream reached, but no terminator '$term' found";
            } else {
                return $buf;
            }
        } elsif (ord($char) == $term) {
            $buf .= $char if $include_term;
            $self->seek($self->pos() - 1) unless $consume_term;
            return $buf;
        } else {
            $buf .= $char;
        }
    }
}

# ========================================================================
# Byte array processing
# ========================================================================

sub process_xor_one {
    my ($data, $key) = @_;

    $key = pack('C', $key);
    for (my $i = 0; $i < length($data); $i++) {
        substr($data, $i, 1) ^= $key;
    }
    return $data;
}

sub process_xor_many {
    my ($data, $key) = @_;
    my $ki = 0;
    my $kl = length($key);

    for (my $i = 0; $i < length($data); $i++) {
        substr($data, $i, 1) ^= substr($key, $ki, 1);
        $ki += 1;
        $ki = 0 if $ki >= $kl;
    }
    return $data;
}

sub process_rotate_left {
    my ($data, $amount, $group_size) = @_;

    die "Unable to rotate group of $group_size bytes yet" if $group_size != 1;

    my $mask = $group_size * 8 - 1;
    $amount &= $mask;
    my $anti_amount = -$amount & $mask;

    for (my $i = 0; $i < length($data); $i++) {
        my $byte = unpack('C', substr($data, $i, 1));
        substr($data, $i, 1) = pack('C', (($byte << $amount) | ($byte >> $anti_amount)) & 0xFF);
    }
    return $data;
}

1;
