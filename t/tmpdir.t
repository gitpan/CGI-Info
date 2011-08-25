#!perl -Tw

use strict;
use warnings;
use Test::More tests => 16;

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
	$i = new_ok('CGI::Info');
	$dir = $i->tmpdir();
	ok(-w $dir);
	ok(-d $dir);
}
