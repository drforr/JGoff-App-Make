package JGoff::App::Make::FakeFilesystem;
use Moose;
extends 'JGoff::App::Make';

has filesystem => ( is => 'rw', isa => 'HashRef' );

sub _mtime {
  my $self = shift;
  my ( $file ) = @_;
  return unless $self->filesystem->{$file};
  return unless $self->filesystem->{$file}->{mtime};
  return $self->filesystem->{$file}->{mtime};
}

=pod

has ticks => ( is => 'rw', isa => 'Int' );
has filesystem => ( is => 'rw', isa => 'HashRef' );

# {{{ advance_time

sub advance_time {
  my $self = shift;
  my ( $amount ) = @_;
  $amount ||= 3;
  $self->ticks( $self->ticks + $amount );
}

# }}}

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
    $self->advance_time;
    return $self->filesystem->{$file}{error_code} if
           $self->filesystem->{$file}{error_code};
  }
  $self->filesystem->{$target}{mtime} = $self->ticks;
  return;
}

# }}}

=cut

1;
