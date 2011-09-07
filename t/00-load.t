#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok( 'JGoff::App::Make' ) || print "Bail out!\n";
}

my $make = JGoff::App::Make->new;

eval { $make->run( target => 'all' ) };
like( $@, qr{ Must \s+ specify \s+ target }x );

my $run_all;
$make->add_target(
  name => 'all',
  dependency => [ 'b', 'c' ],
  action => sub {
    $all++
  }
);

eval { $make->run( name => 'all' ) };
like( $@, qr{ Missing dependencies 'b', 'c' } );

my $run_b;
$make->add_target(
  name => 'b',
  action => sub {
    $run_b++
  }
);
my $run_c;
$make->add_target(
  name => 'c',
  action => sub {
    $run_b++
  }
);

$make->run( name => 'all' );
is( $run_all, 1 );
is( $run_b, 1 );
is( $run_c, 1 );
