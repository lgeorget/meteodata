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

package Meteodata::Storage::DbConnection;

use Moo;
use IO::Async::Loop;
use Net::Async::CassandraCQL;
use Protocol::CassandraCQL qw( CONSISTENCY_QUORUM );


$Meteodata::Storage::db = undef;
$Meteodata::Storage::loop = undef;

has 'table' => (
	is => 'ro'
);
has 'user' => (
	is => 'ro'
);
has 'host' => (
	is => 'ro'
);
has 'keyspace' => (
	is => 'ro',
);

sub connect {
	my $self = shift;
	my $passwd = shift;
 	$Meteodata::Storage::loop = IO::Async::Loop->new;
	$Meteodata::Storage::db = Net::Async::CassandraCQL->new(
		host => $self->host,
		keyspace => $self->keyspace,
		username => $self->user,
		password => $passwd,
		default_consistency => CONSISTENCY_QUORUM,
	);
	$Meteodata::Storage::loop->add($Meteodata::Storage::db);
 	$Meteodata::Storage::db->connect->get;
	return defined($Meteodata::Storage::db);
}

sub disconnect {
	my $self = shift;
	my $future = Future->new;
	$Meteodata::Storage::db->close_when_idle;
}

sub DEMOLISH {
	my $self = shift;
	$self->disconnect;
}

sub add_new_data {
	my ($self,$id,$data) = @_;
	my $put_stmt = $Meteodata::Storage::db->query("INSERT INTO data_$id (...) VALUES (...)")->get;
	my ($type, $result) = $put_stmt->execute($data);
}

sub discover_stations {
	my $self = shift;
	my $sth = $Meteodata::Storage::db->prepare("SELECT id,address,port,polling_period FROM stations")->get;
	my ($type, $result) = $sth->execute([])->get;
	my @stations = $result->rows_array;
	print "Discovered " . scalar(@stations) . " stations";
	return \@stations;
}

1;

__END__
