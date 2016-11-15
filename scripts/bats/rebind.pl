
#
# Copyright (C) 2016 Nethesis S.r.l.
# http://www.nethesis.it - nethserver@nethesis.it
#
# This script is part of NethServer.
#
# NethServer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or any later version.
#
# NethServer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NethServer.  If not, see COPYING.
#

# BIND anonymously then BIND with supplied credentials. This is the typical behavior of
# Apache mod_ldap and other applications.

use strict;
use Net::LDAP;

my $errors = 0;
my $response = undef;
my ($cmd, $host, $dn, $password, $starttls) = @ARGV;

if( ! defined $host || ! defined $dn || ! defined $password) {
    die("Required arguments: host dn password [starttls]\n");
}

my $ldap = Net::LDAP->new($host, 'async' => 0, 'onerror' => 'warn', 'debug' => 0);

if($starttls) {
    $response = $ldap->start_tls('verify' => 'none');
    if($response->is_error()) {
        $errors ++;
        print "[ERROR] STARTTLS failed\n";
    }
}

$response = $ldap->bind('anonymous' => 1);
if($response->is_error()) {
    print "[ERROR] anonymous bind failed\n";
    $errors ++;
}

$response = $ldap->bind($dn, 'password' => $password);
if($response->is_error()) {
    print "[ERROR] authenticated bind failed for $dn\n";
    $errors ++;
}

$ldap->unbind();

exit($errors);
