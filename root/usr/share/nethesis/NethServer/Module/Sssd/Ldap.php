<?php

namespace NethServer\Module\Sssd;

/*
 * Copyright (C) 2016 Nethesis S.r.l.
 * 
 * This script is part of NethServer.
 * 
 * NethServer is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * NethServer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with NethServer.  If not, see <http://www.gnu.org/licenses/>.
 */


/**
 * Change LDAP settings
 *
 * @author Giacomo Sanchietti<giacomo.sanchietti@nethesis.it>
 */
class Ldap extends \Nethgui\Controller\AbstractController
{

    public function prepareView(\Nethgui\View\ViewInterface $view)
    {
        parent::prepareView($view);

        $pass = $this->getPlatform()->exec('sudo cat /var/lib/nethserver/secrets/libuser')->getOutput(); 
        $base = "dc=directory,dc=nh";
        $view['BaseDN'] = $base;
        $view['BindDN'] = "cn=libuser,$base";
        $view['BindPassword'] = $pass;
        $view['UserDN'] = "ou=People,$base";
        $view['GroupDN'] = "ou=Groups,$base";
        $view['dump'] = $this->getPlatform()->exec('/bin/ldapsearch -x -h localhost | head -10000')->getOutput();

    }

}
