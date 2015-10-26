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
use Proc::PID::File;
use Config::Simple;
use Getopt::Long;
use Meteodata::Poller;

eval { Proc::Daemon::Init;
	if (Proc::PID::File->running()) {
		print STDERR "Meteodata is already running, exiting";
		exit(1);
	}
};
if ($@) {
	print STDERR "Unable to start the daemon, exiting";
	exit(2);
}

$Meteodata::Controller::stations = undef;
$Meteodata::Controller::continue = 1;
%Meteodata::Controller::pollers = ();

$SIG{INT} = $SIG{TERM} = \&signalStopHandler;
$SIG{PIPE} = 'ignore';
$SIG{HUP} = \&reconfigure;

$Meteodata::Controller::config_file = "config"; #TODO change this, autoconf placeholder?
GetOptions("config=s" => \$Meteodata::Controller::config_file);
$Meteodata::Controller::config = new Config::Simple($Meteodata::Controller::config_file);

sub validateConfiguration {
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

sub signalStopHandler {
	$Meteodata::Controller::continue = 0;
	# Connection to the database is closed automatically
}

sub connectToDb {
	$Meteodata::Controller::db = Meteodata::Storage::DbConnector->new({});
}

sub reconfigure {
	our $db = $Meteodata::Controller::db;
	our $stations = $Meteodata::Controller::stations;
	our %pollers = %Meteodata::Controller::pollers;

	# handle reparsing the configuration
	validateConfiguration();

	# connect to database
	connectToDb();

	# discover the weather stations
	$stations = $db->discover_stations();

	# spawn a process for each station
	foreach my $new_station ($stations) {
	    my $pid = fork();
	    if ($pid == undef) {
	       warn "Could not fork one of the pollers";
	    } elsif ($pid == 0) { #child
	       Meteodata::Poller::launch_poller($db, $new_station);
		# doesn't return
	    } else { # parent
	       $pollers{$pid} = $new_station;
	       sleep 15; # wait a little between each poller spawning
	       # now, spawn the next child
	    }
	}
}

# Initializations
reconfigure();

## Ready!

# Event loop
while ($Meteodata::Controller::continue) {
  my $pid = wait();

  if ($pid == -1) {
      print "No pollers running, existing";
      $Meteodata::Controller::continue = 0;
      continue;
  }

  if (!exists $Meteodata::Controller::pollers{$pid}) {
      # WTF has just died o_O
      continue;
  }

  # revive the poller
  my $revived_poller_pid = fork();
  if ($revived_poller_pid == undef) {
      warn "Could not fork one of the pollers";
  } elsif ($revived_poller_pid == 0) { #child
      Meteodata::Poller::launch_poller($Meteodata::Controller::db,
                                       $Meteodata::Controller::pollers{$pid});
      # doesn't return
  } # else parent, nothing to do
}


1;

__END__
