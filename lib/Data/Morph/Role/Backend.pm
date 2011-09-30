package Data::Morph::Role::Backend;
use MooseX::Role::Parameterized;
use MooseX::Types::Moose(':all');
use MooseX::Params::Validate;

=role_parameter input_type

    isa: Moose::Meta::TypeConstraint
    required: 1

To properly constrain L</store> and L</retrieve>, a type constraint must be
made available. This must match what L</new_instance> generates.

=cut

parameter input_type =>
(
    isa => 'Moose::Meta::TypeConstraint',
    required => 1,
);

=role_parameter set_val

    isa: CodeRef, required: 1

This coderef should implement a set accessor to the type configured in
L</input_type>. The coderef will receive the instance, the key, and the value
as arguments and be executed in a void context.

=cut

parameter set_val =>
(
    isa => CodeRef,
    required => 1,
);

=role_parameter get_val

    isa: CodeRef, required: 1

This coderef should implement a get accessor to the type configured in
L</input_type>. The coderef will receive the instance and the key as arguments.
The return value will then be used by the system.

=cut

parameter get_val =>
(
    isa => CodeRef,
    required => 1,
);

role
{

=role_require epilogue

This method is required for all backends (even if it is a no-op). Once
processing is complete this method will be called with the final, populated
instance. If additional processing should take place on the instance as a whole
rather on individual properties of it, do it here.

=cut

    requires 'epilogue';

    my $p = shift;

=attribute_public new_instance

    is: ro, isa: CodeRef, required: 1

Each backend should provide a coderef or require one upon construction that is
an instance factory. The instances returned must match L</input_type>. The
instance factory will receive the raw input as the only argument to allow for
dynamic instance creation.

=cut

    has new_instance =>
    (
        is => 'ro',
        isa => CodeRef,
        required => 1,
    );

=attribute_public input_type

    is: ro, isa: Moose::Meta::TypeConstraint, default: role parameter

This attribute is provided so that users of the backend can process different
types other than the default provided at role consumption

=cut

    has input_type =>
    (
        is => 'ro',
        isa => 'Moose::Meta::TypeConstraint',
        default => sub { $p->input_type },
    );

=method_public generate_instance

This method access L</new_instance> and invokes it with the provided raw input
as an argument, returning its return value

=cut

    method generate_instance => sub
    {
        my ($self, $input) = @_;
        return $self->new_instance->($input);
    };

=method_public retrieve

    (INSTANCE, Str, CodeRef?)

This method is what fetches the value from the instance using L</get_val>. The
optional coderef parameter is what is passed in from the map if it is defined
for a read operation. The coderef must be called with the return value from
L</get_val>. And its return value returned.

=cut

    method retrieve => sub
    {
        my ($self, $object, $key, $post) = pos_validated_list
        (
            \@_,
            {isa => __PACKAGE__},
            {isa => $p->input_type},
            {isa => Str},
            {isa => CodeRef, optional => 1},
        );

        my $val = $p->get_val->($object, $key);
        $val = $post->($val) if defined($post);
        return $val;
    };

=method_public store

    (INSTANCE, Defined, Str, CodeRef?)

This method takes the Defined value and sets it into the instance using the Str
key. The optional coderef parameter is what is passed if defined in the map in
a write operation. If it is provided, it must be called with the value and its
return value ultimately used in the storage operation, L</set_val>

=cut


    method store => sub
    {
        my ($self, $object, $val, $key, $pre) = pos_validated_list
        (
            \@_,
            {isa => __PACKAGE__},
            {isa => $p->input_type},
            {isa => Defined},
            {isa => Str},
            {isa => CodeRef, optional => 1}
        );

        $val = $pre->($val) if defined($pre);
        $p->set_val->($object, $key, $val);
    };
};
1;
__END__
=head1 SYNOPSIS

    package Data::Morph::Backend::Object;
    use Moose;
    use MooseX::Types::Moose(':all');
    use MooseX::Params::Validate;
    use namespace::autoclean;

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

    1;

=head1 DESCRIPTION

This module provides a simple composable behavior that backend authors must
consume and fill out so that it operates seamlessly within a Data::Morph
transformation
