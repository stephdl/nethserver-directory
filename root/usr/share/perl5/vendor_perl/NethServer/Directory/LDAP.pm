package NethServer::Directory::LDAP;

use strict;

use Net::LDAP;
use Authen::SASL;
use esmith::ConfigDB;
use List::MoreUtils qw(uniq);
use Data::Dumper;

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
	warn join(' ', $result->error_name(), $result->error());
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
	my $updateResult;
	#
	# loop on $searchResult, replace string values, append list values
	#
	foreach my $entry ($searchResult->entries()) {
	    my %updateAttributes = @{$arg->{'merge'}};
	    my %mergedAttributes = ();


	    foreach my $key ( keys(%updateAttributes) ) {
		# skip 'dn' key:
		if($key eq 'dn') {
		    next;
		}
			       
		if(ref $updateAttributes{$key} eq 'SCALAR' || !$entry->exists($key)) {
		    # Scalar values and new values (of any type) 
		    # are fully replaced:
		    $mergedAttributes{$key} = $updateAttributes{$key};
		} elsif(ref $updateAttributes{$key} eq 'ARRAY') {
		    # New array value is concatenated with the old value
		    # removing duplicate items
		    my %h = map { $_ => 1 } @{[($entry->get_value($key)), @{$updateAttributes{$key}}]};		    
		    $mergedAttributes{$key} = [keys %h];
		}
	    }

	    $entry->replace(%mergedAttributes);
	    $updateResult = $entry->update($self);
	    if($updateResult->is_error()) {
		$message = $updateResult;
	    }
	}
		
	# If not defined at this point, set $message to the last $updateResult
	if(! defined $message) {
	    $message = $updateResult;
	}
    }

    return $message;
}

1;
