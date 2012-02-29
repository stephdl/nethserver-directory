package NethServer::Directory;

use strict;

use Net::LDAP;
use Authen::SASL;

#
# Connection setup
#
sub bindLdap
{
    my $LDAPURL = shift || 'ldapi://';
    my $Ldap = Net::LDAP->new($LDAPURL) or die("Can't connect $LDAPURL");
    my $sasl = Authen::SASL->new(mechanism=>'EXTERNAL');   
    $Ldap->bind(anonymous=>0, sasl => $sasl) or die ("Can't bind to $LDAPURL");
    return $Ldap;
}

1;
