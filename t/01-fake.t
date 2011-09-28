#!perl -T

use strict;
use warnings;

use Test::More tests => 27;

BEGIN {
  use lib 't/lib';
  use_ok( 'JGoff::App::Make::FakeFilesystem' ) || print "Bail out!\n";
}

# {{{ Basic build recipe
#
# hello.o: hello.c hello.h
#	cc -c hello.c
#

{
  my %recipe;
  my $hello_error = 1;
  my $start_ticks = time;
  my $make = JGoff::App::Make::FakeFilesystem->new(
    default => 'hello.o',
    filesystem => {
      'hello.c' => { mtime => $start_ticks - 6 },
      'hello.h' => { mtime => $start_ticks - 4 },
      'hello.o' => { mtime => $start_ticks - 2 },
    },
    target => {
      'hello.o' => {
        prerequisite => [ 'hello.c', 'hello.h' ],
        recipe => sub {
          my $self = shift;
          $recipe{'hello.o'}++;
          $self->_advance_ticks;
          if ( $hello_error ) {
            return $hello_error; # Oh noes, 'cc -c hello.o' returned an error!
          }
          $self->_touch( 'hello.o' );
          return;
        }
      },
      clean => sub {
        my $self = shift;
        $recipe{'clean'}++;
        $self->_advance_ticks;
        delete $self->filesystem->{'hello.o'};
        return;
      }
    }
  );

  #
  # All files up-to-date
  #
  # make hello.o # Should "exit" successfully, do nothing.
  #
  ok( ! $make->run( target => 'hello.o' ), 'Nothing to do!' );
  ok( !exists $recipe{'hello.o'}, 'Recipe for hello.o was not used' );
  ok( !exists $recipe{'clean'}, 'Recipe for clean was not used' );
  is( $make->_mtime( 'hello.o' ),
      $start_ticks - 2, 'Library for hello.o not touched' );
  ok( $make->ticks == $start_ticks, 'Ticks remain stable' );
  %recipe = ();

  #
  # All files up-to-date
  #
  # make clean # Should "exit" successfully, "delete" hello.o
  #
  ok( ! $make->run( target => 'clean' ), 'Make clean ran successfully' );
  ok( !exists $recipe{'hello.o'}, 'Recipe for hello.o was not used' );
  is( $recipe{'clean'}, 1, 'Recipe for clean was used' );
  ok( ! $make->filesystem->{'hello.o'}, 'Library for hello.o deleted' );
  ok( $make->ticks > $start_ticks, 'Ticks advanced' );
  %recipe = ();

  #
  # hello.c up-to-date
  # hello.h up-to-date
  # hello.o does not exist
  #
  # make hello.o # Should "exit" with an error, hello.c has an "error" in it
  #
  is( $make->run( target => 'hello.o' ), 1, 'Make failed correctly' );
  is( $recipe{'hello.o'}, 1, 'Recipe for hello.o was used' );
  ok( !exists $recipe{'clean'}, 'Recipe for clean was not used' );
  ok( ! $make->filesystem->{'hello.o'}, 'Library for hello.o still not there' );
  %recipe = ();
  $hello_error = undef;

  #
  # hello.c up-to-date, has been "edited" to remove the "error"
  # hello.h up-to-date
  # hello.o does not exist
  #
  # make hello.o # Should "exit" cleanly, build hello.o
  #
  ok( ! $make->run( target => 'hello.o' ), 'Make ran successfully' );
  is( $recipe{'hello.o'}, 1, 'Recipe for hello.o was used' );
  ok( !exists $recipe{'clean'}, 'Recipe for clean was not used' );
  ok( $make->filesystem->{'hello.o'}, 'Library for hello.o was created' );
  %recipe = ();

  #
  # hello.c up-to-date
  # hello.h "touched", "edited" to cause an "error"
  # hello.o up-to-date
  #
  # make hello.o # Should "exit" with an error, not update hello.o
  #
  $make->_touch( 'hello.h' );
  $hello_error = 1; # "break" hello.h
  is( $make->run( target => 'hello.o' ), 1,
      'Make failed correctly after hello.h "broken"' );
  is( $recipe{'hello.o'}, 1, 'Recipe for hello.o was used' );
  ok( !exists $recipe{'clean'}, 'Recipe for clean was not used' );
  ok( $make->_mtime( 'hello.h' ) > $make->_mtime( 'hello.o' ),
      'hello.o was correctly not updated' );
  %recipe = ();

  #
  # hello.c still up-to-date
  # hello.h "touched", "edited" to fix the "error"
  # hello.o still up-to-date, will be updated after the build
  #
  # make hello.o #  Should "exit" cleanly, update hello.o
  #
  $make->_touch( 'hello.h' );
  $hello_error = undef; # "clear up" the error
  ok( ! $make->run( target => 'hello.o' ), 'Make ran successfully' );
  is( $recipe{'hello.o'}, 1, 'Recipe for hello.o was used' );
  ok( !exists $recipe{'clean'}, 'Recipe for clean was not used' );
  ok( $make->_mtime( 'hello.o' ) > $make->_mtime( 'hello.h' ),
      'hello.o was correctly updated' );
  %recipe = ();
}

# }}}

# {{{ GNU Make sample
#
# edit : main.o kbd.o command.o display.o insert.o search.o files.o utils.o
#         cc -o edit main.o kbd.o command.o display.o \
#                    insert.o search.o files.o utils.o
# 
# main.o : main.c defs.h
#         cc -c main.c
# kbd.o : kbd.c defs.h command.h
#         cc -c kbd.c
# command.o : command.c defs.h command.h
#         cc -c command.c
# display.o : display.c defs.h buffer.h
#         cc -c display.c
# insert.o : insert.c defs.h buffer.h
#         cc -c insert.c
# search.o : search.c defs.h buffer.h
#         cc -c search.c
# files.o : files.c defs.h buffer.h command.h
#         cc -c files.c
# utils.o : utils.c defs.h
#         cc -c utils.c
# clean :
#         rm edit main.o kbd.o command.o display.o \
#            insert.o search.o files.o utils.o
#

{
  my $start_ticks = 9;
  my %recipe_run;
  my $make = JGoff::App::Make::FakeFilesystem->new(
    ticks => $start_ticks,
    default => 'edit',
    filesystem => {
      'main.c' => { mtime => $start_ticks - 20 },
      'defs.h' => { mtime => $start_ticks - 18 },
      'kbd.c' => { mtime => $start_ticks - 16 },
      'command.h' => { mtime => $start_ticks - 14 },
      'command.c' => { mtime => $start_ticks - 12 },
      'display.c' => { mtime => $start_ticks - 10 },
      'buffer.h' => { mtime => $start_ticks - 8 },
      'insert.c' => { mtime => $start_ticks - 6 },
      'search.c' => { mtime => $start_ticks - 4 },
      'files.c' => { mtime => $start_ticks - 2 },
      'utils.c' => { mtime => $start_ticks },
    },
    target => {
      'edit' => {
        prerequisite => [
          qw (main.o kbd.o command.o display.o
              insert.o search.o files.o utils.o )
        ],
        recipe => sub {
          my $self = shift;
          $self->_advance_ticks;
          $recipe_run{'edit'}++;
        }
      },
      'main.o' => { prerequisite => [qw( main.c defs.h ) ], }, # cc -c main.c
      'kbd.o' => { prerequisite => [qw( kbd.c defs.h command.h ) ], },
      'command.o' => { prerequisite => [qw( command.c defs.h command.h ) ], },
      'display.o' => { prerequisite => [qw( display.c defs.h buffer.h ) ], },
      'insert.o' => { prerequisite => [qw( insert.c defs.h buffer.h ) ], },
      'search.o' => { prerequisite => [qw( search.c defs.h buffer.h ) ], },
      'files.o' => { prerequisite => [qw( files.c defs.h buffer.h command.h ) ], },
      'utils.o' => { prerequisite => [qw( utils.c defs.h ) ], },
      clean => sub {
        my $self = shift;
        $self->_advance_ticks;
        delete $self->filesystem->{$_} for
          qw( edit main.o kbd.o command.o display.o
              insert.o search.o files.o utils.o );
        return;
      }
    }
  );

#  #
#  # All files up-to-date
#  #
#  # make hello.o # Should "exit" successfully, do nothing.
#  #
#  ok( ! $make->run( target => 'hello.o' ), 'Nothing to do!' );
#  ok( ! $recipe_called, 'Recipe for hello.o was not used' );
#  ok( ! $clean_ran, 'Recipe for clean was not used' );
#  is( $make->_mtime( 'hello.o' ),
#      $start_ticks - 2, 'Library for hello.o not touched' );
#  ok( $make->ticks == $start_ticks, 'Ticks remain stable' );
#  $recipe_called = undef;
#  $clean_ran = undef;
#
#  #
#  # All files up-to-date
#  #
#  # make clean # Should "exit" successfully, "delete" hello.o
#  #
#  ok( ! $make->run( target => 'clean' ), 'Make clean ran successfully' );
#  ok( ! $recipe_called, 'Recipe for hello.o was not used' );
#  is( $clean_ran, 1, 'Recipe for clean was used' );
#  ok( ! $make->filesystem->{'hello.o'}, 'Library for hello.o deleted' );
#  ok( $make->ticks > $start_ticks, 'Ticks advanced' );
#  $recipe_called = undef;
#  $clean_ran = undef;
#
#  #
#  # hello.c up-to-date
#  # hello.h up-to-date
#  # hello.o does not exist
#  #
#  # make hello.o # Should "exit" with an error, hello.c has an "error" in it
#  #
#  is( $make->run( target => 'hello.o' ), 1, 'Make failed correctly' );
#  is( $recipe_called, 1, 'Recipe for hello.o was run, failed' );
#  ok( ! $clean_ran, 'Recipe for clean was not used' );
#  ok( ! $make->filesystem->{'hello.o'}, 'Library for hello.o still not there' );
#  $recipe_called = undef;
#  $clean_ran = undef;
#  $hello_error = undef;
#
#  #
#  # hello.c up-to-date, has been "edited" to remove the "error"
#  # hello.h up-to-date
#  # hello.o does not exist
#  #
#  # make hello.o # Should "exit" cleanly, build hello.o
#  #
#  ok( ! $make->run( target => 'hello.o' ), 'Make ran successfully' );
#  is( $recipe_called, 1, 'Recipe for hello.o was run successfully' );
#  ok( ! $clean_ran, 'Recipe for clean was not used' );
#  ok( $make->filesystem->{'hello.o'}, 'Library for hello.o was created' );
#  $recipe_called = undef;
#  $clean_ran = undef;
#
#  #
#  # hello.c up-to-date
#  # hello.h "touched", "edited" to cause an "error"
#  # hello.o up-to-date
#  #
#  # make hello.o # Should "exit" with an error, not update hello.o
#  #
#  $make->_touch( 'hello.h' );
#  $hello_error = 1; # "break" hello.h
#  is( $make->run( target => 'hello.o' ), 1, 'Make failed correctly after hello.h "broken"' );
#  is( $recipe_called, 1, 'Recipe for hello.o was run' );
#  ok( ! $clean_ran, 'Recipe for clean was not used' );
#  ok( $make->_mtime( 'hello.h' ) > $make->_mtime( 'hello.o' ),
#      'hello.o was correctly not updated' );
#  $recipe_called = undef;
#  $clean_ran = undef;
#
#  #
#  # hello.c still up-to-date
#  # hello.h "touched", "edited" to fix the "error"
#  # hello.o still up-to-date, will be updated after the build
#  #
#  # make hello.o #  Should "exit" cleanly, update hello.o
#  #
#  $make->_touch( 'hello.h' );
#  $hello_error = undef; # "clear up" the error
#  ok( ! $make->run( target => 'hello.o' ), 'Make ran successfully' );
#  is( $recipe_called, 1, 'Recipe for hello.o was run successfully' );
#  ok( ! $clean_ran, 'Recipe for clean was not used' );
#  ok( $make->_mtime( 'hello.o' ) > $make->_mtime( 'hello.h' ),
#      'hello.o was correctly updated' );
}

# }}}

=pod

# {{{ Multilevel make

{
  #
  # myApp : core.o gui.o api.o
  #	ln core.o gui.o api.o -lm -o myApp
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  # # Add another layer here to properly test recursion
  # library.o : gui.o api.o
  #	ln gui.o api.o -o library.o
  #
  # gui.o : gui.c gui.h
  #	cc gui.c -o gui.o
  #
  # api.o : api.c api.h
  #	cc api.c -o api.o
  #
  my $ticks = 17;
  my $make = JGoff::App::Make::FakeFilesystem->new(
    ticks => 17,
    filesystem => {
      'core.c' => { mtime => 1 },
      'core.h' => { mtime => 4 },
      'gui.c' => { mtime => 7 },
      'gui.h' => { mtime => 10 },
      'api.c' => { mtime => 13 },
      'api.h' => { mtime => 16 } 
    },
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
      },
      'gui.o' => {
        prerequisite => [ 'gui.c', 'gui.h' ],
      },
      'api.o' => {
        prerequisite => [ 'api.c', 'api.h' ],
      },
      'library.o' => {
        prerequisite => [ 'gui.o', 'api.o' ],
      },
      'myApp' => {
        prerequisite => [ 'core.o', 'library.o' ],
recipe => make_compile_emulator( \$ticks )
      }
    }
  );

  is( $make->run( target => 'myApp' ), undef );
  ok( exists $make->filesystem->{'myApp'}{mtime} );
  ok( $make->filesystem->{'myApp'}{mtime} > 17 );
}

# }}}

# {{{ Multilevel make, run default
{
  #
  # myApp : core.o gui.o api.o
  #	ln core.o gui.o api.o -lm -o myApp
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  # # Add another layer here to properly test recursion
  # library.o : gui.o api.o
  #	ln gui.o api.o -o library.o
  #
  # gui.o : gui.c gui.h
  #	cc gui.c -o gui.o
  #
  # api.o : api.c api.h
  #	cc api.c -o api.o
  #
  my $ticks = 17;
  my $make = JGoff::App::Make::FakeFilesystem->new(
    ticks => 17,
    filesystem => {
      'core.c' => { mtime => 1 },
      'core.h' => { mtime => 4 },
      'gui.c' => { mtime => 7 },
      'gui.h' => { mtime => 10 },
      'api.c' => { mtime => 13 },
      'api.h' => { mtime => 16 } 
    },
    default => 'myApp',
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
      },
      'gui.o' => {
        prerequisite => [ 'gui.c', 'gui.h' ],
      },
      'api.o' => {
        prerequisite => [ 'api.c', 'api.h' ],
      },
      'library.o' => {
        prerequisite => [ 'gui.o', 'api.o' ],
      },
      'myApp' => {
        prerequisite => [ 'core.o', 'library.o' ],
recipe => make_compile_emulator( \$ticks )
      }
    }
  );

  is( $make->run( target => 'hello.o' ), undef );
  ok( exists $make->filesystem->{'myApp'}{mtime} );
  ok( $make->filesystem->{'myApp'}{mtime} > 17 );
}
# }}}

=cut
