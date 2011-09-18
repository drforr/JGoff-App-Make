package JGoff::App::Make;

use Getopt::Long;
use Carp 'croak';
use Moose;

has default => ( is => 'rw', isa => 'Str' );
has target => ( is => 'rw', isa => 'HashRef', default => sub { { } } );

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

# {{{ _prerequisite( $target )

sub _prerequisite {
  my $self = shift;
  my ( $target ) = @_;

  return unless $self->target->{$target}->{prerequisite};
  return @{ $self->target->{$target}->{prerequisite} };
}

# }}}

# {{{ _unsatisfied( $target )

sub _unsatisfied {
  my $self = shift;
  my ( $target ) = @_;

  my @prerequisite = $self->_prerequisite( $target );

  if ( my $mtime_target = $self->_mtime( $target ) ) {
    return grep { $self->_mtime( $_ ) > $mtime_target } @prerequisite;
  }
  return @prerequisite;
}

# }}}

# {{{ _run( $target )

sub _run {
  my $self = shift;
  my ( $target ) = @_;

  my @update = $self->_unsatisfied( $target );
  for my $prerequisite ( @update ) {
    next unless $self->target->{$prerequisite};
    if ( my $rv = $self->_run( $prerequisite ) ) {
      return $rv;
    }
  }
  return $self->_run_recipe( $target ) if @update;
  return;
}

# }}}

# {{{ _default( target => $target )`

sub _default {
  my $self = shift;
  my %args = @_;

  return $args{target} if exists $args{target};
  return $self->default if $self->default;
  return ( keys %{ $self->target } )[0] if keys %{$self->target} == 1;

  croak "*** No target or default specified and >1 target present";
}

# }}}

# {{{ run( target => $target )

sub run {
  my $self = shift;
  my %args = @_;

  return $self->_run( $self->_default( %args ) );
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
