use strict;
use warnings FATAL => 'all';
use Data::Skeleton;
use Test::More;
use Test::Fatal;
use IO::Handle;
use CGI;
use Data::Dumper::Concise;

## Test data
my $page = {
    fruit  => 'apple',
    pie    => 'cherry',
    people => {
        parents => [ 'immortal', { hashish => 'for_all' } ],
        this    => 'can mess',
        with => { yo => 'people' }
    },
    array => [ { one => 2 } ],
    scalar_ref => \'string',
    io => IO::Handle->new,
    cgi => CGI->new,
};

is(ref($page), 'HASH', 'data is a hashref');

my $skeletonizer = Data::Skeleton->new;
my $skeleton = $skeletonizer->deflesh($page);
is_deeply([sort keys %{$skeleton}], [sort qw/fruit pie people array scalar_ref io cgi/], 'First Level Keys');

my $object = bless {code => sub {1}}, 'TestMe';
$skeleton = $skeletonizer->deflesh($object);
is_deeply([sort keys %{$skeleton}], [sort qw/code/], 'Object atrributes');
$object = CGI->new;
$skeleton = $skeletonizer->deflesh($object);
ok(defined $skeleton->{param}, 'param defined');

like(
  exception { $skeletonizer->deflesh(IO::Handle->new) },
  qr/You must pass/,
  'a file handle can not be defleshed'
  );

done_testing();
