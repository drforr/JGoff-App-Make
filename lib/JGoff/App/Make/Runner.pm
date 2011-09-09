package JGoff::App::Make::Runner;

use Getopt::Long;
use Moose;
use JGoff::App::Make;

my $BASEEXT = 'foo';
my $BOOTSTRAP = 'foo';
my $DFSEP = '/';
my $EXE_EXT = 'foo';
my $FIRST_MAKEFILE = 'foo';
my $INST_ARCHAUTODIR = 'foo';
my $INST_ARCHLIB = 'foo';
my $INST_LIBDIR = 'foo';
my $LIB_EXT = 'foo';
my $MAKE_APERL_FILE = 'foo';
my $MYEXTLIB = 'foo';
my $OBJ_EXT = 'foo';
my $PERM_DIR = 'foo';

# {{{ attributes

has option => ( is => 'rw', isa => 'HashRef', default => sub { { } } );
has target => ( is => 'rw', isa => 'ArrayRef', default => sub { [ ] } );
has environment => ( is => 'rw', isa => 'HashRef', default => sub { {
  PREFIX => '/usr'
} } );

sub _mkpath {
  my $self = shift;
}
sub _chmod {
  my $self = shift;
}
sub _touch {
  my $self = shift;
}

=head1 NAME

JGoff::App::Make - The great new JGoff::App::Make!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use JGoff::App::Make;

    my $foo = JGoff::App::Make->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

=head2 run

=cut

sub run {
  my $self = shift;
  my $res = GetOptions(
    $self->option,
    'help',
    'quiet',
    'verbose'
  );
  for my $element ( @ARGV ) {
    if ( $element =~ /=/ ) {
      my ( $k, $v ) = split /=/, $element, 2;
      $self->environment->{$k} = $v;
    }
    else {
      push @{ $self->target }, $element;
    }
  }
#  my @module_name = split /(?:-|\::)/, $self->module
#  $self->config->{version_from} = File::Spec->catfile( 'lib', @module_name );
#  $self->config->{abstract_from} = File::Spec->catfile( 'lib', @module_name );

#die defined $Config{'usethreads'} ? 'yes' : 'no';

  my $maker = JGoff::App::Make->new;
  $maker->target( {
    all => { dependency => [qw( pure_all manifypods )] },
    pure_all => { dependency => [qw( config pm_to_blib subdirs linkext )] },
    subdirs => { dependency => [ $MYEXTLIB ] },
    config => { dependency => [ $FIRST_MAKEFILE, 'blibdirs' ] },
    help => { action => sub { `perldoc JGoff::App::Make` } },
    blibdirs => { dependency => [ "INSERT STUFF HERE" ] },
    'blibdirs.ts' => { dependency => [qw( blibdirs )] },

    # There are a buttload of these.
    "${INST_LIBDIR}${DFSEP}.exists" => {
      dependency => [ 'Make' ], # This file
      action => sub {
        my $self = shift;
        $self->mkdir( $INST_LIBDIR );
        $self->chmod( $PERM_DIR, $INST_LIBDIR );
        $self->touch( "${INST_LIBDIR}${DFSEP}.exists" );
      }
    },
    "${INST_ARCHLIB}${DFSEP}.exists" => {
      dependency => [ 'Make' ], # This file
      action => sub {
        my $self = shift;
        $self->mkdir( $INST_ARCHLIB );
        $self->chmod( $PERM_DIR, $INST_ARCHLIB );
        $self->touch( "${INST_ARCHLIB}${DFSEP}.exists" ); # "foo/.exists"
      }
    },

# {{{ clean => ['clean_subdirs']
    clean => {
      dependency => [ 'clean_subdirs' ],
      action => sub {
        my @unlink_files = (
          'blibdirs.ts',
          'core',
          'mon.out',
          'perl',
          'perl.exe',
          'perlmain.c',
          'pm_to_blib',
          'pm_to_blib.ts',
          'so_locations',
          'tmon.out',
          'MYMETA.yml',

          $BOOTSTRAP,

    	  "${BASEEXT}.bso",
	  "${BASEEXT}.def",
	  "${BASEEXT}.exp",
	  "${BASEEXT}.x",
	  "lib${BASEEXT}.def",

	  "${INST_ARCHAUTODIR}/extralibs.all",
	  "${INST_ARCHAUTODIR}/extralibs.ld",

          $MAKE_APERL_FILE,

	  "perl${EXE_EXT}",
        );
        my @unlink_patterns = (
          'core.[0-9]',
          'core.[0-9][0-9]',
          'core.[0-9][0-9][0-9]',
          'core.[0-9][0-9][0-9][0-9]',
          'core.[0-9][0-9][0-9][0-9][0-9]',
          'core..*perl..*..?', # core.*perl.*.?

	  '.*${LIB_EXT}',
	  '.*${OBJ_EXT}',
	  '.*perl.core',
        );
        my @unlink_dirs = (
          'blib',

          'Compile-JVM-.*'
        );

#	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)
      },
    },
# }}}

  } );
  for my $target ( $self->target ) { # XXX wrong wrong wrong, but hey.
    $maker->run( target => $target );
  }
}

=head1 AUTHOR

Jeff Goff, C<< <jgoff at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jgoff-app-make at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JGoff-App-Make>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JGoff::App::Make


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JGoff-App-Make>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JGoff-App-Make>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JGoff-App-Make>

=item * Search CPAN

L<http://search.cpan.org/dist/JGoff-App-Make/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Jeff Goff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of JGoff::App::Make::Runner
