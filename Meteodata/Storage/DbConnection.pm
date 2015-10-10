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
	$Meteodata::Storage::db->close_when_idle->get;
}

sub DEMOLISH {
	my $self = shift;
	$self->disconnect;
}

sub add_new_data {
	my ($self,$id,$data) = @_;
	my $now = time;
	print "Inserting data in $id at time $now";
	my $put_stmt = $Meteodata::Storage::db->prepare("
	INSERT INTO meteo (
	station,time,
	bartrend,barometer,barometer_abs,barometer_raw,
	insidetemp,outsidetemp,
	insidehum,outsidehum,
	extratemp1,extratemp2, extratemp3,
	extratemp4, extratemp5, extratemp6,
	extratemp7, soiltemp1, soiltemp2,
	soiltemp3, soiltemp4, leaftemp1,
	leaftemp2, leaftemp3, leaftemp4,
	extrahum1, extrahum2, extrahum3,
	extrahum4, extrahum5, extrahum6,
	extrahum7, soilmoistures1, soilmoistures2,
	soilmoistures3, soilmoistures4, leafwetnesses1, leafwetnesses2,
	leafwetnesses3, leafwetnesses4, windspeed, winddir,
	avgwindspeed_10min, avgwindspeed_2min,
	windgust_10min, windgustdir,
	rainrate, rain_15min, rain_1h, rain_24h,
	dayrain, monthrain, yearrain, stormrain, stormstartdate,
	UV, solarrad, dewpoint, icepoint, heatindex, windchill, thswindex,
	dayET, monthET, yearET,
	sunrise, sunset
	)
	VALUES (
	$id,$now,
	'$data->{'Bar Trend'}',$data->{'Barometer'},
	$data->{'Absolute Barometric Pressure'},$data->{'Barometric Sensor Raw Reading'},
	$data->{'Inside Temperature'},$data->{'Outside Temperature'},
	$data->{'Inside Humidity'},$data->{'Outside Humidity'},
	$data->{'Extra Temperatures'}[0], $data->{'Extra Temperatures'}[1],
	$data->{'Extra Temperatures'}[2], $data->{'Extra Temperatures'}[3],
	$data->{'Extra Temperatures'}[4], $data->{'Extra Temperatures'}[5],
	$data->{'Extra Temperatures'}[6],
	$data->{'Soil Temperature'}[0], $data->{'Soil Temperature'}[1],
	$data->{'Soil Temperature'}[2], $data->{'Soil Temperature'}[3],
	$data->{'Leaf Temperature'}[0], $data->{'Leaf Temperature'}[1],
	$data->{'Leaf Temperature'}[2], $data->{'Leaf Temperature'}[3],
	$data->{'Extra Humidities'}[0], $data->{'Extra Humidities'}[1],
	$data->{'Extra Humidities'}[2], $data->{'Extra Humidities'}[3],
	$data->{'Extra Humidities'}[4], $data->{'Extra Humidities'}[5],
	$data->{'Extra Humidities'}[6],
	$data->{'Soil Moistures'}[0], $data->{'Soil Moistures'}[1],
	$data->{'Soil Moistures'}[2], $data->{'Soil Moistures'}[3],
	$data->{'Leaf Wetnesses'}[0], $data->{'Leaf Wetnesses'}[1],
	$data->{'Leaf Wetnesses'}[2], $data->{'Leaf Wetnesses'}[3],
	$data->{'Wind Speed'}, $data->{'Wind Direction'},
	$data->{'10-Min Avg Wind Speed'}, $data->{'2-Min Avg Wind Speed'},
	$data->{'10-Min Wind Gust'},
	$data->{'Wind Direction for the 10-Min Wind Gust'},
	$data->{'Rain Rate'}, $data->{'Last 15-min Rain'},
	$data->{'Last Hour Rain'}, $data->{'Last 24-Hour Rain'},
	$data->{'Day Rain'}, $data->{'Month Rain'}, $data->{'Year Rain'},
	$data->{'Storm Rain'}, $data->{'Start Date of Current Storm'},
	$data->{'UV'}, $data->{'Solar Radiation'}, $data->{'Dew Point'},
	$data->{'Ice Point'}, $data->{'Heat Index'},
	$data->{'Wind Chill'}, $data->{'THSW Index'},
	$data->{'Day ET'}, $data->{'Month ET'}, $data->{'Year ET'},
	$data->{'Time Sunrise'}, $data->{'Time Sunset'}
	)");
	my ($type, $result) = $put_stmt->get->execute([])->get;

	$put_stmt = $Meteodata::Storage::db->prepare("
	UPDATE stations SET
	altimeter_setting = $data->{'Altimeter Setting'},
	barometer_reduction_method = $data->{'Barometric Reduction Method'},
	barometric_calibration = $data->{'Barometric calibration number'},
	barometric_offset = $data->{'User-entered Barometric Offset'}
	WHERE id = $id");
	my ($type, $result) = $put_stmt->get->execute([])->get;
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
