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

@test "read userPassword field, anonymous builtin external TLS bind" {
  run ldapsearch -Z -w '' -D '' -x -b ${BUILTIN_SUFFIX} -h ${HOSTNAME}
  [[ $output == *organizationalUnit* ]]
  [[ ! $output == *userPassword* ]]
}

@test "read userPassword field, anonymous domain external TLS bind" {
  run ldapsearch -Z -w '' -D '' -x -b ${DOMAIN_SUFFIX} -h ${HOSTNAME}
  [[ $output == *organizationalUnit* ]]
  [[ ! $output == *userPassword* ]]
}

@test "read userPassword field, anonymous builtin local bind" {
  run ldapsearch -w '' -D '' -x -b ${BUILTIN_SUFFIX} -h ${LOCALHOST}
  [[ $output == *organizationalUnit* ]]
  [[ ! $output == *userPassword* ]]
}

@test "read userPassword field, anonymous domain local bind" {
  run ldapsearch -w '' -D '' -x -b ${DOMAIN_SUFFIX} -h ${LOCALHOST}
  [[ $output == *organizationalUnit* ]]
  [[ ! $output == *userPassword* ]]
}

