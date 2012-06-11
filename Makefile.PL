use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CGI::Info',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/CGI/Info.pm',
    ABSTRACT_FROM       => 'lib/CGI/Info.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.82,	# Needs new_ok
	'Test::NoWarnings' => 0,
	'URI::Heuristic' => 0,
	'Sys::Hostname' => 0,
	'File::Spec' => 0,
	'Cwd' => 0,
	'Carp' => 0,
	'Socket' => 0,
	'List::Member' => 0,
	'Test::Kwalitee' => 0,
	'HTTP::BrowserDetect' => 1.42,	# Include baidu etc.
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CGI-Info-*' },
);
