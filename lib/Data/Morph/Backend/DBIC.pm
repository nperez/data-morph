package Data::Morph::Backend::DBIC;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose(':all');
use MooseX::Params::Validate;
use Devel::PartialDump('dump');
use namespace::autoclean;
use DBIx::Class;

has result_set =>
(
    is => 'ro',
    isa => class_type('DBIx::Class::ResultSet'),
    required => 1,
);

has auto_insert =>
(
    is => 'ro',
    isa => Bool,
    default => 0,
);

has new_instance =>
(
    is => 'ro',
    isa => CodeRef,
    default => sub
    {
        my ($self) = @_;
        return sub { $self->result_set->new_result({}) };
    },
);

sub epilogue
{
    my ($self, $obj) = @_;

    $obj->update_or_insert
        if $self->auto_insert;
}

with 'Data::Morph::Role::Backend' =>
{
    input_type => class_type('DBIx::Class::Row'),
    get_val => sub
    {
        my ($obj, $key) = @_;
        if($obj->can($key))
        {
            return $obj->$key;
        }
        elsif($obj->has_column($key))
        {
            return +{$obj->get_inflated_columns}->{$key};
        }
        else
        {
            die "Can't find '$key' column in: " . dump($obj);
        }
    },
    set_val => sub
    {
        my ($obj, $key, $value) = @_;
        if($obj->can($key))
        {
            $obj->$key($value);
        }
        elsif($obj->has_column($key))
        {
            return $obj->set_inflated_columns({$key => $value});
        }
        else
        {
            die "Can't find '$key' column in: " . dump($obj);
        }
    }
};

1;
__END__
