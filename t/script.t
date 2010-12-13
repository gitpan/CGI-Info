#!perl -Tw

use strict;
use warnings;
use Test::More tests => 9;

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
	ok(!defined($i->script_name()));
	ok(!defined($i->script_path()));

	$ENV{'DOCUMENT_ROOT'} = '/var/www/bandsman';
	$ENV{'SCRIPT_NAME'} = '/cgi-bin/script.pl';
	$ENV{'SCRIPT_FILENAME'} = '/var/www/bandsman/cgi-bin/script.pl';
	$i = CGI::Info->new();
	ok(defined $i);
	ok($i->isa('CGI::Info'));
	ok($i->script_name() eq 'script.pl');
	ok($i->script_path() eq '/var/www/bandsman/cgi-bin/script.pl');

}
