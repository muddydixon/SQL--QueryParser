#!perl -T

use Test::More "no_plan";
use Data::Dumper;

use SQL::QueryParser;
# use SQL::QueryParser::Tokenizer;
# use SQL::QueryParser::Calculator;


# test tokenizer
# my $tokenizer = new SQL::QueryParser::Tokenizer;
# $tokenizer->split("SELECT *, a.id FROM a, b");

# $tokenizer->split("SELECT *, a.id FROM \\'a, b");
# diag Dumper $tokenizer;

# $tokenizer->split("SELECT *, a.id /* comment in this area */c FROM (SELECT * FROM d.e.a, b /* comment in this area */ ) a");
# diag Dumper $tokenizer;

my $parser = new SQL::QueryParser();
$parser->parse("SELECT *, a.id FROM a");

diag Dumper $parser;

ok 1;
