#!perl -T

use Test::More tests => 17;

BEGIN {
  use_ok( 'JGoff::App::Make' ) || print "Bail out!\n";
}

# {{{ Nothing to do!
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %mtime = (
    'core.c' => 1, 
    'core.h' => 2, 
    'core.o' => 3, # This should do *nothing* and return undef
  );
  my %can_compile = (
    'core.c' => undef,
    'core.h' => undef,
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    mtime => \%mtime,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => sub {
          $ticks+= rand(2) + 1;
          return $can_compile{'core.c'} if $can_compile{'core.c'};
          $ticks+= rand(2) + 1;
          return $can_compile{'core.h'} if $can_compile{'core.h'};
          $ticks+= rand(2) + 1;
          $mtime{'core.o'} = $ticks; # XXX Feed back the mtime changes
          return;
        }
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $mtime{'core.o'} );
  is( $mtime{'core.o'}, 3 );
}
# }}}

# {{{ "create" core.o
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %mtime = (
    'core.c' => 1, 
    'core.h' => 2, 
  );
  my %can_compile = (
    'core.c' => undef,
    'core.h' => undef,
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    mtime => \%mtime,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => sub {
          $ticks+= rand(2) + 1;
          return $can_compile{'core.c'} if $can_compile{'core.c'};
          $ticks+= rand(2) + 1;
          return $can_compile{'core.h'} if $can_compile{'core.h'};
          $ticks+= rand(2) + 1;
          $mtime{'core.o'} = $ticks; # XXX Feed back the mtime changes
          return;
        }
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $mtime{'core.o'} );
  ok( $mtime{'core.o'} and $mtime{'core.o'} > 2 );
}
# }}}

# {{{ bring core.o "up-to-date", older than all source files
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %mtime = (
    'core.c' => 4, 
    'core.h' => 6, 
    'core.o' => 1, # core.h is more "up-to-date", rebuild core.o
  );
  my %can_compile = (
    'core.c' => undef,
    'core.h' => undef,
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    mtime => \%mtime,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => sub {
          $ticks+= rand(2) + 1;
          return $can_compile{'core.c'} if $can_compile{'core.c'};
          $ticks+= rand(2) + 1;
          return $can_compile{'core.h'} if $can_compile{'core.h'};
          $ticks+= rand(2) + 1;
          $mtime{'core.o'} = $ticks; # XXX Feed back the mtime changes
          return;
        }
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $mtime{'core.o'} );
  ok( $mtime{'core.o'} and $mtime{'core.o'} > 6 ); # Touched
}
# }}}

# {{{ bring core.o "up-to-date", older than one source file
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %mtime = (
    'core.c' => 4, 
    'core.h' => 6, 
    'core.o' => 5, # core.h is more "up-to-date", rebuild core.o
  );
  my %can_compile = (
    'core.c' => undef,
    'core.h' => undef,
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    mtime => \%mtime,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => sub {
          $ticks+= rand(2) + 1;
          return $can_compile{'core.c'} if $can_compile{'core.c'};
          $ticks+= rand(2) + 1;
          return $can_compile{'core.h'} if $can_compile{'core.h'};
          $ticks+= rand(2) + 1;
          $mtime{'core.o'} = $ticks; # XXX Feed back the mtime changes
          return;
        }
      },
    }
  );
  is( $make->run( target => 'core.o' ), undef );
  ok( exists $mtime{'core.o'} );
  ok( $mtime{'core.o'} and $mtime{'core.o'} > 3 ); # Touched
}
# }}}

# {{{ "broken" one-step compile
{
  #
  # core.o : core.c core.h
  #	cc core.c -o core.o
  #
  my %mtime = (
    'core.c' => 1, 
    'core.h' => 2, 
  );
  my %can_compile = (
    'core.c' => 1, # cc -o core.o core.c # "returns" 1
    'core.h' => undef,
  );

  my $ticks = 17;
  my $make = JGoff::App::Make->new(
    mtime => \%mtime,
    target => {
      'core.o' => {
        prerequisite => [ 'core.c', 'core.h' ],
        recipe => sub {
          $ticks+= rand(2) + 1;
          return $can_compile{'core.c'} if $can_compile{'core.c'};
          $ticks+= rand(2) + 1;
          return $can_compile{'core.h'} if $can_compile{'core.h'};
          $ticks+= rand(2) + 1;
          $mtime{'core.o'} = $ticks; # XXX Feed back the mtime changes
          return;
        }
      },
    }
  );
  is( $make->run( target => 'core.o' ), 1 );
  ok( !exists $mtime{'core.o'} );
  ok( $ticks > 17 );
}
# }}}

# {{{ Multilevel make
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
#  'library.o' => undef, # XXX In case library.o "already exists"
#  'myApp' => undef # XXX In case myApp "already exists"
);

my %can_compile = (
  'core.c' => undef,
  'core.h' => undef,
  'api.c' => undef,
  'api.h' => undef,
  'gui.c' => undef,
  'gui.h' => undef,
  'library.o' => undef,
  'myApp' => undef, # Can link thing
);

my $ticks = 17;
my $make = JGoff::App::Make->new(
  mtime => \%mtime,
  target => {

# {{{ core.o

    'core.o' => {
      prerequisite => [ 'core.c', 'core.h' ],
      recipe => sub {
        $ticks+= rand(2) + 1;
        return $can_compile{'core.c'} if $can_compile{'core.c'};
        $ticks+= rand(2) + 1;
        return $can_compile{'core.h'} if $can_compile{'core.h'};
        $ticks+= rand(2) + 1;
        $mtime{'core.o'} = $ticks; # XXX Feed back the mtime changes
        return;
      }
    },

# }}}

# {{{ gui.o

    'gui.o' => {
      prerequisite => [ 'gui.c', 'gui.h' ],
      recipe => sub {
        $ticks+= rand(2) + 1;
        return $can_compile{'gui.c'} if $can_compile{'gui.c'};
        $ticks+= rand(2) + 1;
        return $can_compile{'gui.h'} if $can_compile{'gui.h'};
        $ticks+= rand(2) + 1;
        $mtime{'gui.o'} = $ticks; # XXX Feed back the mtime changes
        return;
      }
    },

# }}}

# {{{ api.o

    'api.o' => {
      prerequisite => [ 'api.c', 'api.h' ],
      recipe => sub {
        $ticks+= rand(2) + 1;
        return $can_compile{'api.c'} if $can_compile{'api.c'};
        $ticks+= rand(2) + 1;
        return $can_compile{'api.h'} if $can_compile{'api.h'};
        $ticks+= rand(2) + 1;
        $mtime{'api.o'} = $ticks; # XXX Feed back the mtime changes
        return;
      }
    },

# }}}

# {{{ library.o

    'library.o' => {
      prerequisite => [ 'gui.o', 'api.o' ],
      recipe => sub {
        $ticks+= rand(2) + 1;
        return $can_compile{'gui.o'} if $can_compile{'gui.o'};
        $ticks+= rand(2) + 1;
        return $can_compile{'api.o'} if $can_compile{'api.o'};
        $ticks+= rand(2) + 1;
        $mtime{'library.o'} = $ticks; # XXX Feed back the mtime changes
        return;
      }
    },

# }}}

# {{{ myApp

    'myApp' => {
      prerequisite => [ 'core.o', 'library.o' ],
      recipe => sub {
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

is( $make->run( target => 'myApp' ), undef );

# }}}

=pod

#
# The sample makefile from the GNU manual
# 

edit : main.o kbd.o command.o display.o \
       insert.o search.o files.o utils.o
        cc -o edit main.o kbd.o command.o display.o \
                   insert.o search.o files.o utils.o

main.o : main.c defs.h
        cc -c main.c
kbd.o : kbd.c defs.h command.h
        cc -c kbd.c
command.o : command.c defs.h command.h
        cc -c command.c
display.o : display.c defs.h buffer.h
        cc -c display.c
insert.o : insert.c defs.h buffer.h
        cc -c insert.c
search.o : search.c defs.h buffer.h
        cc -c search.c
files.o : files.c defs.h buffer.h command.h
        cc -c files.c
utils.o : utils.c defs.h
        cc -c utils.c
clean :
        rm edit main.o kbd.o command.o display.o \
           insert.o search.o files.o utils.o

=cut
