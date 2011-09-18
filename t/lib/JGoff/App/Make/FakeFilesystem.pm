package JGoff::App::Make::FakeFilesystem;
use Moose;
extends 'JGoff::App::Make::Suffix';

has filesystem => ( is => 'rw', isa => 'HashRef', default => sub { { } } );

# {{{ _mtime( $target )

sub _mtime {
  my $self = shift;
  my ( $target ) = @_;

  return unless $self->filesystem->{$target};
  return $self->filesystem->{$target}->{mtime};
}

# }}}

# {{{ _run_recipe( $target )

sub _run_recipe {
  my $self = shift;
  my ( $target ) = @_;

  return $self->target->{$target}->{recipe}->(
    $target,
    $self->target->{$target}->{prerequisite},
    $self->filesystem
  );
}

# }}}

1;
