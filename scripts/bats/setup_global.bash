
export DOMAIN_SUFFIX=$(perl -MNethServer::Directory -e 'print NethServer::Directory::getDomainSuffix();')
export BUILTIN_SUFFIX="dc=directory,dc=nh"
export HOSTNAME=${HOSTNAME:-$(hostname)}
export LOCALHOST=127.0.0.1
