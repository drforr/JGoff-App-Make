#!perl -T

use strict;
use warnings;

use Test::More tests => 37;

BEGIN {
  use_ok( 'JGoff::App::Make' ) || print "Bail out!\n";
}

# {{{ make_compile_emulator

sub make_compile_emulator {
  my $tick_ref = shift;
  return sub {
    my ( $target, $prerequisite, $filesystem ) = @_;
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
  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'core.c' => { mtime => 1 },
      'core.h' => { mtime => 2 },
      'core.o' => { mtime => 3 }
    },
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( $make->filesystem->{'core.o'}{mtime} );
  is( $make->filesystem->{'core.o'}{mtime}, 3 );
}
# }}}

# {{{ Nothing to do, default action
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'core.c' => { mtime => 1 },
      'core.h' => { mtime => 2 },
      'core.o' => { mtime => 3 }
    },
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
    }
  );
  is( $make->run, undef );
  ok( $make->filesystem->{'core.o'}{mtime} );
  is( $make->filesystem->{'core.o'}{mtime}, 3 );
}
# }}}

# {{{ "create" core.o
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'core.c' => { mtime => 1 },
      'core.h' => { mtime => 2 }
    },
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $make->filesystem->{'core.o'} );
  ok( $make->filesystem->{'core.o'}{mtime} and
      $make->filesystem->{'core.o'}{mtime} > 2 );
}
# }}}

# {{{ "create" core.o with default suffix handling rule
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'core.c' => { mtime => 1 },
      'core.h' => { mtime => 2 }
    },
    default => 'core.o',
    target => {
      'core.o' => { prerequisite => [ 'core.h' ] },
    }
  );
  for ( @{ $make->suffix } ) {
    $_->{recipe} = make_compile_emulator( \$ticks );
  }
  is( $make->run, undef );
  is_deeply(
    $make->target->{'core.o'}->{prerequisite},
    [ 'core.c', 'core.h' ]
  );
  ok( exists $make->filesystem->{'core.o'} );
  ok( $make->filesystem->{'core.o'}{mtime} and
      $make->filesystem->{'core.o'}{mtime} > 2 );
  ok( $ticks > 17 );
}
# }}}

# {{{ bring core.o "up-to-date", no suffix, older than all source files
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'core.c' => { mtime => 4 },
      'core.h' => { mtime => 6 },
      'core.o' => { mtime => 1 } # core.h is more "up-to-date", rebuild core.o
    },
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $make->filesystem->{'core.o'} );
  ok( $make->filesystem->{'core.o'}{mtime} and
      $make->filesystem->{'core.o'}{mtime} > 6 );
}
# }}}

# {{{ bring core.o "up-to-date", older than all source files
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'core.c' => { mtime => 4 },
      'core.h' => { mtime => 6 },
      'core.o' => { mtime => 1 } # core.h is more "up-to-date", rebuild core.o
    },
    target => {
      'core.o' => {
        prerequisite => [ 'core.h' ]
      },
    }
  );
  for ( @{ $make->suffix } ) {
    $_->{recipe} = make_compile_emulator( \$ticks );
  }
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $make->filesystem->{'core.o'} );
  ok( $make->filesystem->{'core.o'}{mtime} and
      $make->filesystem->{'core.o'}{mtime} > 6 );
}
# }}}

# {{{ bring core.o "up-to-date", older than one source file
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'core.c' => { mtime => 4 },
      'core.h' => { mtime => 6 },
      'core.o' => { mtime => 5 } # core.h is more "up-to-date", rebuild core.o
    },
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $make->filesystem->{'core.o'} );
  ok( $make->filesystem->{'core.o'}{mtime} and
      $make->filesystem->{'core.o'}{mtime} > 6 );
}
# }}}

# {{{ "broken" one-step compile
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'core.c' => { mtime => 1, error_code => 1 },
      'core.h' => { mtime => 2 }
    },
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
    }
  );
  is( $make->run( target => 'core.o' ), 1 );
  ok( !exists $make->filesystem->{'core.o'} );
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
  my $ticks = 17;
  my $make = JGoff::App::Make->new(
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
        recipe => make_compile_emulator( \$ticks )
      },
      'gui.o' => {
        prerequisite => [ 'gui.c', 'gui.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
      'api.o' => {
        prerequisite => [ 'api.c', 'api.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
      'library.o' => {
        prerequisite => [ 'gui.o', 'api.o' ],
        recipe => make_compile_emulator( \$ticks )
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
  my $make = JGoff::App::Make->new(
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
        recipe => make_compile_emulator( \$ticks )
      },
      'gui.o' => {
        prerequisite => [ 'gui.c', 'gui.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
      'api.o' => {
        prerequisite => [ 'api.c', 'api.h' ],
        recipe => make_compile_emulator( \$ticks )
      },
      'library.o' => {
        prerequisite => [ 'gui.o', 'api.o' ],
        recipe => make_compile_emulator( \$ticks )
      },
      'myApp' => {
        prerequisite => [ 'core.o', 'library.o' ],
        recipe => make_compile_emulator( \$ticks )
      }
    }
  );

  is( $make->run, undef );
  ok( exists $make->filesystem->{'myApp'}{mtime} );
  ok( $make->filesystem->{'myApp'}{mtime} > 17 );
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
  #
  my $ticks = 25;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'main.o' => { mtime => 1 },
      'kbd.o' => { mtime => 3 },
      'command.o' => { mtime => 12 },
      'display.o' => { mtime => 13 },
      'insert.o' => { mtime => 14 },
      'search.o' => { mtime => 17 },
      'files.o' => { mtime => 20 },
      'utils.o' => { mtime => 23 }
    },
    target => {

      edit => {
        prerequisite => [qw(
          main.o kbd.o command.o display.o insert.o search.o files.o utils.o
        )],
        recipe => make_compile_emulator( \$ticks )
      },
      'main.o' => {
        prerequisite => [qw( main.c defs.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'kbd.o' => {
        prerequisite => [qw( kbd.c defs.h command.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'command.o' => {
        prerequisite => [qw( command.c defs.h command.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'display.o' => {
        prerequisite => [qw( display.c defs.h buffer.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'insert.o' => {
        prerequisite => [qw( insert.c defs.h buffer.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'search.o' => {
        prerequisite => [qw( search.c defs.h buffer.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'files.o' => {
        prerequisite => [qw( files.c defs.h buffer.h command.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'utils.o' => {
        prerequisite => [qw( utils.c defs.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'clean' => {
        recipe => sub {
          my $target = shift;
          my $prerequisite = shift;
          my $filesystem = shift;
          for my $file ( qw( edit main.o kbd.o command.o display.o 
                             insert.o search.o files.o utils.o ) ) {
            $ticks+= rand(2) + 1;
            delete $filesystem->{$file};
          }
          $ticks+= rand(2) + 1;
          return;
        }
      }
    }
  );

  is( $make->run( target => 'clean' ), undef );
  ok( !exists $make->filesystem->{'edit'} );
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
  #
  my @objects = qw(
    main.o kbd.o command.o display.o insert.o search.o files.o utils.o
  );
  my $ticks = 25;
  my $make = JGoff::App::Make->new(
    filesystem => {
      'main.o' => { mtime => 1 },
      'kbd.o' => { mtime => 3 },
      'command.o' => { mtime => 12 },
      'display.o' => { mtime => 13 },
      'insert.o' => { mtime => 14 },
      'search.o' => { mtime => 17 },
      'files.o' => { mtime => 20 },
      'utils.o' => { mtime => 23 }
    },
    target => {
      edit => {
        prerequisite => [@objects],
        recipe => make_compile_emulator( \$ticks )
      },
      'main.o' => {
        prerequisite => [qw( main.c defs.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'kbd.o' => {
        prerequisite => [qw( kbd.c defs.h command.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'command.o' => {
        prerequisite => [qw( command.c defs.h command.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'display.o' => {
        prerequisite => [qw( display.c defs.h buffer.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'insert.o' => {
        prerequisite => [qw( insert.c defs.h buffer.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'search.o' => {
        prerequisite => [qw( search.c defs.h buffer.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'files.o' => {
        prerequisite => [qw( files.c defs.h buffer.h command.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'utils.o' => {
        prerequisite => [qw( utils.c defs.h )],
        recipe => make_compile_emulator( \$ticks )
      },
      'clean' => {
        recipe => sub {
          my ( $target, $prerequisite, $filesystem ) = @_;
          for my $file ( @$prerequisite ) {
            $ticks+= rand(2) + 1;
            delete $filesystem->{$file};
          }
          $ticks+= rand(2) + 1;
          return;
        }
      }
    }
  );

  is( $make->run( target => 'clean' ), undef );
  ok( !exists $make->filesystem->{'edit'} );
}
# }}}
