package Meteodata::DbConnection

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
has 'db' => (
	is => 'ro',
	init_arg => undef
);

sub connect {
	my $self = shift;
	my $passwd = shift;
	$db = DBI->connect("DBI:mysql:database=$elf->name;host=$self->host",
				$slef->user,$passwd,{ 'RaiseError' => 1 });
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

