use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SQL::QueryParser',
    AUTHOR              => q{muddydixon <muddydixon@gmail.com>},
    VERSION_FROM        => 'lib/SQL/QueryParser.pm',
    ABSTRACT_FROM       => 'lib/SQL/QueryParser.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SQL-QueryParser-*' },
);
