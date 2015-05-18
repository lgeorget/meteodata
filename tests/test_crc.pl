#!/usr/bin/perl
#

use strict;
use warnings;

use Meteodata::Collectors::VantagePro2Collector;

my $controller = Meteodata::Collectors::VantagePro2Collector->new(
	console => *STDOUT,
);

print $controller->check_crc("\xC6\xCE\xA2\x03",unpack("S>","\xE2\xB4"));

