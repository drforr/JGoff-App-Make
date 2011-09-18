package JGoff::App::Make::Suffix;

use Getopt::Long;
use Carp 'croak';
use Moose;

extends 'JGoff::App::Make';

#
# .out, .a, .ln, .o, .c, .cc, .C, .cpp, .p, .f, .F, .m, .r, .y, .l, .ym, .lm,
# .s, .S, .mod, .sym, .def, .h, .info, .dvi, .tex, .texinfo, .texi, .txinfo,
# .w, .ch .web, .sh, .elc, .el.
#

my @suffix = (
  [ '.c' => '.o', sub {
    '$(CC) $(CPPFLAGS) $(CFLAGS) -c'
  } ],
  [ [ '.cc', '.cpp', '.C' ] => '.o', sub {
    '$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c'
  } ],
  [ '.p' => '.o', sub {
    '$(PC) $(PFLAGS) -c'
  } ],
  [ '.f' => '.o', sub {
    '$(FC) $(FFLAGS) -c'
  } ],
  [ '.F' => '.o', sub {
    '$(FC) $(FFLAGS) $(CPPFLAGS) -c'
  } ],
  [ '.r' => 'o', sub {
    '$(FC) $(FFLAGS) $(RFLAGS) -c'
  } ],
  [ '.F' => '.f', sub {
    '$(FC) $(CPPFLAGS) $(FFLAGS) -F'
  } ],
  [ '.r' => '.f', sub {
    '$(FC) $(FFLAGS) $(RFLAGS) -F'
  } ],
  [ '.def' => '.sym', sub {
    '$(M2C) $(M2FLAGS) $(DEFFLAGS)'
  } ],
  [ '.mod' => '.o', sub {
    '$(M2C) $(M2FLAGS) $(MODFLAGS)'
  } ],
  [ '.s' => '.o', sub {
    '$(AS) $(ASFLAGS)'
  } ],
  [ '.S' => '.s', sub {
    '$(CPP) $(CPPFLAGS)'
  } ],
  [ '.o' => '', sub { # Build final binary
    '$(CC) $(LDFLAGS) n.o $(LOADLIBES) $(LDLIBS)'
  } ],
  [ '.y' => '.c', sub {
    '$(YACC) $(YFLAGS)'
  } ],
  [ '.l' => '.r', sub { # Yes, this is ambiguous.
    '$(LEX) $(LFLAGS)'
  } ],
  [ '.c' => '.ln', sub {
    '$(LINT) $(LINTFLAGS) $(CPPFLAGS) -i'
  } ],
  [ '.tex' => '.dvi', sub {
    '$(TEX)'
  } ],
  [ '.web' => '.tex', sub {
    '$(WEAVE)'
  } ],
  [ '.w' => '.dvi', sub {
    '$(CWEAVE)'
  } ],
  [ '.w' => '.c', sub {
    '$(CTANGLE)'
  } ],
  [ [ '.texinfo', '.texi', '.txinfo' ] => '.dvi', sub {
    '$(TEXI2DVI) $(TEXI2DVI_FLAGS)'
  } ],
  [ [ '.texinfo', '.texi', '.txinfo' ] => '.info', sub {
    '$(MAKEINFO) $(MAKEINFO_FLAGS)'
  } ],
  [ [ ',v', 'RCS/,v' ] => '', sub {
    '$(CO) $(COFLAGS)'
  } ],
  [ [ ',n', 'SCCS/.n' ] => '', sub {
    '$(GET) $(GFLAGS)'
  } ],
);

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
  #
  # Link n from *.o # XXX
  #
  { name => '.c',
    completion_list => [qw( .y )] # yacc
  },
  { name => '.c',
    completion_list => [qw( .l )] # lex
  },
  { name => '.r',
    completion_list => [qw( .l )] # lex
  },
  { name => '.ln',
    completion_list => [qw( .c )] # lint
  },
  { name => '.dvi',
    completion_list => [qw( .tex )] # TeX
  },
  { name => '.tex',
    completion_list => [qw( .web .w .ch )] # web # XXX not sure about .ch
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

# {{{ _deduce( $target )

sub _deduce {
  my $self = shift;
  my ( $target ) = @_;

  return if $self->_recipe( $target );
  return unless $self->_prerequisite( $target );

  my ( $name, $extension ) = $target =~ m{ (.+) ([.][^.]+) $ }x;
  for my $suffix ( @{ $self->suffix } ) {
    next unless $suffix->{name} eq $extension;
    for my $completion ( @{ $suffix->{completion_list} } ) {
      my $file = "${name}${completion}";
      next unless defined $self->filesystem->{$file};
      $self->target->{$target}->{prerequisite} = [
        $file,
        $self->_prerequisite( $target )
      ];
      $self->target->{$target}->{recipe} = $suffix->{recipe};
    }
  }
}

# }}}

before _run => sub {
  my $self = shift;
  my ( $target ) = @_;

  $self->_deduce( $target );
};

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
