#!/usr/bin/env bats

#
# prerequisite: install bats from EPEL; on NethServer 7
#
#    yum install bats
#

setup ()
{
    load setup_global
}

@test "bind with wrong suffix success, builtin domain tls remote" {
    run ldapsearch -x -Z -h ${HOSTNAME} -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${BUILTIN_SUFFIX} -b ${DOMAIN_SUFFIX} '(!(cn=ldapservice))'
    [[ $output == *simpleSecurityObject* ]]
}

@test "bind with wrong suffix success, domain builtin tls remote" {
    run ldapsearch -x -Z -h ${HOSTNAME} -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${DOMAIN_SUFFIX} -b ${BUILTIN_SUFFIX} '(!(cn=ldapservice))'
    [[ $output == *simpleSecurityObject* ]]
}

@test "bind with wrong suffix success, builtin domain localhost" {
    run ldapsearch -x -h ${LOCALHOST} -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${BUILTIN_SUFFIX} -b ${DOMAIN_SUFFIX} '(!(cn=ldapservice))'
    [[ $output == *simpleSecurityObject* ]]
}

@test "bind with wrong suffix success, domain builtin localhost" {
    run ldapsearch -x -h ${LOCALHOST} -w $(cat /var/lib/nethserver/secrets/ldapservice) -D cn=ldapservice,${DOMAIN_SUFFIX} -b ${BUILTIN_SUFFIX} '(!(cn=ldapservice))'
    [[ $output == *simpleSecurityObject* ]]
}