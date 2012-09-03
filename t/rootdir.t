#!perl -Tw

use strict;
use warnings;
use Test::More tests => 20;
use File::Spec;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

ROOTDIR: {
	delete $ENV{'C_DOCUMENT_ROOT'};
	delete $ENV{'DOCUMENT_ROOT'};

	my $i = new_ok('CGI::Info');
	my $dir = $i->rootdir();
	ok(-r $dir);
	ok(-d $dir);
	ok($dir =~ /\/t$/);

	ok(CGI::Info->rootdir() eq $dir);
	ok(CGI::Info::rootdir() eq $dir);

	$ENV{'DOCUMENT_ROOT'} = File::Spec->catdir(File::Spec->tmpdir(), 'xyzzy');
	$i = new_ok('CGI::Info');
	$dir = $i->rootdir();
	ok(-r $dir);
	ok(-d $dir);

	delete $ENV{'DOCUMENT_ROOT'};
	$ENV{'C_DOCUMENT_ROOT'} = File::Spec->catdir(File::Spec->tmpdir(), 'xyzzy');
	$i = new_ok('CGI::Info');
	$dir = $i->rootdir();
	ok(-r $dir);
	ok(-d $dir);

	delete $ENV{'C_DOCUMENT_ROOT'};
	$ENV{'DOCUMENT_ROOT'} = $ENV{'HOME'};
	$dir = $i->rootdir();
	ok($dir eq $ENV{'HOME'});
	ok(-r $dir);
	ok(-d $dir);

	$ENV{'DOCUMENT_ROOT'} = File::Spec->catdir($ENV{'HOME'}, 'htdocs');
	$dir = $i->rootdir();
	ok($dir eq File::Spec->catdir($ENV{'HOME'}, 'htdocs'));
	ok(-r $dir);
	ok(-d $dir);
}
