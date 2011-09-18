#!perl 
# -T

use strict;
use warnings;

use Test::More tests => 4;
use Test::Dirs;
use IPC::Run qw( run timeout );
use Cwd;
use Readonly;

BEGIN {
  use lib 't/lib';
  use_ok( 'JGoff::App::Make::Compile' ) || print "Bail out!\n";
}

Readonly my $COMPILE_DIR => 't/compile';

# {{{ in_dir( sub { ... } )

sub in_dir {
  my ( $sub ) = @_;
  my $dir =
    temp_copy_ok( $COMPILE_DIR, 'copy compile_dir for compilation' );
  my $current_dir = getcwd;
  chdir $dir;
  $sub->();
  chdir $current_dir;
}

# }}}

Readonly my $CC => '/usr/bin/cc';

my $make = JGoff::App::Make::Compile->new(
  target => {
    'hello.o' => {
      prerequisite => [ 'hello.c', 'hello.h' ],
      recipe => sub {
        my ( $target, $prerequisite ) = @_;
        #'$(CC) $(CPPFLAGS) $(CFLAGS) -c'
        unless ( run [ $CC, '-c', "hello.c" ] ) {
          return $?;
        }
        return
      }
    },
  }
);

# {{{ basic compile test
{
  in_dir( sub {
    ok( !$make->run );
    ok( -e "hello.o" );
  } );
}
# }}}
