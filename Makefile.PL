use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "MLDBM",
              DISTNAME => "MLDBM",
              VERSION => '1.21',
              SKIP => [qw(static dynamic)],
              'linkext' => {LINKTYPE => '' },
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
             );
