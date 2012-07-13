#!perl -wT

use strict;
use warnings;
use Test::More tests => 42;
use Test::NoWarnings;
use File::Spec;

BEGIN {
	use_ok('CGI::Info');
}

PARAMS: {
	$ENV{'GATEWAY_INTERFACE'} = 'CGI/1.1';
	$ENV{'REQUEST_METHOD'} = 'GET';
	$ENV{'QUERY_STRING'} = 'foo=bar';

	my $i = new_ok('CGI::Info');
	my %p = %{$i->params()};
	ok($p{foo} eq 'bar');
	ok(!defined($p{fred}));
	ok($i->as_string() eq 'foo=bar');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';

	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok($p{foo} eq 'bar');
	ok($p{fred} eq 'wilma');
	ok($i->as_string() eq 'foo=bar;fred=wilma');

	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma&foo=baz';

	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok($p{foo} eq 'bar,baz');
	ok($p{fred} eq 'wilma');
	ok($i->as_string() eq 'foo=bar,baz;fred=wilma');

	# Reading twice should yield the same result
	%p = %{$i->params()};
	ok($p{foo} eq 'bar,baz');

	$ENV{'QUERY_STRING'} = 'foo=&fred=wilma';
	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok(!defined($p{foo}));
	ok($p{fred} eq 'wilma');
	ok($i->as_string() eq 'fred=wilma');

	$ENV{'QUERY_STRING'} = 'foo=&fred=wilma&foo=bar';
	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok($p{foo} eq 'bar');
	ok($p{fred} eq 'wilma');
	ok($i->as_string() eq 'foo=bar;fred=wilma');

	$ENV{'QUERY_STRING'} = 'foo%41=%20bar';
	$i = new_ok('CGI::Info');
	my $p = $i->params();
	ok($p->{'fooA'} eq 'bar');
	ok($i->as_string() eq 'fooA=bar');

	delete $ENV{'QUERY_STRING'};
	$i = new_ok('CGI::Info');
	ok(!$i->params());

	$ENV{'REQUEST_METHOD'} = 'HEAD';
	$ENV{'QUERY_STRING'} = 'foo=bar&fred=wilma';
	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok($p{fred} eq 'wilma');

	$ENV{'REQUEST_METHOD'} = 'FOO';
	$i = new_ok('CGI::Info');

	local $SIG{__WARN__} = sub { die $_[0] };
	eval { $i->params() };
	ok($@ =~ /Use POST, GET or HEAD/);

	delete $ENV{'QUERY_STRING'};
	$ENV{'REQUEST_METHOD'} = 'POST';
	my $input = 'foo=bar';
	$ENV{'CONTENT_LENGTH'} = length($input);

	open (my $fin, '<', \$input);
	local *STDIN = $fin;

	$i = new_ok('CGI::Info');
	%p = %{$i->params()};
	ok($p{foo} eq 'bar');
	ok(!defined($p{fred}));
	ok($i->as_string() eq 'foo=bar');
	close $fin;

	# TODO: find and use a free filename, otherwise /tmp/hello.txt
	# will be overwritten if it exists
	$ENV{'CONTENT_TYPE'} = 'Multipart/form-data; boundary=-----xyz';
	$input = <<'EOF';
-------xyz
Content-Disposition: form-data; name="country"

44
-------xyz
Content-Disposition: form-data; name="datafile"; filename="hello.txt"
Content-Type: text/plain

Hello, World

-------xyz--
EOF
	$ENV{'CONTENT_LENGTH'} = length($input);

	open ($fin, '<', \$input);
	local *STDIN = $fin;

	$i = new_ok('CGI::Info' => [
		upload_dir => File::Spec->tmpdir()
	]);
	%p = %{$i->params()};
	ok(defined($p{country}));
	ok($p{country} eq '44');
	ok($p{datafile} =~ /^hello.txt_.+/);
	my $filename = '/tmp/' . $p{datafile};
	ok(-e $filename);
	ok(-r $filename);
	unlink($filename);
	close $fin;
}
