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

use Proc::Daemon;

$Meteodata::Controller::stations = 0;
$Meteodata::Controller::continue = 1;
$Meteodata::Controller::db;

$SIG{INT} = $SIG{TERM} = \&signalStopHandler;
$SIG{PIPE} = 'ignore';
$SIG{HUP} = \&reconfigure;

sub signalStopHandler() {
	$continue = 1;
	# Connection to the database is closed automatically
}

sub connectToDb() {
	$Meteodata::Controller::db = Meteodata::Storage::DbConnector->new({});
}

sub reconfigure() {
	# handle reparsing the configuration
	# connect to database
	# discover the weather stations
	# reschedule the weather stations polling
}

# Initializations
reconfigure();

## Ready!

# Event loop
while ($continue) {

}


1;

__END__
