use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'JGoff::App::Make',
    AUTHOR              => q{Jeff Goff <jgoff@cpan.org>},
    VERSION_FROM        => 'lib/JGoff/App/Make.pm',
    ABSTRACT_FROM       => 'lib/JGoff/App/Make.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Config' => 0,
        'File::Copy' => 0,
        'File::Spec' => 0,
        'Getopt::Long' => 0,
        'Moose' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'JGoff-App-Make-*' },
);
