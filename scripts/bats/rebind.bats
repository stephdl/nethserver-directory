setup ()
{
    load setup_global
}



@test "rebind libuser builtin external TLS bind" {
    run perl rebind.pl -- ${HOSTNAME} cn=libuser,${BUILTIN_SUFFIX} $(cat /var/lib/nethserver/secrets/libuser) starttls
    [[ $status == 0 ]]
}

@test "rebind libuser domain external TLS bind" {
    run perl rebind.pl -- ${HOSTNAME} cn=libuser,${DOMAIN_SUFFIX} $(cat /var/lib/nethserver/secrets/libuser) starttls
    [[ $status == 0 ]]
}

@test "rebind bind fail, libuser builtin external, require TLS" {
    run perl rebind.pl -- ${HOSTNAME} cn=libuser,${BUILTIN_SUFFIX} $(cat /var/lib/nethserver/secrets/libuser)
    [[ $status != 0 ]]
}

@test "rebind bind fail, libuser domain external, require TLS" {
    run perl rebind.pl -- ${HOSTNAME} cn=libuser,${DOMAIN_SUFFIX} $(cat /var/lib/nethserver/secrets/libuser)
    [[ $status != 0 ]]
}

@test "rebind libuser builtin local bind" {
    run perl rebind.pl -- ${LOCALHOST} cn=libuser,${BUILTIN_SUFFIX} $(cat /var/lib/nethserver/secrets/libuser)
    [[ $status == 0 ]]
}

@test "rebind libuser domain local bind" {
    run perl rebind.pl -- ${LOCALHOST} cn=libuser,${DOMAIN_SUFFIX} $(cat /var/lib/nethserver/secrets/libuser)
    [[ $status == 0 ]]
}

