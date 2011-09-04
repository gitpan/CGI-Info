#!perl -Tw

use strict;
use warnings;
use Test::More tests => 10;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

PATHS: {
        delete $ENV{'HTTP_X_WAP_PROFILE'};
	delete $ENV{'HTTP_USER_AGENT'};

	my $i = new_ok('CGI::Info');
	ok($i->is_mobile() == 0);

	$ENV{'HTTP_X_WAP_PROFILE'} = 'http://www.blackberry.net/go/mobile/profiles/uaprof/9000_80211g/5.0.0.rdf';;
	$i = new_ok('CGI::Info');
	ok($i->is_mobile() == 1);

        delete $ENV{'HTTP_X_WAP_PROFILE'};
	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (iPhone; U)';
	$i = new_ok('CGI::Info');
	ok($i->is_mobile() == 1);

	$ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.18) Gecko/20110614 Firefox/3.6.18';
	$i = new_ok('CGI::Info');
	ok($i->is_mobile() == 0);
}
