package JGoff::App::Make;

use Getopt::Long;
use Carp 'croak';
use Moose;

has target => ( is => 'rw', isa => 'HashRef', default => sub { { } } );
has mtime => ( is => 'rw', isa => 'HashRef', default => sub { { } } );

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

    my $foo = JGoff::App::Make->new( target => { ... } );
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 run

=cut

# {{{ _dependency( target => $target )

sub _dependency {
  my $self = shift;
  my %args = @_;
  croak "*** Must specify argument 'target'" unless
    exists $args{target};
  croak "*** No target '$args{target}' found!" unless
    defined $self->_target( target => $args{target} );

  return @{ $self->target->{$args{target}}->{dependency} };
}

# }}}

# {{{ _target( target => $target )

sub _target {
  my $self = shift;
  my %args = @_;
  croak "*** Must specify argument 'target'" unless
    exists $args{target};
  croak "*** No target '$args{target}' found!" unless
    defined $self->target->{$args{target}};
  
  return $self->target->{$args{target}};
}

# }}}

# {{{ _mtime( target => $target )

sub _mtime {
  my $self = shift;
  my %args = @_;
  croak "*** Must specify argument 'target'" unless
    exists $args{target};
  croak "*** No target '$args{target}' found!" unless
    defined $self->_target( target => $args{target} );
  
  return $self->mtime->{$args{target}};
}

# }}}

# {{{ _update( target => $target )

sub _update {
  my $self = shift;
  my %args = @_;
  croak "*** Must specify argument 'target'" unless
    exists $args{target};
  croak "*** No target '$args{target}' found!" unless
    defined $self->_target( target => $args{target} );
  my $target = $args{target};

  return $self->target->{$target}->{update}->();
}

# }}}

# {{{ _satisfy( target => $target )

sub _satisfy {
  my $self = shift;
  my %args = @_;
  croak "*** Must specify argument 'target'" unless
    exists $args{target};
  croak "*** No target '$args{target}' found!" unless
    defined $self->_target( target => $args{target} );
  my $target = $args{target};

  my @unsatisfied;
  if ( $self->_mtime( target => $target ) ) {
    for my $dependency ( $self->_dependency( %args ) ) {
      next if $self->mtime( target => $target ) >
              $self->mtime( target => $dependency );
      push @unsatisfied, $dependency;
    }
  }
  else {
    @unsatisfied = $self->_dependency( %args );
  }

  for my $dependency ( @unsatisfied ) {
    if ( my $return = $self->_update( target => $dependency ) ) {
      warn "*** Error $return\n";
      return $return;
    }
  }

  return $self->_update( target => $target );
}

# }}}

# {{{ run( target => $target )

sub run {
  my $self = shift;
  my %args = @_;
  croak "*** Must specify argument 'target'" unless
    exists $args{target};
  croak "*** No target '$args{target}' found!" unless
    defined $self->_target( target => $args{target} );

  return $self->_satisfy( %args );
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
