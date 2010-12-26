package CGI::Info;

use warnings;
use strict;
use Carp;

=head1 NAME

CGI::Info - Information about the CGI environment

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

All too often Perl programs have information such as the script's name
hard-coded into their source.
Generally speaking, hard-coding is bad style since it can make programs
difficult to read and it reduces readablility and portability.
CGI::Info attempts to remove that.

Furthermore, to aid script debugging, CGI::Info attempts to do sensible
things when you're not running the program in a CGI environment.

Perhaps a little code snippet.

    use CGI::Info;

    my $info = CGI::Info->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates a CGI::Info object.

=cut

sub new {
	my $class = shift;

	my $self = {
		_script_name => undef,
		_script_path => undef,
		_site => undef,
		_cgi_site => undef,
		_domain => undef,
		_paramref => undef,
	};
	bless $self, $class;

	return $self;
}

=head2 script_name

Returns the name of the CGI script.
This is useful for POSTing, thus avoiding putting hardcoded paths into forms

	my $info = CGI::Info->new();
	my $script_name = $info->script_name();
	...
	print "<form method=\"POST\" action=$script_name name=\"my_form\">\n";

=cut

sub script_name {
	my $self = shift;

	if($self->{_script_name}) {
		return $self->{_script_name};
	}
	$self->_find_paths();
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
		$self->{_script_path} = $ENV{'DOCUMENT_ROOT'} . $ENV{'SCRIPT_NAME'};
	} else {
		require File::Spec;
		File::Spec->import;

		if(File::Spec->file_name_is_absolute($self->{_script_name})) {
			$self->{_script_path} = $self->{_script_name};
		} else {
			require Cwd;
			Cwd->import;

			# FIXME: What is the current drive on Win32?
			$self->{_script_path} = File::Spec->catpath('', Cwd::abs_path(), $self->{_script_name});
		}
	}
}

=head2 script_path

Finds the full path name of the script.

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

	if($self->{_script_path}) {
		return $self->{_script_path};
	}
	$self->_find_paths();
	return $self->{_script_path};
}

=head2 host_name

Return the hostname of the current web server, according to CGI.
If the name can't be determined from the web server, the system's hostname
is used as a fall back.
This may not be the same as the machine that the CGI script is running on,
some ISPs and other sites run scripts on different machines from those
delivering static content.

=cut

sub host_name {
	my $self = shift;

	if($self->{_site}) {
		return $self->{_site};
	}
	$self->_find_site_details();

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
	unless($self->{_cgi_site} =~ /^http:\/\//) {
		$self->{_cgi_site} = 'http://' . $self->{_cgi_site};
	}
}

=head2 domain_name

Domain_name is the name of the controling domain for this website.
It will be similar to host_name.

	my $info = CGI::Info->new();
	my $domain_name = $info->domain_name();
	...
	print "Thank you for visiting our <A HREF=$domain_name>Website!</A>";

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

	if($self->{_cgi_site}) {
		return $self->{_cgi_site};
	}
	$self->_find_site_details();

	return $self->{_cgi_site};
}

=head2 params

Returns a referece to hash list of the CGI arguments.
If we're not in a CGI environment (e.g. the script is being tested) then
the program's command line arguments are used, if there are no command line
arguments then they are read from stdin as a list of key=value lines.

Returns undef if the parameters can't be determined.

If an argument is given twice or more, then the values are put in a
comma separated list.

	my $info = CGI::Info->new();
	my %params = %{$info->params()};
	...
	foreach(keys %params) {
		print "$_ => $params{$_}\n";
	}
=cut

sub params {
	my $self = shift;

	if($self->{_paramref}) {
		return $self->{_paramref};
	}

	my(%FORM, @pairs);
	if(!$ENV{'REQUEST_METHOD'}) {
		if(@ARGV) {
			foreach(@ARGV) {
				push(@pairs, $_);
			}
		} else {
			print "Entering debug mode\n";
			print "Enter key=value pairs - end with quit\n";

			while(<STDIN>) {
				chop(my $line = $_);
				last if $line eq 'quit';
				push(@pairs, $line);
			}
		}
	} elsif($ENV{'REQUEST_METHOD'} eq 'GET') {
		@pairs = split(/&/, $ENV{'QUERY_STRING'});
	} elsif($ENV{'REQUEST_METHOD'} eq 'POST') {
		my $buffer;
		read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
		@pairs = split(/&/, $buffer);

		if($ENV{'QUERY_STRING'}) {
			my @getpairs = split(/&/, $ENV{'QUERY_STRING'});
			push(@pairs,@getpairs);
		}
	} elsif($ENV{'REQUEST_METHOD'} eq 'HEAD') {
		return undef;
	} else {
		carp "Use Post or Get\n";
		return undef;
	}

	foreach(@pairs) {
		my($key, $value) = split(/=/, $_);

		$key =~ tr/+/ /;
		$key =~ s/%([a-fA-F\d][a-fA-F\d])/pack("C", hex($1))/eg;
		unless($value) {
			$value = "";
		}
		$value =~ tr/+/ /;
		$value =~ s/%([a-fA-F\d][a-fA-F\d])/pack("C", hex($1))/eg;

		$key = $self->_sanitise_input($key);
		$value = $self->_sanitise_input($value);

		if($value && (length($value) > 0)) {
			if($FORM{$key}) {
				$FORM{$key} .= ", $value";
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

	$arg =~ s/<!--(.|\n)*-->//g;
	# Allow :
	$arg =~ s/[;<>\*|`&\$!?#\(\)\[\]\{\}'"\\]//g;

	return $arg;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cgi-info at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Info>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




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

Copyright 2010 Nigel Horne.

This program is released under the following license: GPL


=cut

1; # End of CGI::Info
