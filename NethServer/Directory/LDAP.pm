package NethServer::Directory::LDAP;

use strict;

use Net::LDAP;
use Authen::SASL;
use esmith::ConfigDB;
use List::MoreUtils qw(uniq);
use Net::LDAP::LDIF;
use Carp;

our @ISA = qw(Net::LDAP);

#
# Connection setup
#
sub new 
{
    my $class = shift;
    my $url = shift || 'ldapi://';
    my %options = @_;
    $options{'async'} = 0;    
    $options{'onerror'} = sub { 
	my $result = shift;
	if($result->code() != Net::LDAP::Constant::LDAP_NO_SUCH_OBJECT) {
	    carp join(' ', $result->dn(), $result->error_name(), $result->error());
	}
	return $result;
    };

    my $self = $class->SUPER::new($url, %options) or return undef;

    # Automatic-bind if url is ldapi://
    if($url eq 'ldapi://') {
	$self->bind;
    }

    bless ($self, $class);
    return $self;
}

sub bind
{
    my $self = shift;
    my $sasl = Authen::SASL->new(mechanism => 'EXTERNAL');
    return $self->SUPER::bind(anonymous => 0, sasl => $sasl);
}

#
# Check if an entry exists then add or modify
#
sub merge
{
    my $self = shift;
    my $dn = shift;
    my $options = Net::LDAP::_options(@_);
    my $message = $self->message('Net::LDAP::Message::Dummy');

    my $searchResult = $self->search(
	base => $dn,
	filter => 'objectClass=*',
	sizelimit => 1,
	scope => 'base'
	);

    if($searchResult->is_error 
       && $searchResult->code() != Net::LDAP::Constant::LDAP_NO_SUCH_OBJECT) {
	return $searchResult;
    } elsif($searchResult->count() == 0) {
	return $self->add($dn, attrs => $options->{attrs});
    } 

    # Refs #1137: null message object as default response.
    my $updateResult = $self->message('Net::LDAP::Message::Dummy');

    #
    # loop on $searchResult, replace string values, append list values
    #
    foreach my $entry ($searchResult->entries()) {
	my %updateAttributes = @{$options->{attrs}};
	my %mergedAttributes = ();

	foreach my $key ( keys(%updateAttributes) ) {		
	    if($entry->exists($key) && ref $updateAttributes{$key} eq 'ARRAY') {
		my @oldValues = sort @{$entry->get_value($key, asref => 1)};
		# New array value is concatenated with the old value
		# removing duplicate items
		my %h = map { $_ => 1 } @oldValues, @{$updateAttributes{$key}};
		my @values = sort keys %h;

		if((scalar @values != scalar @oldValues)
		   || join(':', @values) ne join(':', @oldValues)) {
		    $mergedAttributes{$key} = [@values];
		}
	    } elsif($updateAttributes{$key} ne $entry->get_value($key)) {
		# Scalar values and new values (of any type) 
		# are fully replaced:
		$mergedAttributes{$key} = $updateAttributes{$key};
	    }
	}

	if ( ! scalar %mergedAttributes ) {
	    next;
	}

	$entry->replace(%mergedAttributes);
	$updateResult = $entry->update($self);
	if($updateResult->is_error()) {
	    $message = $updateResult;
	}
    }

    # If not defined at this point, set $message to the last $updateResult
    if( ! defined $message) {
	$message = $updateResult;
    }
    
    return $message;
}



#
# Load a schema file (LDIF format) if it is missing
#
sub loadLdifSchema($)
{
    my $self = shift;
    my $schemaCn = shift;
    my $schemaFile = shift;

    my $response = $self->search(
	base => 'cn=schema,cn=config',
	filter => 'cn=*' . $schemaCn,
	sizelimit => 1,
	scope => 'one',
	);
    
    if($response->count() > 0) {
	return 1;
    }

    if ( ! -r $schemaFile ) {
	warn "The LDIF schema file is not readable: $schemaFile\n";
	return 0;
    }

    my $ldif = Net::LDAP::LDIF->new($schemaFile, "r", onerror => 'undef');

    if ( ! defined $ldif ) {
	warn "Could not parse the LDIF schema file $schemaFile\n";
	return 0;
    }

    my $ldifEntry = $ldif->read_entry();

    $ldifEntry->changetype('add');
    $response = $ldifEntry->update($self);	
    if( $response->is_error()) {
	warn $response->error();	   
	return 0;
    } else {
	warn "Added LDIF $schemaFile schema\n";
    }
    
    return 1;
}

#
# openldap-servers 2.4.23:
# This method will not work on the current config backend. To
# remove a schema
# - remove the file under slap.d/cn=config/cn=schema/
# - restart slapd daemon
#
sub dropSchema($)
{
    my $self = shift;
    my $schemaCn = shift;

    my $response = $self->search(
	base => 'cn=schema,cn=config',
	filter => 'cn=*' . $schemaCn,
	sizelimit => 1,
	scope => 'one',
	);
    
    if($response->count() > 0) {
	my $deleteResponse = $self->delete("cn=*$schemaCn,cn=schema,cn=config");
	if($deleteResponse->is_error()) {
	    return 0;
	}
    }

    return 1;
}


1;
