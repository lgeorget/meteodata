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

package Meteodata::Poller;

use strict;
use warnings;

use Proc::Daemon;
use Time::HiRes;
use IO::Socket;
use POSIX;

$Meteodata::Poller::station_id;
$Meteodata::Poller::station_addr;
$Meteodata::Poller::station_port;
$Meteodata::Poller::polling_interval;
$Meteodata::Poller::db;
$Meteodata::Poller::continue = 1;

$SIG{ALRM} = \&poll_station;
$SIG{TERM} = \&signalStopHandler;

sub signalStopHandler() {
	$Meteodata::Poller::continue = 0;
}

sub launch_poller {
	my ($db_connection,$new_station) = @_;

	our $station_id = $Meteodata::Poller::station_id;
	our $station_addr = $Meteodata::Poller::station_addr;
	our $station_port = $Meteodata::Poller::station_port;
	our $polling_interval = $Meteodata::Poller::polling_interval;
	our $db = $Meteodata::Poller::db;

	($station_id,$station_addr,$station_port,$polling_interval) = @$new_station;
	$db = $db_connection;
	# We should verify the type of station too, when we have more than one

	setitimer($polling_interval);
	run();
}

sub run {
	while ($Meteodata::Poller::continue) {
		pause; # wait for the polling signal (ALRM)
	}
	print "Poller for station " . $Meteodata::Poller::station_id . " exiting"; 
}

sub poll_station {
	my $socket = new IO::Socket::INET(
		PeerAddr => $Meteodata::Poller::station_addr,
		PeerPort => $Meteodata::Poller::station_port,
		Proto => 'tcp',
	);

	unless ($socket->connected) {
		print "Could not reach station " . $Meteodata::Poller::station_id;
		return undef;
	}

	my $collector = Meteodata::Collectors::VantagePro2Collector->new($socket);
	$Meteodata::Poller::db->add_new_data($Meteodata::Poller::station_id,$collector->getOneLoop);
	return 0;
}

1;

__END__
