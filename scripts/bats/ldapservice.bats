#!/usr/bin/env bats

#
# prerequisite: install bats from EPEL; on NethServer 7
#
#    yum install bats
# 

setup ()
{
    export DOMAIN_SUFFIX=$(perl -MNethServer::Directory -e 'print NethServer::Directory::getDomainSuffix();')
    export BUILTIN_SUFFIX="dc=directory,dc=nh"
    export HOSTNAME=${HOSTNAME:-$(hostname)}
    export LOCALHOST=127.0.0.1
}

@test "read userPassword field, ldapservice builtin external TLS bind" {
  run ldapsearch -Z -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${BUILTIN_SUFFIX} -b ${BUILTIN_SUFFIX} -h ${HOSTNAME} '(!(cn=ldapservice))'
  [[ $output == *simpleSecurityObject* ]]
  [[ ! $output == *userPassword* ]]
}

@test "read userPassword field, ldapservice domain external TLS bind" {
  run ldapsearch -Z -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${DOMAIN_SUFFIX} -b ${DOMAIN_SUFFIX} -h ${HOSTNAME} '(!(cn=ldapservice))'
  [[ $output == *simpleSecurityObject* ]]
  [[ ! $output == *userPassword* ]]
}

@test "bind fail, ldapservice builtin external noTLS bind" {
  run ldapsearch -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${BUILTIN_SUFFIX} -b ${BUILTIN_SUFFIX} -h ${HOSTNAME} '(!(cn=ldapservice))'
  [[ $status != 0 ]]
  [[ $output == *"Invalid credentials"* ]]
}

@test "bind fail, ldapservice domain external noTLS bind" {
  run ldapsearch -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${DOMAIN_SUFFIX} -b ${DOMAIN_SUFFIX} -h ${HOSTNAME} '(!(cn=ldapservice))'
  [[ $status != 0 ]]
  [[ $output == *"Invalid credentials"* ]]
}


@test "read userPassword field, ldapservice builtin local bind" {
  run ldapsearch -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${BUILTIN_SUFFIX} -b ${BUILTIN_SUFFIX} -h ${LOCALHOST} '(!(cn=ldapservice))'
  [[ $output == *simpleSecurityObject* ]]
  [[ ! $output == *userPassword* ]]
}

@test "read userPassword field, ldapservice domain local bind" {
  run ldapsearch -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${DOMAIN_SUFFIX} -b ${DOMAIN_SUFFIX} -h ${LOCALHOST} '(!(cn=ldapservice))'
  [[ $output == *simpleSecurityObject* ]]
  [[ ! $output == *userPassword* ]]
}

