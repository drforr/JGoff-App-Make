#!perl -T

use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
  use lib 't/lib';
  use_ok( 'JGoff::App::Make' ) || print "Bail out!\n";
}

#
# Failing tests on the core library, as long as it's not asked to
# actually do anything the core shouldn't break.
#

eval { JGoff::App::Make->new()->run };
like( $@, qr{ No \s+ target \s+ specified }x );

eval { JGoff::App::Make->new( target => { } )->run };
like( $@, qr{ No \s+ target \s+ specified }x );

eval { JGoff::App::Make->new( target => { warble => 1 } )->run };
like( $@, qr{ No \s+ target \s+ specified }x );

eval { JGoff::App::Make->new( target => { warble => 1, fubar => 1 } )->run };
like( $@, qr{ No \s+ target \s+ specified }x );

eval { JGoff::App::Make->new()->run( target => 'bar' ) };
like( $@, qr{ No \s+ targets \s+ to \s+ build }x );

eval { JGoff::App::Make->new( target => { } )->run( target => 'bar' ) };
like( $@, qr{ No \s+ targets \s+ to \s+ build }x );
eval {
  JGoff::App::Make->new( 
    target => { warble => 1, fubar => 1 } 
  )->run( target => 'bar' )
};
like( $@, qr{ Cannot \s+ make \s+ specified \s+ target }x );

