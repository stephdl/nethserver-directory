package NethServer::Directory;

use esmith::ConfigDB;
use NethServer::Directory::LDAP;

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

    my $ldap = NethServer::Directory::connect();
    my $internalSuffix = NethServer::Directory::getInternalSuffix();
    my $exitCode = 0;

    my $configSearch = $ldap->search(
	base => "cn=config",
	filter => "(&(olcSuffix=$internalSuffix)(objectClass=olcBdbConfig))",
	sizelimit => 1,
	scope => 'one'
	);

    if($configSearch->is_error()) {	
	warn "Cannot find `$internalSuffix` subtree";
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
	my $message = $ldap->modify(
	    $configEntry->dn(),
	    replace => [
		olcAccess => [@olcAccess]
	    ]);
	
	if($message->is_error()) {    	
	    warn '';
	} else {
	    # success
	    return 1;
	}
    } 
    
    return 0;
   
}

1;
