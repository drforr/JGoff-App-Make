package JGoff::App::Make::FakeFilesystem;
use Moose;
extends 'JGoff::App::Make::Suffix';

has ticks => ( is => 'rw', isa => 'Int' );
has filesystem => ( is => 'rw', isa => 'HashRef' );

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

  for my $file ( @{ $self->target->{$target}->{prerequisite} } ) {
    $self->ticks( $self->ticks + int( rand( 2 ) ) + 1 );
    return $self->filesystem->{$file}{error_code} if
           $self->filesystem->{$file}{error_code};
  }
  $self->filesystem->{$target}{mtime} = $self->ticks;
  return;
}

# }}}

1;
