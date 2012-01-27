package CGI::Info;

use warnings;
use strict;
use Carp;
use File::Spec;
use Socket;
use List::Member;

=head1 NAME

CGI::Info - Information about the CGI environment

=head1 VERSION

Version 0.18

=cut

our $VERSION = '0.18';

=head1 SYNOPSIS

All too often Perl programs have information such as the script's name
hard-coded into their source.
Generally speaking, hard-coding is bad style since it can make programs
difficult to read and it reduces readability and portability.
CGI::Info attempts to remove that.

Furthermore, to aid script debugging, CGI::Info attempts to do sensible
things when you're not running the program in a CGI environment.

    use CGI::Info;
    my $info = CGI::Info->new();
    # ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::Info object.

=cut

sub new {
	my ($proto, %args) = @_;

	my $class = ref($proto) || $proto;

	my $self = {
		_script_name => undef,
		_script_path => undef,
		_site => undef,
		_cgi_site => undef,
		_domain => undef,
		_paramref => undef,
		_expect => $args{expect} ? $args{expect} : undef,
	};
	bless $self, $class;

	return $self;
}

=head2 script_name

Returns the name of the CGI script.
This is useful for POSTing, thus avoiding putting hardcoded paths into forms

	use CGI::Info;

	my $info = CGI::Info->new();
	my $script_name = $info->script_name();
	# ...
	print "<form method=\"POST\" action=$script_name name=\"my_form\">\n";

=cut

sub script_name {
	my $self = shift;

	unless($self->{_script_name}) {
		$self->_find_paths();
	}
	return $self->{_script_name};
}

sub _find_paths {
	my $self = shift;
	my @fields;

	if($ENV{'SCRIPT_NAME'}) {
		@fields = split(/\//, $ENV{'SCRIPT_NAME'});
	} else {
		@fields = split(/\//, $0);
	}
	$self->{_script_name} = $fields[$#fields];

	if($ENV{'SCRIPT_FILENAME'}) {
		$self->{_script_path} = $ENV{'SCRIPT_FILENAME'};
	} elsif($ENV{'DOCUMENT_ROOT'} && $ENV{'SCRIPT_NAME'}) {
		my $script_name = $ENV{'SCRIPT_NAME'};
		if(substr($script_name, 0, 1) eq '/') {
			# It's usually the case, e.g. /cgi-bin/foo.pl
			$script_name = substr($script_name, 1);
		}
		$self->{_script_path} = File::Spec->catfile($ENV{'DOCUMENT_ROOT'}, $script_name);
	} else {
		if(File::Spec->file_name_is_absolute($self->{_script_name})) {
			# Called from a command line with a full path
			$self->{_script_path} = $self->{_script_name};
		} else {
			require Cwd;
			Cwd->import;

			$self->{_script_path} = File::Spec->catfile(Cwd::abs_path(), $self->{_script_name});
		}
	}
}

=head2 script_path

Finds the full path name of the script.

	use CGI::Info;

	my $info = CGI::Info->new();
	my $fullname = $info->script_path();
	my @statb = stat($fullname);

	if(@statb) {
		my $mtime = localtime $statb[9];
		print "Last-Modified: $mtime\n";
		# TODO: only for HTTP/1.1 connections
		# $etag = Digest::MD5::md5_hex($html);
		printf "ETag: \"%x\"\n", $statb[9];
	}

=cut

sub script_path {
	my $self = shift;

	unless($self->{_script_path}) {
		$self->_find_paths();
	}
	return $self->{_script_path};
}

=head2 host_name

Return the hostname of the current web server, according to CGI.
If the name can't be determined from the web server, the system's hostname
is used as a fall back.
This may not be the same as the machine that the CGI script is running on,
some ISPs and other sites run scripts on different machines from those
delivering static content.
There is a good chance that this will be domain_name() prepended with either
'www' or 'cgi'.

	use CGI::Info;

	my $info = CGI::Info->new();
	my $host_name = $info->host_name();
	my $protcol = $info->protocol();
	# ...
	print "Thank you for visiting our <A HREF=\"$protocol://$host_name\">Website!</A>";


=cut

sub host_name {
	my $self = shift;

	unless($self->{_site}) {
		$self->_find_site_details();
	}

	return $self->{_site};
}

sub _find_site_details {
	require URI::Heuristic;
	URI::Heuristic->import;

	my $self = shift;

	if($ENV{'HTTP_HOST'}) {
		$self->{_cgi_site} = URI::Heuristic::uf_uristr($ENV{'HTTP_HOST'});
	} elsif($ENV{'SERVER_NAME'}) {
		$self->{_cgi_site} = URI::Heuristic::uf_uristr($ENV{'SERVER_NAME'});
	} else {
		require Sys::Hostname;
		Sys::Hostname->import;

		$self->{_cgi_site} = Sys::Hostname->hostname;
	}

	unless($self->{_site}) {
		$self->{_site} = $self->{_cgi_site};
	}
	if($self->{_site} =~ /^http:\/\/(.+)/) {
		$self->{_site} = $1;
	}
	unless($self->{_cgi_site} =~ /^https?:\/\//) {
		my $protocol = $self->protocol();

		unless($protocol) {
			$protocol = 'http';
		}
		$self->{_cgi_site} = "$protocol://" . $self->{_cgi_site};
	}
}

=head2 domain_name

Domain_name is the name of the controlling domain for this website.
Usually it will be similar to host_name, but will lack the http:// prefix.

=cut

sub domain_name {
	my $self = shift;

	if($self->{_domain}) {
		return $self->{_domain};
	}
	$self->_find_site_details();

	if($self->{_site}) {
		$self->{_domain} = $self->{_site};
		if($self->{_domain} =~ /^www\.(.+)/) {
			$self->{_domain} = $1;
		}
	}

	return $self->{_domain};
}

=head2 cgi_host_url

Return the URL of the machine running the CGI script.

=cut

sub cgi_host_url {
	my $self = shift;

	unless($self->{_cgi_site}) {
		$self->_find_site_details();
	}

	return $self->{_cgi_site};
}

=head2 params

Returns a reference to a hash list of the CGI arguments.

If we're not in a CGI environment (e.g. the script is being tested) then
the program's command line arguments are used, if there are no command line
arguments then they are read from stdin as a list of key=value lines.

Returns undef if the parameters can't be determined.

If an argument is given twice or more, then the values are put in a
comma separated list.

The returned hash value can be passed into L<CGI::Untaint>.

Takes one parameter, expect. This is a reference to a list of arguments that
we expect to see and pass on.  Arguments not in the list are silently
ignored.  The expect list can also be passed to the constructor.

	use CGI::Info;
	use CGI::Untaint;
	# ...
	my $info = CGI::Info->new();
	my %params;
	if($info->params()) {
		%params = %{$info->params()};
	}
	# ...
	foreach(keys %params) {
		print "$_ => $params{$_}\n";
	}
	my $u = CGI::Untaint->new(%params);

	use CGI::Info;
	# ...
	my $info = CGI::Info->new();
	my @allowed = ('foo', 'bar');
	my $paramsref = $info->params(expect => \@allowed);

=cut

sub params {
	my ($self, %args) = @_;

	if($self->{_paramref}) {
		return $self->{_paramref};
	}

	if($args{expect}) {
		$self->{_expect} = $args{expect};
	}

	my(%FORM, @pairs);
	if((!$ENV{'GATEWAY_INTERFACE'}) || (!$ENV{'REQUEST_METHOD'})) {
		if(@ARGV) {
			foreach(@ARGV) {
				push(@pairs, $_);
			}
		} else {
			my $oldfh = select(STDOUT);
			print "Entering debug mode\n";
			print "Enter key=value pairs - end with quit\n";
			select($oldfh);

			while(<STDIN>) {
				chop(my $line = $_);
				last if $line eq 'quit';
				push(@pairs, $line);
			}
		}
	} elsif($ENV{'REQUEST_METHOD'} eq 'GET') {
		unless($ENV{'QUERY_STRING'}) {
			return;
		}
		@pairs = split(/&/, $ENV{'QUERY_STRING'});
	} elsif(($ENV{'REQUEST_METHOD'} eq 'POST') && $ENV{'CONTENT_LENGTH'}) {
		my $buffer;
		read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
		@pairs = split(/&/, $buffer);

		if($ENV{'QUERY_STRING'}) {
			my @getpairs = split(/&/, $ENV{'QUERY_STRING'});
			push(@pairs,@getpairs);
		}
	} elsif($ENV{'REQUEST_METHOD'} eq 'HEAD') {
		return;
	} else {
		carp "Use Post or Get\n";
		return;
	}

	foreach(@pairs) {
		my($key, $value) = split(/=/, $_);

		$key =~ tr/+/ /;
		$key =~ s/%([a-fA-F\d][a-fA-F\d])/pack("C", hex($1))/eg;
		unless($value) {
			$value = '';
		}
		$value =~ tr/+/ /;
		$value =~ s/%([a-fA-F\d][a-fA-F\d])/pack("C", hex($1))/eg;

		$key = $self->_sanitise_input($key);

		if($self->{_expect} && (member($key, @{$self->{_expect}}) == nota_member())) {
			next;
		}
		$value = $self->_sanitise_input($value);

		if($value && (length($value) > 0)) {
			if($FORM{$key}) {
				$FORM{$key} .= ",$value";
			} else {
				$FORM{$key} = $value;
			}
		}
	}

	$self->{_paramref} = \%FORM;

	return \%FORM;
}

sub _sanitise_input {
	my $self = shift;

	my $arg = shift;

	# Remove hacking attempts and spaces
	$arg =~ s/\r|\n//g;
	$arg =~ s/\s+$//;
	$arg =~ s/^\s//;

	$arg =~ s/<!--(.|\n)*-->//g;
	# Allow :
	$arg =~ s/[;<>\*|`&\$!?#\(\)\[\]\{\}'"\\\r]//g;

	return $arg;
}

=head2 is_mobile

Returns a boolean if the website is being viewed on a mobile
device such as a smart-phone.

=cut

sub is_mobile {
	my $self = shift;

	if($ENV{'HTTP_X_WAP_PROFILE'}) {
		# E.g. Blackberry
		# TODO: Check the sanity of this variable
		return 1;
	}

	if($ENV{'HTTP_USER_AGENT'}) {
		my $agent = $ENV{'HTTP_USER_AGENT'};
		if($agent =~ /.+iPhone.+/) {
			return 1;
		}
		eval {
			require HTTP::BrowserDetect;

			HTTP::BrowserDetect->import;
		};

		unless($@) {
			my $browser = HTTP::BrowserDetect->new($agent);

			if($browser && $browser->device()) {
				if($browser->device() =~ /blackberry|webos|iphone|ipod|ipad/i) {
					return 1;
				}
			}
		}
	}

	return 0;
}

=head2 as_string

Returns the parameters as a string, which is useful for debugging or
generating keys for a cache.

=cut

sub as_string {
	my $self = shift;

	unless($self->params()) {
		return '';
	}

	my %f = %{$self->params()};

	my $rc;

	foreach (sort keys %f) {
		my $value = $f{$_};
		$value =~ s/\\/\\\\/g;
		$value =~ s/(;|=)/\\$1/g;
		if(defined($rc)) {
			$rc .= ";$_=$value";
		} else {
			$rc = "$_=$value";
		}
	}

	return defined($rc) ? $rc : '';
}

=head2 protocol

Returns the connection protocol, presumably 'http' or 'https', or undef if
it can't be determined.

=cut

sub protocol {
	my $self = shift;

	if($ENV{'SCRIPT_URI'} && ($ENV{'SCRIPT_URI'} =~ /^(.+):\/\/.+/)) {
		return $1;
	}

	my $port = $ENV{'SERVER_PORT'};
	if(defined($port)) {
		if($port == 80) {
			return 'http';
		} elsif($port == 443) {
			return 'https';
		}
	}

	if($ENV{'SERVER_PROTOCOL'} && ($ENV{'SERVER_PROTOCOL'} =~ /^HTTP\//)) {
		return 'http';
	}
	return;
}

=head2 tmpdir

Returns the name of a directory that you can use to create temporary files in.

The routine is preferable to L<File::Spec/tmpdir> since CGI programs are
often running on shared servers.  Having said that, tmpdir will fall back
to File::Spec->tmpdir() if it can't find somewhere better.

If the parameter 'default' is given, then use that directory as a fall-back
rather than the value in File::Spec->tmpdir().

	use CGI::Info;

	my $info = CGI::Info->new();
	my $dir = $iinfo->tmpdir(default => '/var/tmp');

=cut

sub tmpdir {
	my($self, %params) = @_;

	my $name = 'tmp';
	if($^O eq 'MSWin32') {
		$name = 'temp';
	}

	my $dir;

	if($ENV{'C_DOCUMENT_ROOT'}) {
		$dir = "$ENV{'C_DOCUMENT_ROOT'}/$name";
		if((-d $dir) && (-w $dir)) {
			return $dir;
		}
		$dir = $ENV{'C_DOCUMENT_ROOT'};
		if((-d $dir) && (-w $dir)) {
			return $dir;
		}
	}
	if($ENV{'DOCUMENT_ROOT'}) {
		$dir = File::Spec->catdir($ENV{'DOCUMENT_ROOT'}, File::Spec->updir(), $name);
		if((-d $dir) && (-w $dir)) {
			return $dir;
		}
	}
	return $params{default} ? $params{default} : File::Spec->tmpdir();
}

=head2 is_robot

Is the visitor a real person or a robot?

	use CGI::Info;

	my $info = CGI::Info->new();
	unless($info->is_robot()) {
	  # update site visitor statistics
	}

=cut

sub is_robot {
	unless($ENV{'REMOTE_ADDR'} && $ENV{'HTTP_USER_AGENT'}) {
		# Probably not running in CGI - assume real person
		return 0;
	}

	my $remote = $ENV{'REMOTE_ADDR'};
	my $hostname = gethostbyaddr(inet_aton($remote), AF_INET) || $remote;
	my $agent = $ENV{'HTTP_USER_AGENT'};

	if($agent =~ /.+bot|msnptc|is_archiver|backstreet|spider|scoutjet|gingersoftware|heritrix|dodnetdotcom|yandex|nutch|ezooms|plukkie/i) {
		return 1;
	}
	if($hostname =~ /google\.|msnbot/) {
		return 1;
	}
	eval {
		require HTTP::BrowserDetect;

		HTTP::BrowserDetect->import;
	};

	unless($@) {
		my $browser = HTTP::BrowserDetect->new($agent);

		if($browser && $browser->robot()) {
			return 1;
		}
	}

	return 0;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-info at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Info>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

HTTP::BrowserDetect


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CGI::Info


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CGI-Info>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CGI-Info>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CGI-Info>

=item * Search CPAN

L<http://search.cpan.org/dist/CGI-Info/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Nigel Horne.

This program is released under the following licence: GPL


=cut

1; # End of CGI::Info
