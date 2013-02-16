use strict;
use Module::Build;
#created by eumm-migrate.pl

my $build = Module::Build->new(
  'build_requires' => {
    'Test::More' => 0
  },
  'module_name' => 'MLDBM',
  'requires' => {
    'perl' => '5.005',
    'Data::Dumper' => '2.08'
  },
  'meta_merge' => {
    'resources' => {
      'repository' => 'git://github.com/chorny/MLDBM.git'
    }
  },
  'license' => 'perl',
  'dist_version_from' => 'lib/MLDBM.pm',
  'dist_author' => [
    'Gurusamy Sarathy <gsar@umich.edu>',
    'Alexandr Ciornii (alexchorny@gmail.com)',
  ],
);

$build->create_build_script();
