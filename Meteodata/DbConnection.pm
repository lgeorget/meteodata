package Meteodata::DbConnection;

use Moo;
use DBI;

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
	$db = DBI->connect("dbi:Cassandra:host=$self->host:keyspace=$self->keyspace",
				$self->user,$passwd,{ 'RaiseError' => 1 });
	return defined($db);
}

sub disconnect {
	my $self = shift;
	$self->db->disconnect;
}

sub DEMOLISH {
	my $self = shift;
	$self->disconnect;
}

sub add_new_data {
	my ($self,$id,$data) = @_;
	# ...
}

1;

__END__
