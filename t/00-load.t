#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SQL::QueryParser' ) || print "Bail out!\n";
}

diag( "Testing SQL::QueryParser $SQL::QueryParser::VERSION, Perl $], $^X" );
