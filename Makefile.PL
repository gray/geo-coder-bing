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
        'JSON'           => 2.0,
        'LWP::UserAgent' => 0,
        'Test::More'     => 0,
        'URI'            => 1.36,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
        META_MERGE => {
            resources  => {
                repository => 'http://github.com/gray/geo-coder-bing',
            },
            recommends => {
                'JSON::XS' => 2.0,
            },
        }
    ) : () ),
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Geo-Coder-Bing-*' },
);
