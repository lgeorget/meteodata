#!/usr/bin/perl
#

use strict;
use warnings;

use Meteodata::Collectors::VantagePro2Collector;

my $controller = Meteodata::Collectors::VantagePro2Collector->new(
	console => *STDOUT,
);

$controller->write("coucou");


