#!perl 
# -T

use strict;
use warnings;

use Test::More tests => 9;
use Test::Dirs;
use IPC::Run qw( run timeout );
use Cwd;
use Readonly;

BEGIN {
  use lib 't/lib';
  use_ok( 'JGoff::App::Make::Compile' ) || print "Bail out!\n";
}

Readonly my $COMPILE_DIR => 't/compile';
Readonly my $TIMEOUT => 10;

# {{{ in_dir( sub { ... } )

sub in_dir(&) {
  my ( $sub ) = @_;
  my $current_dir = getcwd;
  my $dir =
    temp_copy_ok( $COMPILE_DIR, 'copy compile_dir for compilation' );
  chdir $dir;
  $sub->();
  chdir $current_dir;
}

# }}}

Readonly my $CC => '/usr/bin/cc';
Readonly my $CPPFLAGS => undef;
Readonly my $CFLAGS => undef;

# {{{ $make

my $make = JGoff::App::Make::Compile->new(
  target => {
    'hello.o' => {
      prerequisite => [ 'hello.c', 'hello.h' ],
      recipe => sub {
        my ( $target, $prerequisite ) = @_;

        my @recipe = grep { defined and $_ ne '' } ( $CC, $CPPFLAGS, $CFLAGS, '-c' );
        my ( $in, $out, $err );
        unless ( run [ @recipe, "hello.c" ],
                     \$in, \$out, \$err,
                     timeout( $TIMEOUT ) ) {
          return $?;
        }
        return
      }
    },
  }
);

# }}}

# {{{ basic compile test

in_dir {
  ok( !$make->run );
  ok( -e "hello.o" );
  ok( !$make->run );
};

# }}}

# {{{ Delete a header file, attempt a compile.

in_dir {
  unlink getcwd().'/hello.h' or die "Couldn't unlink hello.h: $!\n";
  is( $make->run, 256 );
};

# }}}

# {{{ Delete the source file, attempt a compile.

in_dir {
  unlink getcwd().'/hello.c' or die "Couldn't unlink hello.c: $!\n";
  is( $make->run, 256 );
};

# }}}
