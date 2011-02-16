package Data::Morph::Role::Backend;
use MooseX::Role::Parameterized;
use MooseX::Types::Moose(':all');
use MooseX::Params::Validate;

parameter input_type =>
(
    isa => 'Moose::Meta::TypeConstraint',
    required => 1,
);

parameter set_val =>
(
    isa => CodeRef,
    required => 1,
);

parameter get_val =>
(
    isa => CodeRef,
    required => 1,
);

role
{
    requires 'epilogue';

    my $p = shift;

    has new_instance =>
    (
        is => 'ro',
        isa => CodeRef,
        required => 1,
    );

    has input_type =>
    (
        is => 'ro',
        isa => 'Moose::Meta::TypeConstraint',
        default => sub { $p->input_type },
    );

    method generate_instance => sub
    {
        my ($self) = @_;
        return $self->new_instance->();
    };

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
