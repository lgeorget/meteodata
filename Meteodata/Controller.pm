# Copyright (C) 2015  Georget, Laurent <laurent@lgeorget.eu>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Meteodata::Controller;

use strict;
use warnings;

use Proc::Daemon;
use Config::Simple;
use Getopt::Long;

$Meteodata::Controller::stations = 0;
$Meteodata::Controller::continue = 1;

$SIG{INT} = $SIG{TERM} = \&signalStopHandler;
$SIG{PIPE} = 'ignore';
$SIG{HUP} = \&reconfigure;

$Meteodata::Controller::config_file = "config"; #TODO change this, autoconf placeholder?
GetOptions("config=s" => \$Meteodata::Controller::config_file);
$Meteodata::Controller::config = new Config::Simple($Meteodata::Controller::config_file);

sub validateConfiguration() {
	our $cfg = $Meteodata::Controller::config;
	my $die;
	if (!defined $cfg->param('storage.host')) {
		$die = "Configuration variable 'host' undefined for database
		connection\n";
	} elsif (!defined $cfg->param('storage.keyspace')) {
		$die = $die ."Configuration variable 'keyspace' undefined for
		database connection\n";
	} elsif (!defined $cfg->param('storage.user')) {
		$die = $die . "Configuration variable 'user' undefined for
		database connection\n";
	} elsif (!defined $cfg->param('storage.passwd')) {
		print "Configuration variable 'passwd' for database
		connection not found in the configuration variable\n";
	}

	if (defined $die) {
		print $die;
		die "Incomplete configuration -- exiting";
	}
}

sub signalStopHandler() {
	$Meteodata::Controller::continue = 1;
	# Connection to the database is closed automatically
}

sub connectToDb() {
	$Meteodata::Controller::db = Meteodata::Storage::DbConnector->new({});
}

sub reconfigure() {
	# 
	# handle reparsing the configuration
	# connect to database
	# discover the weather stations
	# reschedule the weather stations polling
}

# Initializations
reconfigure();

## Ready!

# Event loop
while ($Meteodata::Controller::continue) {

}


1;

__END__
