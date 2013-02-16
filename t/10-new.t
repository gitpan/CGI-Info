#!/usr/bin/perl -wT

use strict;

use Test::More tests => 1;

use CGI::Info;

isa_ok(CGI::Info->new(), 'CGI::Info', 'Creating CGI::Info object');
