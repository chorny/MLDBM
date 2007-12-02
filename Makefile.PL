use 5.004;
use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "MLDBM",
              DISTNAME => "MLDBM",
              VERSION_FROM => 'lib/MLDBM.pm',
	      PREREQ_PM => {
	       'Data::Dumper' => '2.08',
	       'Test::More' => 0,
	      },
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
              ($ExtUtils::MakeMaker::VERSION gt '6.30'?
               ('LICENSE' => 'perl', ) : ()),
             );
