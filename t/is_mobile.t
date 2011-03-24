#!perl -Tw

use strict;
use warnings;
use Test::More tests => 3;
use File::Spec;

BEGIN {
	use_ok('CGI::Info');
}

PATHS: {
        delete $ENV{'HTTP_X_WAP_PROFILE'};
	delete $ENV{'HTTP_USER_AGENT'};

	my $i = new_ok('CGI::Info');
	ok($i->is_mobile() == 0);
}
