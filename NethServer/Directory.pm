#
# Copyright (C) 2012 Nethesis S.r.l.
# http://www.nethesis.it - support@nethesis.it
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
# along with NethServer.  If not, see <http://www.gnu.org/licenses/>.
#

package NethServer::Directory;

use strict;
use esmith::ConfigDB;
use NethServer::Directory::LDAP;
use NethServer::Password;
use IPC::Open2;
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

    if($crypt) {
	warn '[ERROR] the crypt argument is no longer supported';
    }

    return NethServer::Password::store($user);
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
    
    return $ldap->enforceAccessDirective($directive, $field);   
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
    my $from = shift;
    my $errors = 0;

    my $internalSuffix = getInternalSuffix();

    if( ! $from) {
	$from = 'peername.ip="127.0.0.1"';
    }

    my $ldapAccessDirective = 'by dn.exact="cn=' . $account . ','. $internalSuffix . '" ' . $from . ' ' ;

    if($access & PASSWORD_WRITE) {
	$self->enforceAccessDirective($ldapAccessDirective . 'write', 'userPassword') 
    } elsif($access & PASSWORD_READ) {
	$self->enforceAccessDirective($ldapAccessDirective . 'read', 'userPassword') 
    }

    if($access & FIELDS_WRITE) {
	$self->enforceAccessDirective($ldapAccessDirective . 'write', '*') 
    } elsif($access & FIELDS_READ) {
	$self->enforceAccessDirective($ldapAccessDirective . 'read', '*') 
    }

    # Create cn=account,dc=directory,dc=nh ldap entry

    my $password = NethServer::Password::store("/var/lib/nethserver/secrets/" . $account);

    # glibc SHA-512 salt format:
    my $cryptSaltFormat = '$6$%.86s';
    my $pid = open2(\*COUT, \*CIN, qw(/usr/sbin/slappasswd -u -T /dev/stdin -c), $cryptSaltFormat);
    print CIN "$password"; close(CIN);
    my $cryptPassword = <COUT> ;
    chomp($cryptPassword);	
    waitpid($pid, 0);
    if($?) {
	warn "[ERROR] slappasswd failed. $?\n";
	$cryptPassword="";
	$errors++;
    }

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
sub enforceAccessDirective
{
    my $self = shift;
    my $directive = shift;
    my $field = shift;
    my $errors = 0;

    my $internalSuffix = getInternalSuffix();
    my $domainSuffix = getDomainSuffix();

    my $configSearch = $self->search(
	base => "cn=config",
	filter => "(&(objectClass=olcDatabaseConfig)(|(olcSuffix=$internalSuffix)(olcSuffix=$domainSuffix)))",
	sizelimit => 2,
	scope => 'one'
	);

    if($configSearch->is_error()) {	
	carp "[ERROR] Configuration databases search error.\n";
	return 0;
    }

    if($field ne '*') {
	$field = 'attrs=' . $field;
    }
   
    foreach my $configEntry ($configSearch->entries()) {    
	my @olcAccess = $configEntry->get_value('olcAccess');
       
	# Remove multivalued attribute sort order:
	foreach(@olcAccess) {
	    s/^\{\d+\}to /to /;
	}

	if(grep(m/to \Q$field\E/s, @olcAccess)) {
	    # Tweak existing $field ACL:
	    foreach(@olcAccess) {
		if (m/to \Q$field\E/s && ! m/\Q$directive\E/) {
		    s/ manage/ manage $directive/;
		}
	    }
	} else {
	    # Prepend a new olcAccess entry specific $field,
	    # initializing root access to "manage":
	    unshift @olcAccess, join(' ', 
				     qq(to $field by dn.exact="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage),
				     $directive
		);
	}

	# CLEANUP: use Data::Dumper;
	# print Dumper([@olcAccess]);	    
	my $message = $configEntry->replace(
	    olcAccess => \@olcAccess
	    )->update($self);
       	
	if($message->is_error()) {    	
	    carp 'Failed to update ' . $configEntry->dn . "\n";
	    $errors ++;
	}     
    }
    
    return ($errors == 0 ? 1 : 0);

}

=head2 getFreeId($base)

Search the passwd and group databases for the first free user-id,
starting from $base. 

The returned id is a free uid, gid couple.

=cut
sub getFreeId($)
{
    # This function is derived from esmith::AccountsDB::get_next_uid()

    my $self = shift;
    my $base = shift;

    if( ! $base ) {
	$base = 500;
    }

    my $id = $base;
    my $maxid = 1 << 31;

    setpwent();
    setgrent();

    # Increment $id counter until a free value is found for both
    # passwd and group databases:
    while (getpwuid $id || getgrgid $id)
    {
	if ($id == $maxid) {
	    die "[ERROR] All userids in use!";
	}
        $id++;
    }

    endpwent();
    endgrent();

    return $id;    

}

=head2 addGroupMembers($groupName, @members..)

Add the given @members to $groupName

=cut
sub addGroupMembers
{
    my $self = shift;
    my $groupName = shift;

    my $search = $self->search(base => "ou=Groups," . getInternalSuffix(),
			       filter => "(&(cn=$groupName)(objectClass=posixGroup))");

    if($search->is_error() || $search->count() == 0) {
	return 0;
    }

    my $entry = $search->entry(0);
    my %members = map { $_ ? ($_ => 1) : () } ($entry->get_value('memberUid'), @_);

    $entry->replace('memberUid', [ keys %members ]);

    return ! $entry->update($self)->is_error();
}

=head2 delGroupMembers($groupName, @members..)

Remove the given @members from $groupName

=cut
sub delGroupMembers
{
    my $self = shift;
    my $groupName = shift;

    my $search = $self->search(base => "ou=Groups," . getInternalSuffix(),
			       filter => "(&(cn=$groupName)(objectClass=posixGroup))");

    if($search->is_error() || $search->count() == 0) {
	return 0;
    }

    $search->entry(0)->del(memberUid => [@_]);
    return ! $search->entry(0)->update()->is_error();
}

=head2 setGroupMembers($groupName, @members..)

Set the members of $groupName to the given list

=cut
sub setGroupMembers
{
    my $self = shift;
    my $groupName = shift;

    my $search = $self->search(base => "ou=Groups," . getInternalSuffix(),
			       filter => "(&(cn=$groupName)(objectClass=posixGroup))");

    if($search->is_error() || $search->count() == 0) {
	return 0;
    }

    my $entry = $search->entry(0);
    my %members = map { $_ ? ($_ => 1) : () } @_;

    $entry->replace('memberUid', [ keys %members ]);

    return ! $entry->update($self)->is_error();
}

1;
