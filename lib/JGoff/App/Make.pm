package JGoff::App::Make;

use Carp 'croak';
use Moose;

has target => ( is => 'rw', isa => 'HashRef' );

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

    my $maker = JGoff::App::Make->new(
      target => {
        'helloWorld' => {
          prerequisite => [ 'helloWorld.c', 'helloWorld.h' ]
        }
      }
    );
    $maker->run( target => 'helloWorld' );
    ...

=head1 METHODS

=head2 new( target => { ... } )

The main 'new'

=cut

=head2 run( [target => 'foo'] )

=cut

# {{{ _targets_to_update( $target_name )

sub _targets_to_update {
  my $self = shift;
  my ( $target_name ) = @_;
  my $target = $self->target->{$target_name};

  my @update = @{ $target->{prerequisite} };
  if ( my $mtime_target = $self->_mtime( $target_name ) ) {
    return grep { $self->_mtime( $_ ) > $mtime_target } @update;
  }
  return @update;
}

# }}}`

# {{{ _run( $target_name )

sub _run {
  my $self = shift;
  my ( $target_name ) = @_;
  my $target = $self->target->{$target_name};

  return $target->($self) if
    ref( $target ) eq 'CODE';

  my @update = $self->_targets_to_update( $target_name );

  return unless @update;

  for my $prerequisite ( @update ) {
    next unless $self->target->{$prerequisite};
    if ( my $rv = $self->_run( $prerequisite ) ) {
      return $rv;
    }
  }
  return $target->{recipe}->($self);
}

# }}}

# {{{ run( target => $target )

sub run {
  my $self = shift;
  my %args = @_;

  croak "*** No target specified!\n" unless $args{target};

  croak "*** No targets to build!" unless
    $self->target and keys %{ $self->target };

  croak "*** Cannot make specified target '$args{target}!" unless
    $self->target->{ $args{target} };

  return $self->_run( $args{target} );
}

# }}}

=head1 AUTHOR

Jeff Goff, C<< <jgoff at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jgoff-app-make at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JGoff-App-Make>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

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
