package Data::Morph::Backend::Object;

#ABSTRACT: Provides a Data::Morph backend for talking to objects

use Moose;
use MooseX::Types::Moose(':all');
use MooseX::Params::Validate;
use namespace::autoclean;

=method_public epilogue

Implements L<Data::Morph::Role::Backend/epilogue> as a no-op

=cut

sub epilogue { }

with 'Data::Morph::Role::Backend' =>
{
    input_type => Object,
    get_val => sub
    {
        my ($obj, $key) = @_;
        return $obj->$key;
    },
    set_val => sub
    {
        my ($obj, $key, $val) = @_;
        $obj->$key($val);
    },
};

__PACKAGE__->meta->make_immutable();
1;
__END__

=head1 DESCRIPTION

Data::Morph::Backend::Object provides a backend for interacting with arbitrary
objects. Directives defined in map should correspond to methods or attributes
