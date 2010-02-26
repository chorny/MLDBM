use strict;
use Module::Build;
#created by eumm-migrate.pl

my $build = Module::Build->new(
  'build_requires' => {
    'Test::More' => 0
  },
  'module_name' => 'MLDBM',
  'requires' => {
    'perl' => '5.004',
    'Data::Dumper' => '2.08'
  },
  'meta_merge' => {
    'resources' => {
      'repository' => 'git://github.com/chorny/MLDBM.git'
    }
  },
  'license' => 'perl',
  'dist_version_from' => 'lib/MLDBM.pm'
);

$build->create_build_script();
