<?php

echo "<div class='ldap-info'><dl>";
echo "<dt>".$T('basedn_label')."</dt><dd>{$view['BaseDN']}</dd>";
echo "<dt>".$T('userdn_label')."</dt><dd>{$view['UserDN']}</dd>";
echo "<dt>".$T('groupdn_label')."</dt><dd>{$view['GroupDN']}</dd>";
echo "</dl></div>";


echo "<div class='ldap-info'><dl>";
echo "<dt>".$T('binddn_label')."</dt><dd>{$view['BindDN']}</dd>";
echo "<dt>".$T('bindpassword')."</dt><dd>{$view['BindPassword']}</dd>";
echo "</dl></div>";

echo $view->fieldset('', $view::FIELDSET_EXPANDABLE)->setAttribute('template', $T('LDAPdump_label'))
    ->insert($view->textLabel('dump')->setAttribute('class', 'labeled-control ldif ui-corner-all')->setAttribute('tag', 'div'));

$view->includeCss("
.ldif { white-space: pre-wrap; padding: 4px; border: 1px solid #c2c2c2; margin-right: 5px; background: #e2e2r2; color: #4b4b4b; }
.ldap-info { padding: 4px; margin: 4px; }
.ldap-info dt { font-weight: bold; }
.ldap-info dd { margin-left: 4px; margin-bottom: 4px; }
");
