#!perl -Tw

use strict;
use warnings;
use Test::More tests => 24;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

PATHS: {
	delete $ENV{'C_DOCUMENT_ROOT'};
	delete $ENV{'DOCUMENT_ROOT'};

	my $i = new_ok('CGI::Info');
	my $dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	$ENV{'DOCUMENT_ROOT'} = '/non-existant-path';
	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	$ENV{'C_DOCUMENT_ROOT'} = '/non-existant-path';
	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir(default => '/non-existant-path');
	ok($dir eq '/non-existant-path');

	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir({ default => '/non-existant-path' });
	ok($dir eq '/non-existant-path');

	$ENV{'DOCUMENT_ROOT'} = $ENV{'HOME'};
	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	delete $ENV{'DOCUMENT_ROOT'};

	$ENV{'C_DOCUMENT_ROOT'} = '/non-existant-path';
	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);

	$ENV{'C_DOCUMENT_ROOT'} = $ENV{'HOME'};
	$dir = $i->tmpdir();
	ok($dir !~ '/non-existant-path');
	ok(-w $dir);
	ok(-d $dir);
}
