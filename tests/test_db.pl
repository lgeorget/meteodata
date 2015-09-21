#!/usr/bin/perl
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
#
# In jurisdictions that recognize copyright laws, the author or authors
# of this software dedicate any and all copyright interest in the
# software to the public domain. We make this dedication for the benefit
# of the public at large and to the detriment of our heirs and
# successors. We intend this dedication to be an overt act of
# relinquishment in perpetuity of all present and future rights to this
# software under copyright law.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# For more information, please refer to <http://unlicense.org/>


use strict;
use warnings;

use Meteodata::Storage::DbConnection;

my $db = Meteodata::Storage::DbConnection->new(
	table => 'stations',
	user => 'cassandra',
	host => 'localhost',
	keyspace => 'meteodata',
);

my %data;

$data{'Bar Trend'} = 'Steady';
$data{'Barometer'} = 0;
$data{'Inside Temperature'} = 1;
$data{'Inside Humidity'} = 2;
$data{'Outside Temperature'} = 3;
$data{'Outside Humidity'} = 4;
$data{'Extra Temperatures'}[0] = 5;
$data{'Extra Temperatures'}[1] = 6;
$data{'Extra Temperatures'}[2] = 7;
$data{'Extra Temperatures'}[3] = 8;
$data{'Extra Temperatures'}[4] = 9;
$data{'Extra Temperatures'}[5] = 10;
$data{'Extra Temperatures'}[6] = 11;
$data{'Soil Temperature'}[0] = 12;
$data{'Soil Temperature'}[1] = 13;
$data{'Soil Temperature'}[2] = 14;
$data{'Soil Temperature'}[3] = 1;
$data{'Leaf Temperature'}[0] = 3;
$data{'Leaf Temperature'}[1] = 5;
$data{'Leaf Temperature'}[2] = 7;
$data{'Leaf Temperature'}[3] = 9;
$data{'Extra Humidities'}[0] = 11;
$data{'Extra Humidities'}[1] = 13;
$data{'Extra Humidities'}[2] = 15;
$data{'Extra Humidities'}[3] = 17;
$data{'Extra Humidities'}[4] = 19;
$data{'Extra Humidities'}[5] = 21;
$data{'Extra Humidities'}[6] = 23;
$data{'Soil Moistures'}[0] = 25;
$data{'Soil Moistures'}[1] = 27;
$data{'Soil Moistures'}[2] = 29;
$data{'Soil Moistures'}[3] = 31;
$data{'Leaf Wetnesses'}[0] = 33;
$data{'Leaf Wetnesses'}[1] = 35;
$data{'Leaf Wetnesses'}[2] = 37;
$data{'Leaf Wetnesses'}[3] = 39;
$data{'Wind Speed'} = 41;
$data{'Wind Direction'} = 43;
$data{'10-Min Avg Wind Speed'} = 45;
$data{'2-Min Avg Wind Speed'} = 47;
$data{'10-Min Wind Gust'} = 49;
$data{'Wind Direction for the 10-Min Wind Gust'} = 51;
$data{'Rain Rate'} = 53;
$data{'Last 15-min Rain'} = 55;
$data{'Last Hour Rain'} = 57;
$data{'Last 24-Hour Rain'} = 59;
$data{'Day Rain'} = 61;
$data{'Month Rain'} = 63;
$data{'Year Rain'} = 65;
$data{'Storm Rain'} = 67;
$data{'Start Date of Current Storm'} = 69;
$data{'UV'} = 71;
$data{'Solar Radiation'} = 73;
$data{'Dew Point'} = 75;
$data{'Heat Index'} = 77;
$data{'Wind Chill'} = 79;
$data{'THSW Index'} = 81;
$data{'Day ET'} = 83;
$data{'Month ET'} = 85;
$data{'Year ET'} = 87;
$data{'Time Sunrise'} = 89;
$data{'Time Sunset'} = 91;
$data{'Console Battery Voltage'} = 93;


print "Connected? \n";
$db->connect('cassandra');
$db->add_new_data('11111111-2222-3333-4444-555555555555',\%data);
$db->discover_stations;
