Configuration of ppolicy, see:
```
  man slapo-ppolicy
```

Reference: https://tobrunet.ch/articles/openldap-password-policy-overlay/

To configure the server, copy the directory and execute:
```
./load_ppolicy

ldapmodify -Y EXTERNAL -a <<EOF
dn: ou=Policies,dc=directory,dc=nh
ou: Policies
objectClass: organizationalUnit

dn: cn=passwordDefault,ou=Policies,dc=directory,dc=nh
objectClass: pwdPolicy
objectClass: person
objectClass: top
cn: passwordDefault
sn: passwordDefault
pwdAttribute: userPassword
pwdCheckQuality: 0
pwdMinAge: 0
pwdMaxAge: 0
pwdMinLength: 8
pwdInHistory: 5
pwdMaxFailure: 3
pwdFailureCountInterval: 0
pwdLockout: TRUE
pwdLockoutDuration: 0
pwdAllowUserChange: TRUE
pwdExpireWarning: 0
pwdGraceAuthNLimit: 0
pwdMustChange: FALSE
pwdSafeModify: FALSE
EOF
```

Add this line under the domain section of sssd.conf:
```
ldap_access_order = ppolicy
```


Lock user (giacomo):
```
ldapmodify -Y EXTERNAL -a  <<EOF
dn: uid=giacomo,ou=People,dc=directory,dc=nh
changetype: modify
add: pwdAccountLockedTime
pwdAccountLockedTime: 000001010001Z
EOF
```

Unlock user (giacomo):
```
ldapmodify -Y EXTERNAL -a  <<EOF
dn: uid=giacomo,ou=People,dc=directory,dc=nh
changetype: modify
delete: pwdAccountLockedTime
EOF
```

List of locked users:
```
ldapsearch -Y EXTERNAL -b "ou=People,dc=directory,dc=nh" "pwdAccountLockedTime=*" pwdAccountLockedTime
```
