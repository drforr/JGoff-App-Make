package JGoff::App::Make::FakeFilesystem;
use Moose;
extends 'JGoff::App::Make';

has ticks => ( is => 'rw', isa => 'Int', default => time );
has filesystem => ( is => 'rw', isa => 'HashRef' );

sub _mtime {
  my $self = shift;
  my ( $file ) = @_;
  return unless $self->filesystem->{$file};
  return unless $self->filesystem->{$file}->{mtime};
  return $self->filesystem->{$file}->{mtime};
}

sub _advance_ticks {
  my $self = shift;
  my ( $ticks ) = @_;
  $ticks ||= int( rand( 3 ) ) + 1;
  $self->ticks( $self->ticks + $ticks );
}

sub _touch {
  my $self = shift;
  my ( $file ) = @_;
  $self->_advance_ticks;
  $self->filesystem->{$file} = { mtime => $self->ticks };
}

1;
