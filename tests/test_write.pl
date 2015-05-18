#!/usr/bin/perl
#

use strict;
use warnings;

use Meteodata::Collectors::VantagePro2Collectors;

my $controller = Meteodata::Collectors::VantagePro2Collectors->new(
	console => *STDOUT,
);

$controller->write("coucou");


