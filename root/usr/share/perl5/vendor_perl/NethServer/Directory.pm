package NethServer::Directory;

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
    $DomainName =~ s/\./,dc=/g;
    return "dc=" . $DomainName;
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

sub getUserPassword
{
    my $self = shift;
    my $user = shift;
    my $crypt = shift;

    my $cryptSaltFormat = $self->getCryptSaltFormat;   
    my $file;

    if($user eq 'pam') {
	#
	# pam_ldap read the "secret" file for rootbinddb password
	# see pam_ldap(5) for details
	#
	$file = '/etc/pam_ldap.secret';
    } else {
	$file = '/etc/openldap/.' . $user . '.pw';
    }

    my $password;

    if(not -e $file) {
	my $umask = umask 0177;
	`slappasswd -n -g > $file`;
	umask $umask;
    }

    if($crypt) {
	$password = `slappasswd -n -u -c '$cryptSaltFormat' -T $file`;
	chomp($password);	
    } else {
	open(FH, $file);
	$password = <FH>;
	chomp($password);
	close(FH);
    }

    return $password;
}

sub getCryptSaltFormat 
{
    my $self = shift;

    my $default = '$6$%.86s';

    my $searchResponse = $self->search(
	base => 'cn=config',
	filter => 'objectClass=*',
	scope => 'base',
	attributes => ['olcPasswordCryptSaltFormat'],
	sizelimit => 1
	);

    if($searchResponse->is_error) {
	warn 'Could not retrieve password salt format: ' . $searchResponse->error_name;
	return $default;
    }

    return $searchResponse->entry(0)->get_value('olcPasswordCryptSaltFormat') || $default;
}

1;
