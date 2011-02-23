use Test::More;
use warnings;
use strict;

use Try::Tiny;
use Data::Morph;
use Data::Morph::Backend::DBIC;
use Data::Morph::Backend::Object;
use Data::Morph::Backend::Raw;
use DBD::SQLite;

{
    package Foo;
    use Moose;
    use namespace::autoclean;

    has foo => ( is => 'ro', isa => 'Int', default => 1, writer => 'set_foo' );
    has bar => ( is => 'rw', isa => 'Str', default => '123ABC');
    has flarg => ( is => 'rw', isa => 'Str', default => 'boo');
    1;
}

{
    package Blah;
    use base 'DBIx::Class::Core';
    __PACKAGE__->table('blah');
    __PACKAGE__->add_columns(qw/some_foo bar_zoop ker_flarg_fluffle/);
    __PACKAGE__->set_primary_key('some_foo');
    1;
}

{
    package Bar;
    use base 'DBIx::Class::Schema';
    __PACKAGE__->register_class('Blah', 'Blah');
    1;
}

my $schema = Bar->connect('dbi:SQLite:dbname=','','');
$schema->deploy({ add_drop_table => 1 });
$schema->resultset('Blah')->all();

my $map1 =
[
    {
        recto =>
        {
            read => 'foo',
            write => 'set_foo',
        },
        verso => '/FOO',
    },
    {
        recto =>
        {
            read => ['bar', sub { my ($f) = @_; $f =~ s/\d+//; $f } ], # post read
            write => [ 'bar', sub { "123".shift(@_) } ], # pre write
        },
        verso => '/BAR',
    },
    {
        recto => 'flarg',
        verso => '/some/path/goes/here/flarg'
    },
];

my $map2 =
[
    {
        recto => $map1->[0]->{recto},
        verso => 'some_foo',
    },
    {
        recto => $map1->[1]->{recto},
        verso => 'bar_zoop',
    },
    {
        recto => $map1->[2]->{recto},
        verso => 'ker_flarg_fluffle',
    },
];

my $map3 =
[
    {
        recto => $map2->[0]->{verso},
        verso => $map1->[0]->{verso},
    },
    {
        recto => $map2->[1]->{verso},
        verso => $map1->[1]->{verso},
    },
    {
        recto => $map2->[2]->{verso},
        verso => $map1->[2]->{verso},
    },
];

my $obj_backend = Data::Morph::Backend::Object->new(new_instance => sub { Foo->new() });
my $raw_backend = Data::Morph::Backend::Raw->new();
my $dbc_backend = Data::Morph::Backend::DBIC->new(result_set => $schema->resultset('Blah'));

try
{
    my $morpher = Data::Morph->new(
        recto => $obj_backend,
        verso => $raw_backend,
        map => $map1
    );

    my $foo1 = Foo->new();
    my $hash = $morpher->morph($foo1);

    is_deeply
    (
        $hash,
        {
            FOO => 1,
            BAR => 'ABC',
            some =>
            {
                path =>
                {
                    goes =>
                    {
                        here =>
                        {
                            flarg => 'boo'
                        }
                    }
                }
            }
        },
        'Output hash matches what is expected'
    );

    my $foo2 = $morpher->morph($hash);

    is($foo2->foo, $foo1->foo, 'foo matches on object');
    is($foo2->bar, $foo1->bar, 'bar matches on object');
    is($foo2->flarg, $foo1->flarg, 'bar matches on object');
}
catch
{
    fail($_);
};

try
{
    my $morpher = Data::Morph->new(
        recto => $obj_backend,
        verso => $dbc_backend,
        map => $map2
    );

    my $foo1 = Foo->new();
    my $row = $morpher->morph($foo1);

    is($row->some_foo, '1', 'row data matches foo');
    is($row->bar_zoop, 'ABC', 'row data matches bar');
    is($row->ker_flarg_fluffle, 'boo', 'row data matches flarg');

    $row->insert();

    my $foo2 = $morpher->morph($row);
    is($foo2->foo, $foo1->foo, 'foo matches on object');
    is($foo2->bar, $foo1->bar, 'bar matches on object');
    is($foo2->flarg, $foo1->flarg, 'bar matches on object');

}
catch
{
    fail($_);
};

try
{
    my $morpher = Data::Morph->new(
        recto => $dbc_backend,
        verso => $raw_backend,
        map => $map3,
    );

    my $row = $schema->resultset('Blah')->first();

    my $hash = $morpher->morph($row);

    is_deeply
    (
        $hash,
        {
            FOO => 1,
            BAR => 'ABC',
            some =>
            {
                path =>
                {
                    goes =>
                    {
                        here =>
                        {
                            flarg => 'boo'
                        }
                    }
                }
            }
        },
        'Output hash matches what is expected'
    );

    my $row2 = $morpher->morph($hash);

    is($row2->some_foo, $row->some_foo, 'row data matches foo');
    is($row2->bar_zoop, $row->bar_zoop, 'row data matches bar');
    is($row2->ker_flarg_fluffle, $row->ker_flarg_fluffle, 'row data matches flarg');
}
catch
{
    fail($_);
};

done_testing();


