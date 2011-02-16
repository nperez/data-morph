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
__END__
