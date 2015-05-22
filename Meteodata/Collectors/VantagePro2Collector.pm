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

package Meteodata::Collectors::VantagePro2Collector;

use v5.20;
use Moo;

has console => (
	is => 'ro',
);

@Meteodata::Collectors::VantagePro2Collector::crc_table = (
0x0, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
0x1231, 0x210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
0x2462, 0x3443, 0x420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
0x3653, 0x2672, 0x1611, 0x630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
0x48c4, 0x58e5, 0x6886, 0x78a7, 0x840, 0x1861, 0x2802, 0x3823,
0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0xa50, 0x3a33, 0x2a12,
0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0xc60, 0x1c41,
0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0xe70,
0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f,
0x1080, 0xa1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e,
0x2b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
0x34e2, 0x24c3, 0x14a0, 0x481, 0x7466, 0x6447, 0x5424, 0x4405,
0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c,
0x26d3, 0x36f2, 0x691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab,
0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x8e1, 0x3882, 0x28a3,
0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
0x4a75, 0x5a54, 0x6a37, 0x7a16, 0xaf1, 0x1ad0, 0x2ab3, 0x3a92,
0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9,
0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0xcc1,
0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0xed1, 0x1ef0);

sub read {
	my $self = shift;
	my $buffer = shift;
	my $size = shift;

	my $nread = 0;
	eval {
		local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
		alarm 3;
		$nread = sysread($self->console(), $$buffer, $size);
		alarm 0;
	};
	if ($@) {
		die unless $@ eq "alarm\n"; # TODO: change die for something
		                            # less definitive
		# timed out
	}
	return $nread; # return 0 if nothing could be read, because of timeout
}

sub getOneLoop {
	my $self = shift;

	$self->wake_up();

	my %data;
	my $l1 = "A"x99;
	my $l2 = "A"x99;

	my $attempts = 3;
	while (my $ok == 0 && $attempts > 0) {
		$self->write("LPS 3 1");

		# First, we will receive LOOP 1
		$ok = $self->read($self, \$l1, 99) == 99;
		# Next, LOOP 2
		$ok = $ok && $self->read($self, \$l2, 99) == 99;
		if ($self->crc_check(substr($l1, 0, 97),
				     extract(\$l1, "N", 97, 2)) &&
		    $self->crc_check(substr($l2, 0, 97),
				     extract(\$l2, "N", 97, 2))) {

			$ok = 1;
		} else {
			$attempts -= 1;
			warn "Reception error, retrying";
		}
	}

	if ($attempts <= 0) {
		warn "Impossible to receive the LOOP packets";
		return -1;
	}

	if (substr($l1, 0, 3) != "LOO" ||
	    extract($l1, "C", 4, 1) != 0 ||
	    substr($l1, 95, 2) != "\n\r") {
		warn "LOOP 1 packet ill-formatted";
		return -2;
	}
	if (substr($l2, 0, 3) != "LOO" ||
	    extract($l2, "C", 4, 1) != 1 ||
	    substr($l2, 95, 2) != "\n\r") {
		warn "LOOP 2 packet ill-formatted";
		return -3;
	}

	# Parse LOOP 1
	$data{'Bar Trend'} = extract(\$l1, "C", 3, 1);
	$data{'Barometer'} = extract(\$l1, "v", 7, 2);
	$data{'Inside Temperature'} = extract(\$l1, "v", 9, 2);
	$data{'Inside Humidity'} = extract(\$l1, "C", 11, 1);
	$data{'Outside Temperature'} = extract(\$l1, "v", 12, 2);
	$data{'Wind Speed'} = extract(\$l1, "C", 14, 1);
	$data{'10 Min Avg Wind Speed'} = extract(\$l1, "C", 15, 1);
	$data{'Wind Direction'} = extract(\$l1, "v", 16, 2);
	$data{'Extra Temperature'} = [
		extract(\$l1, "C", 18, 1),
		extract(\$l1, "C", 19, 1),
		extract(\$l1, "C", 20, 1),
		extract(\$l1, "C", 21, 1),
		extract(\$l1, "C", 22, 1),
		extract(\$l1, "C", 23, 1),
		extract(\$l1, "C", 24, 1)
	];
	$data{'Soil Temperature'} = [
		extract(\$l1, "C", 25, 1),
		extract(\$l1, "C", 26, 1),
		extract(\$l1, "C", 27, 1),
		extract(\$l1, "C", 28, 1)
	];
	$data{'Leaf Temperature'} = [
		extract(\$l1, "C", 29, 1),
		extract(\$l1, "C", 30, 1),
		extract(\$l1, "C", 31, 1),
		extract(\$l1, "C", 32, 1)
	];
	$data{'Outside Humidity'} = extract(\$l1, "C", 33, 1);
	$data{'Extra Humidities'} = [
		extract(\$l1, "C", 34, 1),
		extract(\$l1, "C", 35, 1),
		extract(\$l1, "C", 36, 1),
		extract(\$l1, "C", 37, 1),
		extract(\$l1, "C", 38, 1),
		extract(\$l1, "C", 39, 1),
		extract(\$l1, "C", 40, 1)
	];
	$data{'Rain Rate'} = extract(\$l1, "v", 41, 2);
	$data{'UV'} = extract(\$l1, "C", 43, 1);
	$data{'Solar Radiation'} = extract(\$l1, "v", 44, 2);
	$data{'Storm Rain'} = extract(\$l1, "v", 46, 2);
	$data{'Start Date of current Storm'} = extract(\$l1, "v", 48, 2);
	$data{'Day Rain'} = extract(\$l1, "v", 50, 2);
	$data{'Month Rain'} = extract(\$l1, "v", 52, 2);
	$data{'Year Rain'} = extract(\$l1, "v", 54, 2);
	$data{'Day ET'} = extract(\$l1, "v", 56, 2);
	$data{'Month ET'} = extract(\$l1, "v", 58, 2);
	$data{'Year ET'} = extract(\$l1, "v", 60, 2);
	$data{'Soil Moistures'} = [
		extract(\$l1, "C", 62, 1),
		extract(\$l1, "C", 63, 1),
		extract(\$l1, "C", 64, 1),
		extract(\$l1, "C", 65, 1)
	];
	$data{'Leaf Wetnesses'} = [
		extract(\$l1, "C", 66, 1),
		extract(\$l1, "C", 67, 1),
		extract(\$l1, "C", 68, 1),
		extract(\$l1, "C", 69, 1)
	];
	$data{'Console Battery Voltage'} = extract(\$l1, "v", 87, 2);
	$data{'Time of Sunrise'} = extract(\$l1, "v", 91, 2);
	$data{'Time of Sunset'} = extract(\$l1, "v", 93, 2);

	# Parse LOOP 2

}

sub extract {
	my $answer = shift;
	my $packer = shift;
	my $offset = shift;
	my $length = shift;

	return unpack($packer, substr($$answer, $offset, $length));
}

sub write {
	my $self = shift;
	my $msg = shift;

	my $fh = $self->console;

	print $fh "$msg\n";
}

sub wake_up {
	my $self = shift;

	my $answer;
	foreach (1..3) {
		$self->write("\n");
		sysread($self->console(), $answer, 2);
		if ($answer != "\n\r") {
			sleep 2; #wait before retrying
		} else {
			last; #succesfully woken up, jump out of the loop
		}
	}
}

sub check_crc {
	my $self = shift;
	my $blob = shift; # a binary string received or to be sent to the Vantage Pro 2 station
	my $crc = shift; # the CRC value for $blob

	# Initialization
	my $computed_crc = 0;

	# Compute the CRC on data
	foreach my $data (unpack("C*",$blob))
	{
	   crc_round($data,\$computed_crc);
	}

	# Check first byte (MSB) of CRC
	my $data = ($crc & 0xFF00) >> 8;
	crc_round($data,\$computed_crc);

	# Check second byte (LSB) of CRC
	$data = $crc & 0xFF;
	crc_round($data,\$computed_crc);

	return !$computed_crc; #CRC check passes if crc == 0
}

sub crc_round {
	my $byte = shift;
	my $current_crc = shift;

	our @crc_table = @Meteodata::Collectors::VantagePro2Collector::crc_table;

	# All the magic is taken from  Chapter XII in
	# 	"Vantage Pro TM , Vantage Pro2 TM and Vantage Vue TM
	#	Serial Communication Reference Manual", by Davis Instruments Corp.
	#	v2.61, March 29th, 2013
	my $index = $$current_crc >> 8 ^ $byte;
	$$current_crc = $crc_table[$index] ^ (($$current_crc << 8) & 0xFFFF);
}


1;

__END__
