use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "MLDBM",
              DISTNAME => "MLDBM",
              VERSION_FROM => 'MLDBM.pm',
              SKIP => [qw(static dynamic)],
              'linkext' => {LINKTYPE => '' },
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
             );
