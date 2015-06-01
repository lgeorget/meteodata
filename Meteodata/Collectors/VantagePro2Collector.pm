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
use Meteodata::Converters::UnitConverter qw/inHg_to_bar mph_to_mps
					    in_to_mm degreesF_to_C/;

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

	my $nread;
	eval {
		local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
		$nread = 0;
		my $last_read = -1;
		while ($nread < $size && $last_read != 0) {
			alarm 5;
			$last_read = sysread($self->console(), $$buffer, $size, $nread);
			alarm 0;
			$nread += $last_read;
		}
	};
	if ($@) {
		die unless $@ eq "alarm\n"; # TODO: change die for something
		                            # less definitive
		warn "timeout!\n";
	}
	print "read $nread bytes\n";
	return $nread; # return 0 if nothing could be read, because of timeout
}

sub getOneLoop {
	my $self = shift;

	$self->wake_up();

	my %data;
	my $loops;

	my $attempts = 3;
	my $ok = 0;
	while ($ok == 0 && $attempts > 0) {
		$self->write("LPS 3 2",1);

		# First, we will receive LOOP1 and 2.5 sec later LOOP2
		print "reading...\n";
		# We expect 99 bytes (LOOP1) + 99 bytes (LOOP2)
		$ok = ($self->read(\$loops, 198) == 198);
		print "finished reading\n";

		# It's possible to make a single CRC check for two packets in a
		# row thanks to the properties of the CRC used
		my $crc = $self->check_crc($loops);
		if (!$ok || !$crc)
		{
			warn "Reception error (read: $ok, crc_LOOP: $crc), retrying";
			$attempts -= 1;
			$ok = 0;
		}
	}

	if ($attempts <= 0) {
		warn "Impossible to receive the LOOP packets";
		return undef;
	} else {
		print "Loop packets received, parsing on progress...";
	}

	# The reception went well, now, let's have a look to the packet
	$ok = 1;
	if (extract(\$loops, "A3", 0, 3) ne "LOO") {
		warn "LOOP packet doesn't start with 'LOO' as expected";
		$ok = 0;
	}
	if (extract(\$loops, "C", 4, 1) != 0) {
		warn "Not a LOOP 1 packet";
		$ok = 0;
	}
	if (!$ok) {
		return undef;
	}

	# Parse LOOP 1
	$data{'Bar Trend'} = extract(\$loops, "C", 3, 1);
	$data{'Barometer'} = extract(\$loops, "v", 7, 2);
	$data{'Inside Temperature'} = extract(\$loops, "v", 9, 2);
	$data{'Inside Humidity'} = extract(\$loops, "C", 11, 1);
	$data{'Outside Temperature'} = extract(\$loops, "v", 12, 2);
	$data{'Wind Speed'} = extract(\$loops, "C", 14, 1);
	$data{'Wind Direction'} = extract(\$loops, "v", 16, 2);
	$data{'Extra Temperature'} = [
		extract(\$loops, "C", 18, 1),
		extract(\$loops, "C", 19, 1),
		extract(\$loops, "C", 20, 1),
		extract(\$loops, "C", 21, 1),
		extract(\$loops, "C", 22, 1),
		extract(\$loops, "C", 23, 1),
		extract(\$loops, "C", 24, 1)
	];
	$data{'Soil Temperature'} = [
		extract(\$loops, "C", 25, 1),
		extract(\$loops, "C", 26, 1),
		extract(\$loops, "C", 27, 1),
		extract(\$loops, "C", 28, 1)
	];
	$data{'Leaf Temperature'} = [
		extract(\$loops, "C", 29, 1),
		extract(\$loops, "C", 30, 1),
		extract(\$loops, "C", 31, 1),
		extract(\$loops, "C", 32, 1)
	];
	$data{'Outside Humidity'} = extract(\$loops, "C", 33, 1);
	$data{'Extra Humidities'} = [
		extract(\$loops, "C", 34, 1),
		extract(\$loops, "C", 35, 1),
		extract(\$loops, "C", 36, 1),
		extract(\$loops, "C", 37, 1),
		extract(\$loops, "C", 38, 1),
		extract(\$loops, "C", 39, 1),
		extract(\$loops, "C", 40, 1)
	];
	$data{'Rain Rate'} = extract(\$loops, "v", 41, 2);
	$data{'UV'} = extract(\$loops, "C", 43, 1);
	$data{'Solar Radiation'} = extract(\$loops, "v", 44, 2);
	$data{'Storm Rain'} = extract(\$loops, "v", 46, 2);
	$data{'Start Date of current Storm'} = extract(\$loops, "v", 48, 2);
	$data{'Day Rain'} = extract(\$loops, "v", 50, 2);
	$data{'Month Rain'} = extract(\$loops, "v", 52, 2);
	$data{'Year Rain'} = extract(\$loops, "v", 54, 2);
	$data{'Day ET'} = extract(\$loops, "v", 56, 2);
	$data{'Month ET'} = extract(\$loops, "v", 58, 2);
	$data{'Year ET'} = extract(\$loops, "v", 60, 2);
	$data{'Soil Moistures'} = [
		extract(\$loops, "C", 62, 1),
		extract(\$loops, "C", 63, 1),
		extract(\$loops, "C", 64, 1),
		extract(\$loops, "C", 65, 1)
	];
	$data{'Leaf Wetnesses'} = [
		extract(\$loops, "C", 66, 1),
		extract(\$loops, "C", 67, 1),
		extract(\$loops, "C", 68, 1),
		extract(\$loops, "C", 69, 1)
	];
	$data{'Console Battery Voltage'} = extract(\$loops, "v", 87, 2);
	$data{'Time of Sunrise'} = extract(\$loops, "v", 91, 2);
	$data{'Time of Sunset'} = extract(\$loops, "v", 93, 2);

	# Parse LOOP 2
	# Only extract fields different from LOOP1
	# We take the 10-Min Avg Wind Speed from here because we have higher
	# resolution than in LOOP 1
	$data{'10-Min Avg Wind Speed'} = extract(\$loops, "v", 98 + 18, 2);
	$data{'2-Min Avg Wind Speed'} = extract(\$loops, "v", 98 + 20, 2);
	$data{'10-Min Wind Gust'} = extract(\$loops, "v", 98 + 22, 2);
	$data{'Wind Direction for the 10-Min Wind Gust'} = extract(\$loops, "v", 98 + 24, 2);
	$data{'Dew Point'} = extract(\$loops, "v", 98 + 30, 2);
	$data{'Heat Index'} = extract(\$loops, "v", 98 + 35, 2);
	$data{'Wind Chill'} = extract(\$loops, "v", 98 + 37, 2);
	$data{'THSW Index'} = extract(\$loops, "v", 98 + 39, 2);
	$data{'Last 15-min Rain'} = extract(\$loops, "v", 98 + 52, 2);
	$data{'Last Hour Rain'} = extract(\$loops, "v", 98 + 54, 2);
	$data{'Last 24-Hour Rain'} = extract(\$loops, "v", 98 + 58, 2);

	return \%data;
}

sub convert_data {
	my ($self, $data) = @_;

	# Barometer trend (LOOP 1, offset 4)
	if ($data->{'Bar Trend'} == 196) {
		$data->{'Bar Trend'} = "Falling rapidly";
	} elsif ($data->{'Bar Trend'} == 236) {
		$data->{'Bar Trend'} = "Falling slowly";
	} elsif ($data->{'Bar Trend'} == 0) {
		$data->{'Steady'} = "Steady";
	} elsif ($data->{'Bar Trend'} == 20) {
		$data->{'Bar Trend'} = "Raising slowly";
	} elsif ($data->{'Bar Trend'} == 60) {
		$data->{'Bar Trend'} = "Raising rapidly";
	} else {
		$data->{'Bar Trend'} = undef;
	}

	# Current barometer value (LOOP 1, offset 7)
	if ($data->{'Barometer'} > 20 && $data->{'Barometer'} < 32.5) {
	    $data->{'Barometer'} = inHg_to_bar($data->{'Barometer'}) * 1000;
	} else {
	    $data->{'Barometer'} = undef;
	}

	# Inside temperature (LOOP 1, offset 11)
	$data->{'Inside Temperature'} = degreesF_to_C($data->{'Inside Temperature'});

	# Inside humidity (LOOP 1, offset 12)
	# Already OK: in %

	# Outside temperature (LOOP 1, offset 12)
	if ($data->{'Outside Temperature'} != 255) {
		$data->{'Outside Temperature'} = degreesF_to_C($data->{'Outside Temperature'});
        } else {
		$data->{'Outside Temperature'} = undef;
	}

	# Wind speed (LOOP 1, offset 14)
	$data->{'Wind Speed'} = mph_to_mps($data->{'Wind Speed'});

	# Wind direction (LOOP 1, offset 16)
	# Already OK; in °

	# Extra temperatures (LOOP 1, offset 18)
	@{$data->{'Extra Temperatures'}} =
		map {
			if ($_!=255) {
				degreesF_to_C($_ - 90);
			} else {
				undef;
			}
		}  @{$data->{'Extra Temperatures'}};

	# Soil temperatures (LOOP 1, offset 25)
	@{$data->{'Soil Temperatures'}} =
		map {
			if ($_!=255) {
				degreesF_to_C($_ - 90);
			} else {
				undef;
			}
		}  @{$data->{'Soil Temperatures'}};

	# Leaf temperatures (LOOP 1, offset 29)
	@{$data->{'Leaf Temperatures'}} =
		map {
			if ($_!=255) {
				degreesF_to_C($_ - 90);
			} else {
				undef;
			}
		}  @{$data->{'Leaf Temperatures'}};

	# Outside humidity (LOOP 1, offset 33)
	# Already OK: in %

	# Extra humidities (LOOP 1, offset 34)
	# Already OK: in %

	# Rain rate (LOOP 1, offset 41)
	# ASSUMING THE RAW VALUE IS IN 0.2mm/hour
	$data->{'Rain Rate'} = $data->{'Rain Rate'} * 0.2;

	# UV index (LOOP 1, offset 43)
	# Already OK: in usual, meteological, unit
	if ($data->{'UV'} == 255) {
		$data->{'UV'} = undef;
	}

	# Solar radiation (LOOP 1, offset 44)
	# Already OK: in watt/m^3
	if ($data->{'Solar Radiation'} == 32767) {
		$data->{'Solar Radiation'} = undef;
	}

	# Storm rain (LOOP 1, offset 46)
	$data->{'Storm Rain'} = in_to_mm($data->{'Storm Rain'}*100);

	# Start Date of current Storm (LOOP 1, offset 48)
	{
	my $day = vec($data->{'Start Date of current Storm'},7,5);
	my $month = vec($data->{'Start Date of current Storm'},12,3);
	# the year should be interpreted as a signed character
	# for offsetting with 2000 but we have quite good reasons not to
	# expect future storms to begin before year 2000
	my $year = vec($data->{'Start Date of current Storm'},0,7) + 2000;

	if ($day > 0 && $day <= 31 &&
	    $month >= 1 && $month <= 12) {
		$data->{'Start Date of current Storm'} = "$year-$month-$day";
	} else {
		$data->{'Start Date of current Storm'} = undef;
	}
	}

	# Day rain (LOOP 1, offset 50)
	$data->{'Day Rain'} = $data->{'Day Rain'} * 0.2;

	# Month rain (LOOP 1, offset 52)
	$data->{'Month Rain'} = $data->{'Month Rain'} * 0.2;

	# Year rain (LOOP 1, offset 54)
	$data->{'Year Rain'} = $data->{'Year Rain'} * 0.2;

	# Day ET (LOOP 1, offset 56) in 1000th of an inch
	$data->{'Day ET'} = in_to_mm($data->{'Day ET'}*1000);

	# Month ET (LOOP 1, offset 58) in 100th of an inch
	$data->{'Month ET'} = in_to_mm($data->{'Month ET'}*100);

	# Year ET (LOOP 1, offset 60) in 100th of an inch
	$data->{'Year ET'} = in_to_mm($data->{'Year ET'}*100);

	# Soil moistures (LOOP 1, offset 62)
	@{$data->{'Soil Moistures'}} =
		map {
			if ($_!=255) {
				$_; #TODO check the unit here, centibar??
			} else {
				undef;
			}
		}  @{$data->{'Soil Moistures'}};

	# Leaf wetnesses (LOOP 1, offset 66) in custom scale from 0 to 15
	@{$data->{'Leaf Wetnesses'}} =
		map {
			if ($_>=0 && $_<=15) {
				$_;
			} else {
				undef;
			}
		}  @{$data->{'Leaf Wetnesses'}};

	# Console battery voltage (LOOP 1, offset 87)
	$data->{'Console Battery Voltage'} =
		(($data->{'Console Battery Voltage'} * 300) / 512) / 100.0;

	# Time of Sunrise (LOOP 1, offset 91)
	if ($data->{'Time of Sunrise'} != 32767) {
		my $hour = $data->{'Time of Sunrise'} / 100;
		my $min = $data->{'Time of Sunrise'} % 100;
		$data->{'Time of Sunrise'} = "$hour:$min";
	} else {
		$data->{'Time of Sunrise'} = undef;
	}

	# Time of Sunrise (LOOP 1, offset 93)
	if ($data->{'Time of Sunrise'} != 32767) {
		my $hour = $data->{'Time of Sunrise'} / 100;
		my $min = $data->{'Time of Sunrise'} % 100;
		$data->{'Time of Sunrise'} = "$hour:$min";
	} else {
		$data->{'Time of Sunrise'} = undef;
	}

	# Last 10 minutes average wind speed (LOOP 2, offset 18)
	if ($data->{'10-Min Avg Wind Speed'} != 32767) {
		$data->{'10-Min Avg Wind Speed'} = mph_to_mps($data->{'10-Min Avg Wind Speed'} * 10);
	} else {
		$data->{'10-Min Avg Wind Speed'} = undef;
	}

	# Last 2 minutes average wind speed (LOOP 2, offset 20)
	if ($data->{'2-Min Avg Wind Speed'} != 32767) {
		$data->{'2-Min Avg Wind Speed'} = mph_to_mps($data->{'2-Min Avg Wind Speed'} * 10);
	} else {
		$data->{'2-Min Avg Wind Speed'} = undef;
	}

	# Last 10 minutes wind gust (LOOP 2, offset 22)
	if ($data->{'10-Min Wind Gust'} != 32767) {
		$data->{'10-Min Wind Gust'} = mph_to_mps($data->{'10-Min Wind Gust'} * 10);
	} else {
		$data->{'10-Min Wind Gust'} = undef;
	}

	# Wind direction for the 10-Min Wind Gust (LOOP 2, offset 24)
	# Already OK: in °

	# Dew point (LOOP 2, offset 30)
	if ($data->{'Dew Point'} != 255) {
		$data->{'Dew Point'} = degreesF_to_C($data->{'Dew Point'});
	} else {
		$data->{'Dew Point'} = undef;
	}

	# Heat index (LOOP 2, offset 35)
	if ($data->{'Heat Index'} != 255) {
		$data->{'Heat Index'} = degreesF_to_C($data->{'Heat Index'});
	} else {
		$data->{'Heat Index'} = undef;
	}

	# Wind chill (LOOP 2, offset 37)
	if ($data->{'Wind Chill'} != 255) {
		$data->{'Wind Chill'} = degreesF_to_C($data->{'Wind Chill'});
	} else {
		$data->{'Wind Chill'} = undef;
	}

	# THSW index (LOOP 2, offset 39)
	if ($data->{'THSW Index'} != 255) {
		$data->{'THSW Index'} = degreesF_to_C($data->{'THSW Index'});
	} else {
		$data->{'THSW Index'} = undef;
	}

	# Last 15 minutes rain (LOOP 2, offset 52)
	$data->{'Last 15-min Rain'} = $data->{'Last 15-min Rain'}*0.2;

	# Last hour rain (LOOP 2, offset 54)
	$data->{'Last Hour Rain'} = $data->{'Last Hour Rain'}*0.2;

	# Last 24 hours rain (LOOP 2, offset 56)
	$data->{'Last 24-Hour Rain'} = $data->{'Last 24-Hour Rain'}*0.2;
}


sub extract {
	my $answer = shift;
	my $packer = shift;
	my $offset = shift;
	my $length = shift;

	return unpack("x$offset$packer", $$answer);
}

sub write {
	my $self = shift;
	my $msg = shift;
	my $wait_for_ack = shift;

	my $fh = $self->console;

	print $fh "$msg\n";
	if ($wait_for_ack) {
		print "Waiting for acknowledgement\n";
		my $discard;
		$self->read(\$discard, 1);
		print "Acknowledgment: ",extract(\$discard, "C", 0, 1),"\n";
	}
}

sub wake_up {
	my $self = shift;

	print "Waking up the device\n";
	my $answer;
	foreach (1..3) {
		my $nbread;
		$self->write("\n",0);
		$nbread = $self->read(\$answer, 2);
		print "Answer: ",extract(\$answer, "CC", 0, 1),"\n";
		if ($nbread != 2 || $answer ne "\n\r") {
			sleep 2; #wait before retrying
		} else {
			last; #succesfully woken up, jump out of the loop
		}
	}
}

sub check_crc {
	my $self = shift;
	my $blob = shift; # a binary string received or to be sent
	                  # to the Vantage Pro 2 station, the CRC is at the end

	# Initialization
	my $computed_crc = 0;

	# Compute the CRC on data
	foreach my $data (unpack("C*",$blob))
	{
	   crc_round($data,\$computed_crc);
	}

	if ($computed_crc == 0) { #CRC check passes if crc == 0
		return 1;
	} else {
		return 0;
	}
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
