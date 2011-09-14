#!perl -T

use strict;
use warnings;

use Test::More tests => 29;

BEGIN {
  use_ok( 'JGoff::App::Make' ) || print "Bail out!\n";
}

my $DEBUG = 0;

# {{{ make_compile_emulator

sub make_compile_emulator {
  my ( $filesystem, $tick_ref ) = @_;
  return sub {
    my $target = shift;
    my $prerequisite = shift;
    for my $file ( @$prerequisite ) {
      $$tick_ref += int(rand(2)) + 1;
      return $filesystem->{$file}{error_code} if
             $filesystem->{$file}{error_code};
    }
    $filesystem->{$target}{mtime} = $$tick_ref;
    return;
  }
}

# }}}

# {{{ Nothing to do!
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %filesystem = (
    'core.c' => { mtime => 1 },
    'core.h' => { mtime => 2 },
    'core.o' => { mtime => 3 }
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator(
          \%filesystem, \$ticks
        )
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( $filesystem{'core.o'}{mtime} );
  is( $filesystem{'core.o'}{mtime}, 3 );
}
# }}}

# {{{ Nothing to do, default action
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %filesystem = (
    'core.c' => { mtime => 1 },
    'core.h' => { mtime => 2 },
    'core.o' => { mtime => 3 }
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator(
          \%filesystem, \$ticks
        )
      },
    }
  );
  is( $make->run, undef );
  ok( $filesystem{'core.o'}{mtime} );
  is( $filesystem{'core.o'}{mtime}, 3 );
}
# }}}

# {{{ "create" core.o
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %filesystem = (
    'core.c' => { mtime => 1 },
    'core.h' => { mtime => 2 }
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator(
          \%filesystem, \$ticks
        )
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $filesystem{'core.o'} );
  ok( $filesystem{'core.o'}{mtime} and $filesystem{'core.o'}{mtime} > 2 );
}
# }}}

# {{{ bring core.o "up-to-date", older than all source files
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %filesystem = (
    'core.c' => { mtime => 4 },
    'core.h' => { mtime => 6 },
    'core.o' => { mtime => 1 } # core.h is more "up-to-date", rebuild core.o
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator(
          \%filesystem, \$ticks
        )
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $filesystem{'core.o'} );
  ok( $filesystem{'core.o'}{mtime} and $filesystem{'core.o'}{mtime} > 6 );
}
# }}}

# {{{ bring core.o "up-to-date", older than one source file
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %filesystem = (
    'core.c' => { mtime => 4 },
    'core.h' => { mtime => 6 },
    'core.o' => { mtime => 5 } # core.h is more "up-to-date", rebuild core.o
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator(
          \%filesystem, \$ticks
        )
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $filesystem{'core.o'} );
  ok( $filesystem{'core.o'}{mtime} and $filesystem{'core.o'}{mtime} > 6 );
}
# }}}

# {{{ "broken" one-step compile
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %filesystem = (
    'core.c' => { mtime => 1, error_code => 1 },
    'core.h' => { mtime => 2 }
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },
    }
  );
  is( $make->run( target => 'core.o' ), 1 );
  ok( !exists $filesystem{'core.o'} );
  ok( $ticks > 17 );
}
# }}}

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

  my %filesystem = (
    'core.c' => { mtime => 1 },
    'core.h' => { mtime => 4 },
    'gui.c' => { mtime => 7 },
    'gui.h' => { mtime => 10 },
    'api.c' => { mtime => 13 },
    'api.h' => { mtime => 16 } 
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },
      'gui.o' => {
        prerequisite => [ 'gui.c', 'gui.h' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },
      'api.o' => {
        prerequisite => [ 'api.c', 'api.h' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },
      'library.o' => {
        prerequisite => [ 'gui.o', 'api.o' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },
      'myApp' => {
        prerequisite => [ 'core.o', 'library.o' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      }
    }
  );

  is( $make->run( target => 'myApp' ), undef );
  ok( exists $filesystem{'myApp'}{mtime} );
  ok( $filesystem{'myApp'}{mtime} > 17 );
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

  my %filesystem = (
    'core.c' => { mtime => 1 },
    'core.h' => { mtime => 4 },
    'gui.c' => { mtime => 7 },
    'gui.h' => { mtime => 10 },
    'api.c' => { mtime => 13 },
    'api.h' => { mtime => 16 } 
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    default => 'myApp',
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },
      'gui.o' => {
        prerequisite => [ 'gui.c', 'gui.h' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },
      'api.o' => {
        prerequisite => [ 'api.c', 'api.h' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },
      'library.o' => {
        prerequisite => [ 'gui.o', 'api.o' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },
      'myApp' => {
        prerequisite => [ 'core.o', 'library.o' ],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      }
    }
  );

  is( $make->run, undef );
  ok( exists $filesystem{'myApp'}{mtime} );
  ok( $filesystem{'myApp'}{mtime} > 17 );
}
# }}}

# {{{ GNU make sample file - make clean
{
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

  my %filesystem = (
    'main.o' => { mtime => 1 },
    'kbd.o' => { mtime => 3 },
    'command.o' => { mtime => 12 },
    'display.o' => { mtime => 13 },
    'insert.o' => { mtime => 14 },
    'search.o' => { mtime => 17 },
    'files.o' => { mtime => 20 },
    'utils.o' => { mtime => 23 }
  );

  my $ticks = 25;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    target => {

# {{{ edit
      edit => {
        prerequisite => [qw(
          main.o kbd.o command.o display.o insert.o search.o files.o utils.o
        )],
        recipe => make_compile_emulator(
          \%filesystem, [qw(
            main.o kbd.o command.o display.o insert.o search.o files.o utils.o
          )],
          \$ticks
        )
      },

# }}}

# {{{ main.o
      'main.o' => {
        prerequisite => [qw( main.c defs.h )],
        recipe => make_compile_emulator(
          \%filesystem, [ 'main.c', 'defs.h' ], \$ticks
        )
      },

# }}}

# {{{ kbd.o
      'kbd.o' => {
        prerequisite => [qw( kbd.c defs.h command.h )],
        recipe => make_compile_emulator(
          \%filesystem, [ 'kbd.c', 'defs.h', 'command.h' ], \$ticks
        )
      },

# }}}

# {{{ command.o
      'command.o' => {
        prerequisite => [qw( command.c defs.h command.h )],
        recipe => make_compile_emulator(
          \%filesystem, [ 'command.c', 'defs.h', 'command.h' ],
          \$ticks
        )
    },

# }}}

# {{{ display.o
      'display.o' => {
        prerequisite => [qw( display.c defs.h buffer.h )],
        recipe => make_compile_emulator(
          \%filesystem, [ 'display.c', 'defs.h', 'buffer.h' ],
          \$ticks
        )
      },

# }}}

# {{{ insert.o
      'insert.o' => {
        prerequisite => [qw( insert.c defs.h buffer.h )],
        recipe => make_compile_emulator(
          \%filesystem, [ 'insert.c', 'defs.h', 'buffer.h' ],
          \$ticks
        )
      },

# }}}

# {{{ search.o
      'search.o' => {
        prerequisite => [qw( search.c defs.h buffer.h )],
        recipe => make_compile_emulator(
          \%filesystem, [ 'search.c', 'defs.h', 'buffer.h' ],
          \$ticks
        )
      },

# }}}

# {{{ files.o
      'files.o' => {
        prerequisite => [qw( files.c defs.h buffer.h command.h )],
        recipe => make_compile_emulator(
          \%filesystem, [qw( files.c defs.h buffer.h command.h )],
          \$ticks
        )
      },

# }}}

# {{{ utils.o
      'utils.o' => {
        prerequisite => [qw( utils.c defs.h )],
        recipe => make_compile_emulator(
          \%filesystem, [ 'utils.c', 'defs.h', ],
          \$ticks
        )
      },

# }}}

# {{{ clean

    'clean' => {
      recipe => sub {
        for my $file ( qw( edit main.o kbd.o command.o display.o 
                           insert.o search.o files.o utils.o ) ) {
          $ticks+= rand(2) + 1;
          delete $filesystem{$file};
        }
        $ticks+= rand(2) + 1;
        return;
      }
    },

# }}}

    }
  );

  is( $make->run( target => 'clean' ), undef );
  ok( !exists $filesystem{'edit'} );
#  ok( !exists $mtime{'edit'} );
}
# }}}

# {{{ GNU make sample file - make clean with @objects reference
{
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

  my %filesystem = (
    'main.o' => { mtime => 1 },
    'kbd.o' => { mtime => 3 },
    'command.o' => { mtime => 12 },
    'display.o' => { mtime => 13 },
    'insert.o' => { mtime => 14 },
    'search.o' => { mtime => 17 },
    'files.o' => { mtime => 20 },
    'utils.o' => { mtime => 23 }
  );

  my @objects = qw(
    main.o kbd.o command.o display.o insert.o search.o files.o utils.o
  );
  my $ticks = 25;
  my $make = JGoff::App::Make->new(
    filesystem => \%filesystem,
    target => {

      edit => {
        prerequisite => [@objects],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },

      'main.o' => {
        prerequisite => [qw( main.c defs.h )],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },

      'kbd.o' => {
        prerequisite => [qw( kbd.c defs.h command.h )],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },

      'command.o' => {
        prerequisite => [qw( command.c defs.h command.h )],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
    },

      'display.o' => {
        prerequisite => [qw( display.c defs.h buffer.h )],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },

      'insert.o' => {
        prerequisite => [qw( insert.c defs.h buffer.h )],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },

      'search.o' => {
        prerequisite => [qw( search.c defs.h buffer.h )],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },

      'files.o' => {
        prerequisite => [qw( files.c defs.h buffer.h command.h )],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },

      'utils.o' => {
        prerequisite => [qw( utils.c defs.h )],
        recipe => make_compile_emulator( \%filesystem, \$ticks )
      },

      'clean' => {
        recipe => sub {
          my ( $target, $objects ) = @_;
          for my $file ( @$objects ) {
            $ticks+= rand(2) + 1;
            delete $filesystem{$file};
          }
          $ticks+= rand(2) + 1;
          return;
        }
      },
    }
  );

  is( $make->run( target => 'clean' ), undef );
  ok( !exists $filesystem{'edit'} );
}
# }}}
