#!perl 
# -T

use strict;
use warnings;

use Test::More tests => 3;
use Test::Dirs;
use IPC::Run qw( run timeout );
use Cwd;

BEGIN {
  use lib 't/lib';
  use_ok( 'JGoff::App::Make::Compile' ) || print "Bail out!\n";
}

my $compile_dir = 't/compile';

use lib 't/lib';
use JGoff::App::Make::Compile;

# {{{ basic compile test
{
  my $tmp_dir =
    temp_copy_ok( $compile_dir, 'copy compile_dir for compilation' );
  my $make = JGoff::App::Make::Compile->new(
    target => {
      'hello.o' => {
        prerequisite => [ 'hello.c', 'hello.h' ],
        recipe => sub {
          my ( $target, $prerequisite ) = @_;
          #'$(CC) $(CPPFLAGS) $(CFLAGS) -c'
          unless ( run [ '/usr/bin/cc', '-c', "$tmp_dir/hello.c" ] ) {
            return $?;
          }
        }
      },
    }
  );
  my $current_dir = getcwd;
  chdir $tmp_dir;
  $make->run;

  ok( -e "$tmp_dir/hello.o" );
  chdir $current_dir;
}

# }}}
