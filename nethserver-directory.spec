Name: nethserver-directory
Summary: LDAP backend for user and group accounts
Version: 3.4.1
Release: 1%{?dist}
License: GPL
Source0: %{name}-%{version}.tar.gz
BuildArch: noarch
URL: %{url_prefix}/%{name} 

Requires: openldap-clients, openldap-servers
Requires: perl-LDAP
Requires: nethserver-sssd
Requires: jq

BuildRequires: nethserver-devtools

%description
LDAP backend for user and group accounts

%prep
%setup -q

%build

mkdir -p root%{perl_vendorlib}
mv -v NethServer root%{perl_vendorlib}

perl createlinks
%{makedocs}

%install
rm -rf %{buildroot}
(cd root   ; find . -depth -not -name '*.orig' -print  | cpio -dump %{buildroot})
%{genfilelist} %{buildroot} | \
  sed '\:^/etc/nethserver/todos.d/: d
\:^/etc/sudoers.d/: d
' > %{name}-%{version}-filelist

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
%doc COPYING
%doc scripts/bats
%dir %{_nseventsdir}/%{name}-update
%ghost %attr(644,root,root) /etc/pam.d/password-auth-nh
%ghost %attr(644,root,root) /etc/pam.d/system-auth-nh
%config %attr (0440,root,root) %{_sysconfdir}/sudoers.d/20_nethserver_directory

%changelog
* Mon Jun 08 2020 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.4.1-1
- OpenLDAP: avoid password limit length fixed to 8 chars - Bug NethServer/dev#6194

* Thu Jun 04 2020 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.4.0-1
- Remove TLS 1.0 and TLS 1.1 - NethServer/dev#6170

* Thu Jan 16 2020 Davide Principi <davide.principi@nethesis.it> - 3.3.3-1
- Shared folders UPN login error after ns6upgrade - Bug NethServer/dev#6020

* Fri Dec 07 2018 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.3.2-1
- Detach user-cleanup event from user-delete - NethServer/dev#5624

* Thu Oct 25 2018 Davide Principi <davide.principi@nethesis.it> - 3.3.1-1
- Live upgrade procedure - NethServer/dev#5564

* Tue Jun 26 2018 Davide Principi <davide.principi@nethesis.it> - 3.3.0-1
- Allow Elliptic Curve Criptography (ECC) certificate - NethServer/dev#5509

* Wed May 30 2018 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.2.7-1
- Slapd fails to start during restore-config - Bug NethServer/dev#5512

* Tue May 15 2018 Davide Principi <davide.principi@nethesis.it> - 3.2.6-1
- Local LDAP accounts provider installation error - Bug NethServer/dev#5493

* Thu Mar 29 2018 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.2.5-1
- Importing users fails during upgrade from ns6 to AD - Bug NethServer/dev#5443

* Tue Mar 27 2018 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.2.4-1
- Directory: error when removing user without home - Bug NethServer/dev#5444

* Thu May 25 2017 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.2.3-1
- Migrate LogonDrive prop - Bug NethServer/dev#5290
- UPN is now set by nethserver-dc package

* Mon May 22 2017 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.2.2-1
- NS 6 upgrade: users not locked - Bug NethServer/dev#5288

* Wed May 10 2017 Davide Principi <davide.principi@nethesis.it> - 3.2.1-1
- Accounts provider guided configuration - NethServer/dev#5253
- Upgrade from NS 6 via backup and restore - NethServer/dev#5234

* Fri Apr 21 2017 Davide Principi <davide.principi@nethesis.it> - 3.2.0-1
- Upgrade from NS 6 via backup and restore - NethServer/dev#5234 
- Slapd: decrease log verbosity - NethServer/dev#5256
- Accounts provider guided configuration - NethServer/dev#5253

* Mon Mar 06 2017 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.1.4-1
- Migration from sme8 - NethServer/dev#5196

* Mon Jan 30 2017 Davide Principi <davide.principi@nethesis.it> - 3.1.3-1
- Domain admins members are not granted full server-manager access - Bug NethServer/dev#5209

* Tue Dec 20 2016 Davide Principi <davide.principi@nethesis.it> - 3.1.2-1
- Fix bad recursive events -- NethServer/nethserver-directory#20

* Thu Dec 15 2016 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.1.1-1
- Set the members of administrators group - NethServer/dev#5168
- Enable LDAPs protocol on Active Directory clients - NethServer/dev#5161
- Notify changes to NethServer::SSSD clients - NethServer/dev#5164
- Changing password fails if contains a space - Bug NethServer/dev#5154
- Default "admins" config DB record - NethServer/dev#5157

* Wed Nov 09 2016 Davide Principi <davide.principi@nethesis.it> - 3.1.0-1
- LDAP account with read-only privileges - NethServer/dev#5145

* Mon Oct 17 2016 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.0.2-1
- Root's password change fails with OpenLDAP provider - Bug NethServer/dev#5129

* Mon Aug 01 2016 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 3.0.1-1
- Execute nethserver-sssd-save event - #5072 

* Thu Jul 07 2016 Stefano Fancello <stefano.fancello@nethesis.it> - 3.0.0-1
- First NS7 release

* Thu Sep 24 2015 Davide Principi <davide.principi@nethesis.it> - 2.3.0-1
- Obsolete nethserver-password by merging it into nethserver-directory - Enhancement #3260 [NethServer]

* Mon Sep 14 2015 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.2.3-1
- Avoid slapd restart when updating openldap-servers package - Enhancement #3253 [NethServer]

* Wed May 20 2015 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.2.2-1
- Localize "password expire" notifications - Enhancement #2887 [NethServer]

* Tue May 19 2015 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.2.1-1
- Create User tab not reset - Bug #2728 [NethServer]

* Thu Apr 23 2015 Davide Principi <davide.principi@nethesis.it> - 2.2.0-1
- Language packs support - Feature #3115 [NethServer]
- Expired password visual notification - Feature #2980 [NethServer]

* Tue Mar 03 2015 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.1.0-1
- Differentiate root and admin users - Feature #3026 [NethServer]

* Thu Jan 29 2015 Davide Principi <davide.principi@nethesis.it> - 2.0.6-1.ns6
- Password renewal link doesn't use httpd-admin TCPPort  - Bug #2993 [NethServer]

* Tue Dec 09 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.0.5-1.ns6
- Modify all users if the ldap organisation contacts is updated - Bug #2931 [NethServer]
- Drop TCP wrappers hosts.allow hosts.deny templates - Enhancement #2785 [NethServer]

* Mon Nov 03 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.0.4-1.ns6
- slapd Upstart status is out of control if BDB is corrupted - Bug #2928
- Drop TCP wrappers hosts.allow hosts.deny templates - Enhancement #2785

* Thu Jun 19 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 2.0.3-1.ns6
- Flexible "what" clause in enforceAccessDirective() - Enhancement #2757
- Missing Italian translation - Bug #2706
- Import users from a file - Feature #2666

* Mon Mar 10 2014 Davide Principi <davide.principi@nethesis.it> - 2.0.2-1.ns6
- Backup config: can't restore LDAP dump - Bug #2680 [NethServer]

* Wed Feb 26 2014 Davide Principi <davide.principi@nethesis.it> - 2.0.1-1.ns6
- Revamp web UI style - Enhancement #2656 [NethServer]
- Skip deleted accounts in dashboard - Bug #2648 [NethServer]
- Implement hostname-modify event for samba  - Enhancement #2626 [NethServer]

* Wed Feb 05 2014 Davide Principi <davide.principi@nethesis.it> - 2.0.0-1.ns6
- Move admin user in LDAP DB - Feature #2492 [NethServer]
- IPSec: honor VPNClientAccess property - Enhancement #2294 [NethServer]
- Update all inline help documentation - Task #1780 [NethServer]
- Dashboard: new widgets - Enhancement #1671 [NethServer]
- Users and groups migration script - Enhancement #1655 [NethServer]

* Wed Dec 18 2013 Davide Principi <davide.principi@nethesis.it> - 1.3.0-1.ns6
- Password expiration warnings are sent to locked users - Bug #2250 [NethServer]
- Directory: backup service accounts passwords  - Enhancement #2063 [NethServer]
- Service supervision with Upstart - Feature #2014 [NethServer]

* Wed Oct 16 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.2.3-1.ns6
- Add AdminIsNotRoot property #2277
- Add language code to URLs  #2113
- warnpassexpire script: conform to user state machine - #1073
- Db defaults: remove Runlevels prop. Refs #206

* Fri Jul 12 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.2.2-1.ns6
- Backup: implement and document full restore #2043
- nethserver-directory: fix nsstest user creation #1981

* Wed May 29 2013 Davide Principi <davide.principi@nethesis.it> - 1.2.1-1.ns6
- Create nsstest user and group in LDAP. Bugfix #1981

* Tue Apr 30 2013 Davide Principi <davide.principi@nethesis.it> - 1.2.0-1.ns6
- Full automatic package install/upgrade/uninstall support #1870
- Default user Organization Contact props #1853
- Fixed samba password hash disclosure: slapd ACLs applied on both BDB and rwm frontends #1894
- hostname-modify event support #1010
- Change default slapd log level to 0  #1835
- /etc/pam.d/system-auth-nh, /etc/nsswitch.conf: use new template format #1746

* Tue Mar 19 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.1.2-1.ns6
- Add migration code

* Mon Feb 11 2013 Davide Principi <davide.principi@nethesis.it> - 1.1.1-1.ns6
- Disable default group home directory cretion. 
  Refs #1638

* Thu Jan 31 2013 Davide Principi <davide.principi@nethesis.it> - 1.1.0-1.ns6
- NethServer/Directory.pm: added configServiceAccount() method. 
  Refs #1639 -- LDAP service accounts
- Configure default certificate management. 
  Refs #1632


