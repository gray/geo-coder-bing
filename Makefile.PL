use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Geo::Coder::Bing',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Geo/Coder/Bing.pm',
    ABSTRACT_FROM => 'lib/Geo/Coder/Bing.pm',
    PREREQ_PM     => {
        'JSON'       => 0,
        'Test::More' => 0,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
        META_MERGE => {
            resources => {
                repository => 'http://github.com/gray/geo-coder-bing',
            }
        }
    ) : () ),
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Geo-Coder-Bing-*' },
);
