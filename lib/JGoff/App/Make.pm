package JGoff::App::Make;

use Getopt::Long;
use Carp 'croak';
use Moose;

has default => ( is => 'rw', isa => 'Str' );
has target => ( is => 'rw', isa => 'HashRef', default => sub { { } } );
has mtime => ( is => 'rw', isa => 'HashRef', default => sub { { } } );
has filesystem => ( is => 'rw', isa => 'HashRef', default => sub { { } } );

=head1 NAME

JGoff::App::Make - Core library for Make utilities.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use JGoff::App::Make;

    my $foo = JGoff::App::Make->new( target => { ... } );
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 run

=cut

# {{{ _check( target => $target )

sub _check {
  my $self = shift;
  my %args = @_;
  croak "*** Must specify argument 'target'" unless
    exists $args{target};
  croak "*** No target '$args{target}' found!" unless
    defined $self->target->{$args{target}};
}

# }}}

# {{{ _phony( target => $target )

sub _phony {
  my $self = shift;
  $self->_check( @_ );
  my %args = @_;

  croak "*** Attempting to check whether a nonexistent target '$args{target}' is phony!" unless
    defined $self->target->{$args{target}};
  return 1 unless defined $self->target->{$args{target}}{prerequisite};
  return 1 unless @{ $self->target->{$args{target}}{prerequisite} };
  return;
}

# }}}

# {{{ _unsatisfied( target => $target )

sub _unsatisfied {
  my $self = shift;
  $self->_check( @_ );
  my %args = @_;

  return unless $self->target->{$args{target}};

  my $mtime_target = $self->mtime->{$args{target}};
  my @prerequisite = @{ $self->target->{$args{target}}->{prerequisite} };

  return @prerequisite unless
    $mtime_target;

  return grep { $self->mtime->{$_} > $mtime_target } @prerequisite;
}

# }}}

# {{{ _run( target => $target )

sub _run {
  my $self = shift;
  $self->_check( @_ );
  my %args = @_;
  my $target = $args{target};

  return $self->target->{$target}->{recipe}->() if
    $self->_phony( %args );

  my @update = $self->_unsatisfied( %args );
  for my $prerequisite ( @update ) {
    if ( $self->target->{$prerequisite} ) {
      if ( my $rv = $self->_run( target => $prerequisite ) ) {
        return $rv;
      }
    }
  }

  return $self->target->{$target}->{recipe}->(
    $target, $self->target->{$target}{prerequisite}
   ) if
    @update;
  return;
}

# }}}

# {{{ run( target => $target )

sub run {
  my $self = shift;
  my %args = @_;
  unless ( exists $args{target} ) {
    if ( $self->default ) {
      $args{target} = $self->default;
    }
    elsif ( keys %{$self->target} == 1 ) {
      $args{target} = ( keys %{ $self->target } )[0];
    }
    else {
      croak "*** No target or default specified and >1 target present";
    }
  }

  unless ( keys $self->mtime ) {
    $self->mtime( {
      map { $_ => $self->filesystem->{$_}{'mtime'} } keys %{ $self->filesystem }
    } )
  }

  return $self->_run( %args );
}

# }}}

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

1; # End of JGoff::App::Make
