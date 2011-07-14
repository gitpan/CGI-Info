use Test::More;

eval 'use Test::Portability::Files';
plan skip_all => "Test::Portability::Files required for testing filenames portability" if $@;
options(all_tests => 1);
run_tests();
