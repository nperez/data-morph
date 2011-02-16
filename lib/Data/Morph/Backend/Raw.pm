package Data::Morph::Backend::Raw;
use Moose;
use MooseX::Params::Validate;
use MooseX::Types::Moose(':all');
use Data::DPath(qw|dpath dpathr|);
use Devel::PartialDump('dump');
use namespace::autoclean;

has new_instance =>
(
    is => 'ro',
    isa => CodeRef,
    default => sub { sub { +{} } },
);

sub epilogue { }

with 'Data::Morph::Role::Backend' =>
{
    input_type => HashRef,
    get_val => sub
    {
        my ($obj, $key) = @_;
        my @refs = dpath($key)->match($obj);

        die "No matching points for key '$key' in: \n". dump($obj)
            unless scalar(@refs);

        die "Too many maching points for '$key' in: \n". dump($obj)
            if scalar(@refs) > 1;

        return $refs[0];
    },
    set_val => sub
    {
        my ($obj, $key, $val) = @_;
        my @refs = dpathr($key)->match($obj);

        die "Too many maching points for '$key' in: \n". dump($obj)
            if scalar(@refs) > 1;

        unless(scalar(@refs))
        {
            my @paths = split('/', $key);
            my $place = $obj;
            for(0..$#paths)
            {
                next if $paths[$_] eq '';
                if($_ == $#paths)
                {
                    $place->{$paths[$_]} = $val;
                }
                else
                {
                    $place = \%{$place->{$paths[$_]} = {}};
                }
            }
        }
        else
        {
            ${$refs[0]} = $val;
        }
    },
};
