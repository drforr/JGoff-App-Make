#!perl 
# -T

use strict;
use warnings;

use Test::More tests => 3;
use Test::Dirs;
use IPC::Run qw( run timeout );
use Cwd;
use Readonly;

BEGIN {
  use lib 't/lib';
  use_ok( 'JGoff::App::Make::Compile' ) || print "Bail out!\n";
}

Readonly my $COMPILE_DIR => 't/compile';
Readonly my $CC => '/usr/bin/cc';

# {{{ basic compile test
{
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
        }
      },
    }
  );

  my $current_dir = getcwd;
  my $tmp_dir =
    temp_copy_ok( $COMPILE_DIR, 'copy compile_dir for compilation' );
  chdir $tmp_dir;
  $make->run;

  ok( -e "$tmp_dir/hello.o" );
  chdir $current_dir;
}

# }}}
