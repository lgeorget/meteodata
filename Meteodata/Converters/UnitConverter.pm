# Copyright (C) 2015  Georget, Laurent <laurent@lgeorget.eu>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Meteodata::Converters::UnitConverter;

use Exporter;

@EXPORT_OK = qw/inHg_to_bar degreesF_to_C mph_to_mps in_to_mm/;

sub inHg_to_bar {
	# inches of mercury to bar
	return $_[0] * 0.03386;
}

sub degreesF_to_C {
	# degrees Farenheit to degrees Celsius
	return ($_[0] - 32.0) / 1.80;
}

sub mph_to_mps {
	# miles per hour to meters per second
	return $_[0] * 0.44704;
}

sub in_to_mm {
	# inches to mm
	return $_[0] * 25.4;
}




1;

__END__
