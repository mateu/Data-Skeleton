package Data::Skeleton;
use Moo;
use MooX::Types::MooseLike qw/Str/;
use Scalar::Util qw(blessed);
use Data::Dumper::Concise;

has 'value_marker' => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub { '' },
);

sub deflesh {
    my ($self, $data) = @_;
    if (ref($data) eq 'HASH') {
        return $self->_blank_hash($data);
    }
    elsif (ref($data) eq 'ARRAY') {
        return $self->_blank_array($data);
    }
    else {
        die "You need to pass the deflesh method either a hash or an array reference";
    }
}

sub _blank_hash {
    my ($self, $hashref) = @_;
    # Work on a copy
    my %hashref = %{$hashref};
    $hashref = \%hashref;

    foreach my $key (keys %{$hashref}) {
        my $value = $hashref->{$key};
        if (!ref($value)) {
            # blank a value that is not a reference
            $hashref->{$key} = $self->value_marker;
        }
        elsif (ref($value) eq 'SCALAR') {
            $hashref->{$key} = $self->value_marker;
        }
        elsif (ref($value) eq 'HASH') {

            # recurse when a value is a HashRef
            $hashref->{$key} = $self->_blank_hash($value);
        }

        # look inside ArrayRefs for HashRefs
        elsif (ref($value) eq 'ARRAY') {
            $hashref->{$key} = $self->_blank_array($value);
        }
        else {
            if (blessed($value)) {
                # Hash based objects have keys
                if (eval { keys %{$value}; 1; }) {
                    my $blanked_hash_object = $self->_blank_hash($value); #[keys %{$value}];
                    # Note that we have an object
                    # WARNING: we are altering the data structure by adding a key
                    $blanked_hash_object->{BLESSED_AS} = ref($value);
                    $hashref->{$key} = $blanked_hash_object;
                } else {
                    $hashref->{$key} = ref($value) . ' object';
                }
            }
            else {
                # To leave value or to nuke it in this case?  Leave for now.
            }
        }
    }
    return $hashref;
}

sub _blank_array {
    my ($self, $arrayref) = @_;

    my @ref_values =
      grep { ref($_) eq 'HASH' or ref($_) eq 'ARRAY' } @{$arrayref};
    # if no array values are a reference to either a Hash or an Array then we nuke the entire array
    if (!scalar @ref_values) {
        $arrayref = $self->value_marker;
    }
    else {
        $arrayref = [
            map {
                if (ref($_) eq 'HASH') {
                    $self->_blank_hash($_);
                }
                elsif (ref($_) eq 'ARRAY') {
                    $self->_blank_array($_);
                }
                else {
                    $self->value_marker;
                }
              } @{$arrayref}
        ];
    }
    return $arrayref;
}

#say Dumper dump_partial($page, {max_total_len => 1000, max_len => 0});

1;
