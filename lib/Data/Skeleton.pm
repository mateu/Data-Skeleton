use strictures 1;
package Data::Skeleton;
use Moo;
use MooX::Types::MooseLike::Base qw/Str/;
use Scalar::Util qw(blessed);
use Data::Dumper::Concise;

=head1 NAME

Data::Skeleton - Show the keys of a deep data structure

=head1 SYNOPSIS

    use Data::Skeleton;
    my $ds = Data::Skeleton->new;
    my $deep_data_structure = {
        id            => 'blahblahblah',
        last_modified => 1,
        sections      => [
            {
                content => 'h1. Ice Cream',
                class   => 'textile'
            },
            {
                content => '# Chocolate',
                class   => 'markdown'
            },
        ],
    };
    use Data::Dumper::Concise;
    print Dumper $ds->deflesh($deep_data_structure);

# results in:

    {
      id => "",
      last_modified => "",
      sections => [
        {
          class => "",
          content => ""
        },
        {
          class => "",
          content => ""
        }
      ]
    }

=head1 DESCRIPTION

Sometimes you just want to see the "schema" of a data structure.
This modules shows only the keys with blanks for the values.

=cut

has 'value_marker' => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub { '' },
);

=head1 METHODS

=head2 deflesh

    Signature: (HashRef|ArrayRef)
      Returns: The data structure with values blanked

=cut

sub deflesh {
    my ($self, $data) = @_;
    if (ref($data) eq 'HASH') {
        return $self->_blank_hash($data);
    } elsif (ref($data) eq 'ARRAY') {
        return $self->_blank_array($data);
    } elsif (blessed($data) && eval { keys %{$data}; 1; } ) {
        return $self->_blank_hash($data);
    } else {
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

1;

=head1 SEE ALSO

Data::Dump::Partial is way more feature rich than this module.
The only reason I didn't use it is that the output is all on one line.
To get something similar to deflesh with Data::Dump::Partial do:

    say Dumper dump_partial($data, {max_total_len => $big_enough_number, max_len => 0});

The important part being max_len = 0

This module was inspired when I wanted to see the "schema" of a MongoDB document.
If you want to enforce a schema (and have a place to recall its nature)
then you might consider L<Data::Schema>

=head1 AUTHORS

Mateu Hunter C<hunter@missoula.org>

=head1 COPYRIGHT

Copyright 2011-2012, Mateu Hunter

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
