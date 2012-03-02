package NethServer::Directory;

use esmith::ConfigDB;

sub getDomainSuffix
{
    my $ConfigDb = esmith::ConfigDB->open_ro();
    my $DomainName = $ConfigDb->get_value('DomainName');
    $DomainName =~ s/\./,dc=/g;
    return "dc=" . $DomainName;
}

sub getInternalSuffix
{
    return 'dc=directory,dc=nh';
}

sub getUserPassword
{
    my $user = shift;
    my $crypt = shift;
    my $ldap = shift;

    my $cryptSaltFormat = getCryptSaltFormat($ldap);
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
    my $ldap = shift;

    # Default value, if cannot contact LDAP server
    my $default = '$6$%.86s';

    if(ref $ldap ne 'NethServer::Directory::LDAP') {
	return $default;
    }

    my $searchResponse = $ldap->search(
	base => 'cn=config',
	filter => 'objectClass=*',
	scope => 'base',
	attributes => ['olcPasswordCryptSaltFormat'],
	sizelimit => 1
	);

    if($searchResponse->is_error) {
	warn "Could not retrieve password salt format, using `$default`: " . 
	    $searchResponse->error_name;
	return $default;
    }

    return $searchResponse->entry(0)->get_value('olcPasswordCryptSaltFormat') || $default;
}

1;
