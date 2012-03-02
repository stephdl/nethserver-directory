package NethServer::Directory::LDAP;

use strict;

use Net::LDAP;
use Authen::SASL;
use esmith::ConfigDB;

use Data::Dumper;

our @ISA = qw(Net::LDAP);

#
# Connection setup
#
sub new 
{
    my $class = shift;
    my $url = shift || 'ldapi://';
    my $self = $class->SUPER::new($url, @_) or return undef;

    if($url eq 'ldapi://') {
	$self->bind;
    }

    bless ($self, $class);
    return $self;
}

sub bind
{
    my $self = shift;
    my $sasl = Authen::SASL->new(mechanism=>'EXTERNAL');
    return $self->SUPER::bind(anonymous=>0, sasl => $sasl);
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
