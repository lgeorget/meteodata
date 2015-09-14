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
	my $now = localtime;
	my $put_stmt = $Meteodata::Storage::db->query("
	INSERT INTO meteo (
	station,time,Bar_Trend,Barometer,Inside_Temperature,
	Inside_Humidity,Outside_Humidity,
	Extra_Temperatures_1,Extra_Temperatures_2, Extra_Temperatures_3,
	Extra_Temperatures_4, Extra_Temperatures_5, Extra_Temperatures_6,
	Extra_Temperatures_7, Soil_Temperatures_1, Soil_Temperatures_2,
	Soil_Temperatures_3, Soil_Temperatures_4, Leaf_Temperatures_1,
	Leaf_Temperatures_2, Leaf_Temperatures_3, Leaf_Temperatures_4,
	Extra_Humidities_1, Extra_Humidities_2, Extra_Humidities_3,
	Extra_Humidities_4, Extra_Humidities_5, Extra_Humidities_6,
	Extra_Humidities_7, Soil_Moistures_1, Soil_Moistures_2,
	Soil_Moistures_3, Soil_Moistures_4, Leaf_Wetnesses_1, Leaf_Wetnesses_2,
	Leaf_Wetnesses_3, Leaf_Wetnesses_4, Wind_Speed, Wind_Direction,
	Ten_Min_Avg_Wind_Speed, Two_Min_Avg_Wind_Speed, Ten_Min_Wind_Gust,
	Rain_Rate, Last_15_min_Rain, Last_Hour_Rain, Last_24_Hour_Rain,
	Day_Rain, Month_Rain, Year_Rain, Storm_Rain,
	Start_Date_of_Current_Storm, UV, Solar_Radiation, Dew_Point,
	Heat_Index, Wind_Chill, THSW_Index, Day_ET, Month_ET, Year_ET,
	Time_Sunrise, Time_Sunset, Console_Battery_Voltage
	)
	VALUES (
	$id,$now,
	$data->{'Bar Trend'},$data->{'Barometer'},$data->{'Inside Temperature'},
	$data->{'Inside Humidity'},$data->{'Outside Humidity'},
	$data->{'Extra Temperatures'}[1], $data->{'Extra Temperatures'}[2],
	$data->{'Extra Temperatures'}[3], $data->{'Extra Temperatures'}[4],
	$data->{'Extra Temperatures'}[5], $data->{'Extra Temperatures'}[6],
	$data->{'Extra Temperatures'}[7],
	$data->{'Soil Temperatures'}[1], $data->{'Soil Temperatures'}[2],
	$data->{'Soil Temperatures'}[3], $data->{'Soil Temperatures'}[4],
	$data->{'Leaf Temperatures'}[1], $data->{'Leaf Temperatures'}[2],
	$data->{'Leaf Temperatures'}[3], $data->{'Leaf Temperatures'}[4],
	$data->{'Extra Humidities'}[1], $data->{'Extra Humidities'}[2],
	$data->{'Extra Humidities'}[3], $data->{'Extra Humidities'}[4],
	$data->{'Extra Humidities'}[5], $data->{'Extra Humidities'}[6],
	$data->{'Extra Humidities'}[7],
	$data->{'Soil Moistures'}[1], $data->{'Soil Moistures'}[2],
	$data->{'Soil Moistures'}[3], $data->{'Soil Moistures'}[4],
	$data->{'Leaf Wetnesses'}[1], $data->{'Leaf Wetnesses'}[2],
	$data->{'Leaf Wetnesses'}[3], $data->{'Leaf Wetnesses'}[4],
	$data->{'Wind Speed'}, $data->{'Wind Direction'},
	$data->{'10-Min Avg Wind Speed'}, $data->{'2-Min Avg Wind Speed'},
	$data->{'10-Min Wind Gust'},
	$data->{'Rain Rate'}, $data->{'Last 15-min Rain'},
	$data->{'Last Hour Rain'}, $data->{'Last 24-Hour Rain'},
	$data->{'Day Rain'}, $data->{'Month Rain'}, $data->{'Year Rain'},
	$data->{'Storm Rain'}, $data->{'Start Date of Current Storm'},
	$data->{'UV'}, $data->{'Solar Radiation'}, $data->{'Dew Point'},
	$data->{'Heat Index'}, $data->{'Wind Chill'}, $data->{'THSW Index'},
	$data->{'Day ET'}, $data->{'Month ET'}, $data->{'Year ET'},
	$data->{'Time Sunrise'}, $data->{'Time Sunset'},
	$data->{'Console Battery Voltage'}
	)")->get;
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
