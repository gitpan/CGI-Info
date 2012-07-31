#!perl -wT

use strict;
use warnings;
use Test::More tests => 6;
use Test::NoWarnings;

BEGIN {
	use_ok('CGI::Info');
}

XML: {
	my $xml = '<foo>bar</foo>';

	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'POST';
	$ENV{'CONTENT_TYPE'} = 'text/xml; charset=utf-8';
	$ENV{'CONTENT_LENGTH'} = length($xml);

	my @expect = ('xml');

	open (my $fin, '<', \$xml);
	local *STDIN = $fin;

	my $i = new_ok('CGI::Info');
	my %p = %{$i->params({expect => \@expect})};
	ok(exists($p{xml}));
	ok($p{xml} eq $xml);
	ok($i->as_string() eq "xml=$xml");
}
