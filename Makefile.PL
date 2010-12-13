use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'BarnOwl::Module::ClassFilters',
    AUTHOR              => q{Kevin Riggle <kevinr@free-dissociation.com>},
    VERSION_FROM        => 'lib/BarnOwl/Module/ClassFilters.pm',
    ABSTRACT_FROM       => 'lib/BarnOwl/Module/ClassFilters.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'BarnOwl-Module-ClassFilters-*' },
);
