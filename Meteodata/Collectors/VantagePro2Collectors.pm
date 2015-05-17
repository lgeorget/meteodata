package Meteodata::Collectors::VantagePro2Collectors;

use Moo;

has "console" {
	is => 'ro',
}

sub getOneRound {
	my $self = shift;

}

sub write {
}

sub wake_up {
	my $self = shift;

	my $answer;
	foreach (1..3) {
		$self->write("\n");
		sysread($self->console, $answer, 2);
		if ($answer != "\n\r") {
			sleep 2; #wait before retrying
		} else {
			last; #succesfully woken up, jump out of the loop
		}
	}
}

sub check_crc {
	my $self = shift;
	my $blob = shift;
	my $crc = shift;
}


1;

__END__
