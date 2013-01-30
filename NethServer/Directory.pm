package NethServer::Directory;

use strict;
use esmith::ConfigDB;
use NethServer::Directory::LDAP;
use Net::LDAP::LDIF;
use Carp;

use Exporter qw(import);

use constant PASSWORD_READ => 0x02;
use constant PASSWORD_WRITE => 0x08;
use constant FIELDS_READ => 0x01;
use constant FIELDS_WRITE => 0x04;

our @ISA = qw(NethServer::Directory::LDAP);
our @EXPORT_OK = qw(PASSWORD_READ PASSWORD_WRITE FIELDS_READ FIELDS_WRITE);

sub domain2suffix
{
    my $domain = shift;   
    $domain =~ s/\./,dc=/g; 
    return "dc=" . $domain;
}

sub getDomainSuffix
{
    my $ConfigDb = esmith::ConfigDB->open_ro();
    return domain2suffix($ConfigDb->get_value('DomainName'));
}

sub getInternalDomain
{
    return 'directory.nh';        
}

sub getInternalSuffix
{
    return domain2suffix(getInternalDomain());
}

sub getUserPassword
{
    my $user = shift;
    my $crypt = shift;

    my $cryptSaltFormat = getCryptSaltFormat();
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
    return '$6$%.86s';
}

sub connect
{
    return NethServer::Directory::LDAP->new;
}

sub addAccessDirective ($$)
{
    my $directive = shift;
    my $field = shift;

    my $ldap = NethServer::Directory->new();
    
    return $ldap->_addAccessDirective($directive, $field);   
}

=head2 new

Create a NethServer::Directory instance as a subclass of Net::LDAP
package.  The returned object has already bind()ed to the internal
LDAP server.

=cut
sub new
{
    my $class = shift;
    my $self = $class->SUPER::new();
    return $self;
}

=head2 getUser(UID)

Return a Net::LDAP::Entry object for the given UID, or undef if not
found.

=cut
sub getUser($)
{
    my $self = shift;
    my $uid = shift;

    return $self->search(
	base => 'ou=People, ' . NethServer::Directory::getInternalSuffix(),
	scope => 'one',
	filter => sprintf('(&(objectClass=PosixAccount)(uid=%s))', $uid),
	)->pop_entry();
}

=head2 configServiceAccount

Append a simpleSecurityObject+device node for simple BINDs from localhost.

Example:
   
    $ldap->configServiceAccount('sogo', PASSWORD_READ | FIELDS_READ);

=cut
sub configServiceAccount
{
    my $self = shift;
    my $account = shift;
    my $access = shift;
    my $errors = 0;

    my $internalSuffix = getInternalSuffix();

    my $ldapAccessDirective = 'by dn.exact="cn=' . $account . ','. $internalSuffix . '" peername.ip="127.0.0.1" ';

    if($access & PASSWORD_WRITE) {
	$self->_addAccessDirective($ldapAccessDirective . 'write', 'userPassword') 
    } elsif($access & PASSWORD_READ) {
	$self->_addAccessDirective($ldapAccessDirective . 'read', 'userPassword') 
    }

    if($access & FIELDS_WRITE) {
	$self->_addAccessDirective($ldapAccessDirective . 'write', '*') 
    } elsif($access & FIELDS_READ) {
	$self->_addAccessDirective($ldapAccessDirective . 'read', '*') 
    }

    # Create cn=account,dc=directory,dc=nh ldap entry

    my $cryptPassword = getUserPassword($account, 1);

    my @entries = (
        [ 'cn=' . $account . ',' . $internalSuffix,
          attrs => [
              objectClass => ['device', 'simpleSecurityObject'],
              cn => $account,
              userPassword => $cryptPassword,
              description => $account . ' management account'
          ] 
        ]
    );

    foreach(@entries) {
        my $message = $self->merge(@{$_});
        if($message->is_error()) {
            carp 'error merging ' . $_[0];
            $errors ++;
        }
    }

    return $errors == 0 ? 1 : 0;
}

#
# Modify LDAP ACLs. see slapd.access(5)
#
sub _addAccessDirective
{
    my $self = shift;
    my $directive = shift;
    my $field = shift;

    my $internalSuffix = getInternalSuffix();

    my $configSearch = $self->search(
	base => "cn=config",
	filter => "(&(olcSuffix=$internalSuffix)(objectClass=olcBdbConfig))",
	sizelimit => 1,
	scope => 'one'
	);

    if($configSearch->is_error()) {	
	carp "Cannot find `$internalSuffix` subtree";
	return 0;
    }
    
    my $configEntry = $configSearch->pop_entry();
    
    if($configEntry) {

	my @olcAccess = $configEntry->get_value('olcAccess');
       
	if($field ne '*') {
	    $field = 'attrs=' . $field;
	}

	foreach(@olcAccess) {
	    if (m/to \Q$field\E/s && ! m/\Q$directive\E/) {
		s/ manage/ manage $directive/;
	    }
	}
	
	# print Dumper([@olcAccess]);	    
	my $message = $self->modify(
	    $configEntry->dn(),
	    replace => [
		olcAccess => [@olcAccess]
	    ]);
	
	if($message->is_error()) {    	
	    carp '';
	} else {
	    # success
	    return 1;
	}
    } 
    
    return 0;

}

1;
