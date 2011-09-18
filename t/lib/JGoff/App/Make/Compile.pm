package JGoff::App::Make::Compile;
use Moose;
extends 'JGoff::App::Make';

# {{{ _mtime( $target )

sub _mtime {
  my $self = shift;
  my ( $target ) = @_;

  return unless -e $target;
  return -M $target;
}

# }}}

# {{{ _run_recipe( $target )

sub _run_recipe {
  my $self = shift;
  my ( $target ) = @_;

  return $self->target->{$target}->{recipe}->(
    $target,
    $self->target->{$target}->{prerequisite}
  );
}

# }}}

1;
