use lib "./lib";
require MLDBM;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "MLDBM",
              DISTNAME => "MLDBM",
              VERSION => $MLDBM::VERSION,
              SKIP => [qw(static dynamic)],
              'linkext' => {LINKTYPE => '' },
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
             );
