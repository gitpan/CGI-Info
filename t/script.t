#!perl -Tw

use strict;
use warnings;
use Test::More tests => 9;
use File::Spec;

BEGIN {
	use_ok('CGI::Info');
}

PATHS: {
        delete $ENV{'SCRIPT_NAME'};
	delete $ENV{'DOCUMENT_ROOT'};
        delete $ENV{'SCRIPT_FILENAME'};

	my $i = CGI::Info->new();
	ok(defined $i);
	ok($i->isa('CGI::Info'));
	ok($i->script_name() eq 'script.t');
	ok(File::Spec->file_name_is_absolute($i->script_path()));

	$ENV{'DOCUMENT_ROOT'} = '/var/www/bandsman';
	$ENV{'SCRIPT_NAME'} = '/cgi-bin/foo.pl';
	$ENV{'SCRIPT_FILENAME'} = '/var/www/bandsman/cgi-bin/foo.pl';
	$i = CGI::Info->new();
	ok(defined $i);
	ok($i->isa('CGI::Info'));
	ok($i->script_name() eq 'foo.pl');
	ok($i->script_path() eq '/var/www/bandsman/cgi-bin/foo.pl');

}
