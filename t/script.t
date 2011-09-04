#!perl -Tw

use strict;
use warnings;
use Test::More tests => 21;
use File::Spec;
use Cwd;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

PATHS: {
        delete $ENV{'SCRIPT_NAME'};
	delete $ENV{'DOCUMENT_ROOT'};
        delete $ENV{'SCRIPT_FILENAME'};

	my $i = new_ok('CGI::Info');
	ok($i->script_name() eq 'script.t');
	ok(File::Spec->file_name_is_absolute($i->script_path()));
	ok($i->script_path() =~ /.+script\.t$/);

	# Test full path given as the name of the script
	$ENV{'SCRIPT_NAME'} = $i->script_path();
	$i = new_ok('CGI::Info');
	ok(File::Spec->file_name_is_absolute($i->script_path()));
	ok($i->script_path() =~ /.+script\.t$/);
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Absolute path test needs to be done on Windows';
			ok($i->script_name() eq 'script.t');
		}
	} else {
		ok($i->script_name() eq 'script.t');
	}

	$ENV{'DOCUMENT_ROOT'} = '/var/www/bandsman';
	$ENV{'SCRIPT_NAME'} = '/cgi-bin/foo.pl';
	$ENV{'SCRIPT_FILENAME'} = '/var/www/bandsman/cgi-bin/foo.pl';
	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'foo.pl');
	ok($i->script_path() eq '/var/www/bandsman/cgi-bin/foo.pl');

	# The name is cached - check reading it twice returns the same value
	ok($i->script_name() eq 'foo.pl');
	ok($i->script_path() eq '/var/www/bandsman/cgi-bin/foo.pl');

	$ENV{'DOCUMENT_ROOT'} = '/path/to';
	$ENV{'SCRIPT_NAME'} = '/cgi-bin/bar.pl';
        delete $ENV{'SCRIPT_FILENAME'};

	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	if($^O eq 'MSWin32') {
		TODO: {
			local $TODO = 'Absolute path test needs to be done on Windows';
			ok($i->script_path() eq '/path/to/cgi-bin/bar.pl');
		}
	} else {
		ok($i->script_path() eq '/path/to/cgi-bin/bar.pl');
	}

        delete $ENV{'DOCUMENT_ROOT'};
	$ENV{'SCRIPT_NAME'} = '/cgi-bin/bar.pl';
        delete $ENV{'SCRIPT_FILENAME'};

	$i = new_ok('CGI::Info');
	ok($i->script_name() eq 'bar.pl');
	ok($i->script_path() eq File::Spec->catfile(Cwd::abs_path(), 'bar.pl'));
}
