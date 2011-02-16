package Data::Morph;
use Moose;
use MooseX::Types::Moose(':all');
use MooseX::Types::Structured(':all');
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

has [qw/recto verso/] =>
(
    is => 'ro',
    does => 'Data::Morph::Role::Backend',
    required => 1,
);

has map =>
(
    is => 'ro',
    isa => ArrayRef
    [
        Dict
        [
            verso =>
            (
                Str|Dict
                [
                    read => (Str|Tuple[Str, CodeRef]),
                    write => (Str|Tuple[Str, CodeRef]),
                ]
            ),
            recto =>
            (
                Str|Dict
                [
                    read => (Str|Tuple[Str, CodeRef]),
                    write => (Str|Tuple[Str, CodeRef]),
                ]
            )
        ]
    ],
    required => 1,
);

has morpher =>
(
    is => 'ro',
    isa => HashRef,
    builder => '_build_morpher',
    lazy => 1,
);

sub _build_morpher
{
    my ($self) = @_;
    my $hash = {};
    my $map = $self->map;
    my ($recto, $verso) = ($self->recto, $self->verso);

    $hash->{$recto->input_type} = sub
    {
        my ($input) = @_;

        my $instance = $verso->generate_instance();
        foreach my $entry (@$map)
        {
            my ($recto_map, $verso_map) = @$entry{qw/recto verso/};

            my $val = $recto->retrieve
            (
                $input,
                (
                    ref($recto_map)
                    ? ref($recto_map->{read})
                        ? @{$recto_map->{read}}
                        : $recto_map->{read}
                    : $recto_map
                )
            );

            $verso->store
            (
                $instance,
                $val,
                (
                    ref($verso_map)
                    ? ref($verso_map->{write})
                        ? @{$verso_map->{write}}
                        : $verso_map->{write}
                    : $verso_map
                ),
            );
        }

        $verso->epilogue($instance);

        return $instance;
    };

    $hash->{$verso->input_type} = sub
    {
        my ($input) = @_;

        my $instance = $recto->generate_instance();
        foreach my $entry (@$map)
        {
            my ($recto_map, $verso_map) = @$entry{qw/recto verso/};

            my $val = $verso->retrieve
            (
                $input,
                (
                    ref($verso_map)
                    ? ref($verso_map->{read})
                        ? @{$verso_map->{read}}
                        : $verso_map->{read}
                    : $verso_map
                )
            );

            $recto->store
            (
                $instance,
                $val,
                (
                    ref($recto_map)
                    ? ref($recto_map->{write})
                        ? @{$recto_map->{write}}
                        : $recto_map->{write}
                    : $recto_map
                ),
            );
        }

        $recto->epilogue($instance);

        return $instance;

    };

    return $hash;
}

sub morph
{
    my ($self, $object) = pos_validated_list
    (
        \@_,
        {isa => __PACKAGE__},
        {isa => Defined},
    );

    return match_on_type $object => %{$self->morpher};
}

1;
__END__
