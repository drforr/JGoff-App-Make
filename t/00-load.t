#!perl -T

use Test::More tests => 8;

BEGIN {
  use_ok( 'JGoff::App::Make' ) || print "Bail out!\n";
}

#
# myApp : core.o gui.o api.o
#	ln core.o gui.o api.o -lm -o myApp
#
# core.o : core.c core.h
#	cc core.c -o core.o
#
# gui.o : gui.c gui.h
#	cc gui.c -o gui.o
#
# api.o : api.c api.h
#	cc api.c -o api.o
#

my %mtime = (
  'core.c' => 1,
  'core.h' => 4,
  'gui.c' => 7,
  'gui.h' => 10,
  'api.c' => 13,
  'api.h' => 16,
#  'core.o' => undef, # XXX In case core.o "already exists"
#  'gui.o' => undef, # XXX In case gui.o "already exists"
#  'api.o' => undef, # XXX In case api.o "already exists"
#  'myApp' => undef # XXX In case myApp "already exists"
);
my %can_compile = (
  'core.c' => 1,
  'core.h' => 1,
  'api.c' => 1,
  'api.h' => 1,
  'gui.c' => 1,
  'gui.h' => 1,
  'myApp' => 1, # Can link thing
);
my $ticks = 17;
my $make = JGoff::App::Make->new(
  mtime => \%mtime,
  target => {
    'core.c' => { },
    'core.h' => { },

# {{{ core.o

    'core.o' => {
      dependency => [ 'core.c', 'core.h' ],
      update => sub {
$ticks+= rand(2) + 1;
        return 1 unless exists $can_compile{'core.c'};
$ticks+= rand(2) + 1;
        return 1 unless exists $can_compile{'core.h'};
$ticks+= rand(2) + 1;
        $mtime{'core.o'} = $ticks; # XXX Feed back the mtime changes
        return;
      }
    },

# }}}

    'gui.c' => { },
    'gui.h' => { },

# {{{ gui.o

    'gui.o' => {
      dependency => [ 'gui.c', 'gui.h' ],
      update => sub {
$ticks+= rand(2) + 1;
        return 1 unless exists $can_compile{'gui.c'};
$ticks+= rand(2) + 1;
        return 1 unless exists $can_compile{'gui.h'};
$ticks+= rand(2) + 1;
        $mtime{'gui.o'} = $ticks; # XXX Feed back the mtime changes
        return;
      }
    },

# }}}

    'api.c' => { },
    'api.h' => { },

# {{{ api.o

    'api.o' => {
      dependency => [ 'api.c', 'api.h' ],
      update => sub {
$ticks+= rand(2) + 1;
        return 1 unless exists $can_compile{'api.c'};
$ticks+= rand(2) + 1;
        return 1 unless exists $can_compile{'api.h'};
$ticks+= rand(2) + 1;
        $mtime{'api.o'} = $ticks; # XXX Feed back the mtime changes
        return;
      }
    },

# }}}

# {{{ myApp

    'myApp' => {
      dependency => [ 'core.o', 'gui.o', 'api.o' ],
      update => sub {
$ticks+= rand(2) + 1;
        return 1 unless exists $can_compile{'myApp'};
$ticks+= rand(2) + 1;
        $mtime{'myApp'} = $ticks; # XXX Feed back the mtime changes
        return;
      }
    }

# }}}

  }
);
$make->run( target => 'myApp' );

=pod

my $make = JGoff::App::Make->new;

#
# Failing tests
#
eval { $make->run( ) };
like( $@, qr{ Must \s+ specify \s+ argument \s+ 'target' }x );

eval { $make->run( name => 'foobar' ) };
like( $@, qr{ Must \s+ specify \s+ argument \s+ 'target' }x );

eval { $make->run( target => 'foobar' ) };
like( $@, qr{ No \s+ target \s+ 'foobar' \s+ found }x );

$make->add_target(
  target => 'foobar',
  dependency => [ 'foo.o', 'bar.o' ],
  action => sub {
    # "link" the two libraries
  }
);

eval { $make->run( target => 'foobar' ) };
like( $@, qr{ Missing dependencies 'foo.o', 'bar.o' } );

$make->add_target(
  target => 'foo.o',
  dependency => [ 'foo.c' ],
  action => sub { }
);
$make->add_target(
  target => 'bar.o',
  dependency => [ 'foo.c' ],
  action => sub { }
);

$make->add_target( target => 'foo.c', action => sub { } );
$make->add_target( target => 'bar.c', action => sub { } );

$make->run( target => 'foobar' );

=cut
