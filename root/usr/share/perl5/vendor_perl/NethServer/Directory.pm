package NethServer::Directory;

use strict;

use Net::LDAP;
use Authen::SASL;
use esmith::ConfigDB;
use esmith::util;

use Data::Dumper;

our @ISA = qw(Net::LDAP);

#
# Connection setup
#
sub new 
{
    my $class = shift;
    my $url = shift || 'ldapi://';
    my $self = $class->SUPER::new($url, @_) or die("Can't connect $url");

    if($url eq 'ldapi://') {
	$self->bind;
    }

    $self->{ConfigDb} = esmith::ConfigDB->open_ro();

    bless ($self, $class);
    return $self;
}

sub bind
{
    my $self = shift;
    my $sasl = Authen::SASL->new(mechanism=>'EXTERNAL');
    return $self->SUPER::bind(anonymous=>0, sasl => $sasl) or die ("Can't bind to " . $self->uri());
}


sub getDomainSuffix
{
    my $self = shift;
    my $DomainName = $self->{ConfigDb}->get_value('DomainName');
    return esmith::util::ldapBase($DomainName);
}

sub getInternalSuffix
{
    return 'dc=directory,dc=nh';
}

#
# Check if an entry exists then add or modify
#
sub merge
{
    my $self = shift;
    my $arg = Net::LDAP::_dn_options(@_);
    my $message;

    my $searchResult = $self->search(
	base => $arg->{dn},
	filter => 'objectClass=*',
	sizelimit => 1,
	scope => 'base'
	);
   
    if($searchResult->is_error && $searchResult->code() != Net::LDAP::Constant::LDAP_NO_SUCH_OBJECT) {
	$message = $searchResult;
    } elsif($searchResult->count() == 0) {
	$message = $self->add($arg->{dn}, attrs => $arg->{merge});
    } else {
	$message = $self->modify($arg->{dn}, replace => $arg->{merge});
    }

    return $message;
}

1;
