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

@test "read userPassword field, libuser builtin external TLS bind" {
  run ldapsearch -Z -w $(cat /var/lib/nethserver/secrets/libuser) -D cn=libuser,${BUILTIN_SUFFIX} -b ${BUILTIN_SUFFIX} -h ${HOSTNAME} '(cn=ldapservice)'
  [[ $output == *simpleSecurityObject* ]]
  [[ ! $output == *userPassword* ]]
}

@test "read userPassword field, libuser domain external TLS bind" {
  run ldapsearch -Z -w $(cat /var/lib/nethserver/secrets/libuser) -D cn=libuser,${DOMAIN_SUFFIX} -b ${DOMAIN_SUFFIX} -h ${HOSTNAME} '(cn=ldapservice)'
  [[ $output == *simpleSecurityObject* ]]
  [[ ! $output == *userPassword* ]]
}

@test "bind fail, libuser builtin external noTLS bind" {
  run ldapsearch -w $(cat /var/lib/nethserver/secrets/libuser) -D cn=libuser,${BUILTIN_SUFFIX} -b ${BUILTIN_SUFFIX} -h ${HOSTNAME} '(cn=ldapservice)'
  [[ $status != 0 ]]
  [[ $output == *"Invalid credentials"* ]]
}

@test "bind fail, libuser domain external noTLS bind" {
  run ldapsearch -w $(cat /var/lib/nethserver/secrets/libuser) -D cn=libuser,${DOMAIN_SUFFIX} -b ${DOMAIN_SUFFIX} -h ${HOSTNAME} '(cn=ldapservice)'
  [[ $status != 0 ]]
  [[ $output == *"Invalid credentials"* ]]
}

@test "read userPassword field, libuser builtin local bind" {
  run ldapsearch -w $(cat /var/lib/nethserver/secrets/libuser) -D cn=libuser,${BUILTIN_SUFFIX} -b ${BUILTIN_SUFFIX} -h ${LOCALHOST} '(cn=ldapservice)'
  [[ $output == *simpleSecurityObject* ]]
  [[ $output == *userPassword* ]]
}

@test "read userPassword field, libuser domain local bind" {
  run ldapsearch -w $(cat /var/lib/nethserver/secrets/libuser) -D cn=libuser,${DOMAIN_SUFFIX} -b ${DOMAIN_SUFFIX} -h ${LOCALHOST} '(cn=ldapservice)'
  [[ $output == *simpleSecurityObject* ]]
  [[ $output == *userPassword* ]]
}

# ------- WRITE PERMISSIONS TESTS -------------

@test "libuser create user libuserunittest" {
    run luseradd -M libuserunittest
    [[ $status == 0 ]]
    id libuserunittest
}

@test "libuser delete user libuserunittest" {
    run luserdel libuserunittest
    [[ $status == 0 ]]
}

@test "libuser create group libuserunittestg" {
    run lgroupadd libuserunittestg
    [[ $status == 0 ]]
}

@test "libuser delete group libuserunittestg" {
    run lgroupdel libuserunittestg
    [[ $status == 0 ]]
}


