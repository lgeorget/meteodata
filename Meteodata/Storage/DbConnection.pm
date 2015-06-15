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
use perlcassa;

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

has 'db' => (
	is => 'ro',
);

sub connect {
	my $self = shift;
	my $passwd = shift;
	$self->db = DBI->connect("dbi:Cassandra:host=$self->host:keyspace=$self->keyspace",
				$self->user,$passwd,{ 'RaiseError' => 1 });
	return defined($self->db);
}

sub disconnect {
	my $self = shift;
	$self->db->disconnect;
}

sub DEMOLISH {
	my $self = shift;
	$self->disconnect;
}

1;

__END__