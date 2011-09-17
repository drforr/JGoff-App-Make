package JGoff::App::Make;

use Getopt::Long;
use Carp 'croak';
use Moose;

has default => ( is => 'rw', isa => 'Str' );
has target => ( is => 'rw', isa => 'HashRef', default => sub { { } } );
has filesystem => ( is => 'rw', isa => 'HashRef', default => sub { { } } );
has suffix => ( is => 'rw', isa => 'ArrayRef', default => sub { [
  { name => '.o',
    completion_list => [qw( .c )] # C
  },
  { name => '.o',
    completion_list => [qw( .cc .cpp .C )] # C++
  },
  { name => '.o',
    completion_list => [qw( .p )] # Pascal
  },
  { name => '.o',
    completion_list => [qw( .r .F .f )] # FORTRAM
  },
  { name => '.f',
    completion_list => [qw( .r .F )] # RATFOR
  },
  { name => '.sym',
    completion_list => [qw( .def )] # Modula-2
  },
  { name => '.o',
    completion_list => [qw( .S )] # assembly
  },
  { name => '.S',
    completion_list => [qw( .s )] # assembly
  },
] } );

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
  my $target = $args{target};
  croak "*** No target '$target' found!" unless
    defined $self->target->{$target};
}

# }}}

# {{{ _phony( target => $target )

sub _phony {
  my $self = shift;
  $self->_check( @_ );
  my %args = @_;
  my $target = $args{target};

  croak "*** Attempting to check whether a nonexistent target '$target' is phony!"
    unless defined $self->target->{$target};
  return 1 unless defined $self->target->{$target}{prerequisite};
  return 1 unless @{ $self->target->{$target}{prerequisite} };
  return;
}

# }}}

# {{{ _unsatisfied( target => $target )

sub _unsatisfied {
  my $self = shift;
  $self->_check( @_ );
  my %args = @_;
  my $target = $args{target};

  return unless $self->target->{$target};
  my @prerequisite = @{ $self->target->{$target}->{prerequisite} };

  if ( $self->filesystem->{$target} and
       $self->filesystem->{$target}->{mtime} ) {
    my $mtime_target = $self->filesystem->{$target}->{mtime};
    return
      grep { $self->filesystem->{$_}->{mtime} > $mtime_target } @prerequisite;
  }
  else {
    return @prerequisite;
  }
}

# }}}

# {{{ _deduce( target => $target )

sub _deduce {
  my $self = shift;
  $self->_check( @_ );
  my %args = @_;
  my $target = $args{target};

  return if $self->target->{$target}->{recipe};
  return unless $self->target->{$target}->{prerequisite};
  return unless @{ $self->target->{$target}->{prerequisite} };

  my ( $name, $extension ) = $target =~ m{ (.+) ([.][^.]+) $ }x;
  for my $suffix ( @{ $self->suffix } ) {
    next unless $suffix->{name} eq $extension;
    for my $completion ( @{ $suffix->{completion_list} } ) {
      my $file = "${name}${completion}";
      next unless defined $self->filesystem->{$file};
      $self->target->{$target}->{prerequisite} = [
        $file,
        @{ $self->target->{$target}->{prerequisite} }
      ];
      $self->target->{$target}->{recipe} = $suffix->{recipe};
    }
  }
}

# }}}

# {{{ _run( target => $target )

sub _run {
  my $self = shift;
  $self->_check( @_ );
  my %args = @_;
  my $target = $args{target};

  $self->_deduce( %args );

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
    $target,
    $self->target->{$target}{prerequisite},
    $self->filesystem
  ) if @update;
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

  my $has_mtime;
  for(keys %{$self->filesystem} ) {
    next unless $self->filesystem->{$_}{mtime};
    $has_mtime = 1;
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
