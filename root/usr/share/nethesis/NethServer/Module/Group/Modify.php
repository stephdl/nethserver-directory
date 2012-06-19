<?php
namespace NethServer\Module\Group;

/*
 * Copyright (C) 2012 Nethesis S.r.l.
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

use Nethgui\System\PlatformInterface as Validate;
use Nethgui\Controller\Table\Modify as Table;

/**
 * Group modify actions
 *
 * @author Davide Principi <davide.principi@nethesis.it>
 * @since 1.0
 */
class Modify extends \Nethgui\Controller\Table\Modify
{

    public function initialize()
    {
        $groupNameValidator = $this->getPlatform()->createValidator(Validate::USERNAME)->platform('group-name');

        $parameterSchema = array(
            array('groupname', $groupNameValidator, \Nethgui\Controller\Table\Modify::KEY),
            array('Description', Validate::ANYTHING, \Nethgui\Controller\Table\Modify::FIELD, 'Description'),
            array('Members', Validate::USERNAME_COLLECTION, \Nethgui\Controller\Table\Modify::FIELD, 'Members', ','),
            array('MembersDatasource', FALSE, array($this, 'provideMembersDatasource')), // this parameter will never be submitted: set an always-failing validator
        );
        
        $this->setSchema($parameterSchema);

        parent::initialize();
    }

    public function provideMembersDatasource()
    {
        $platform = $this->getPlatform();
        if (is_null($platform)) {
            return array();
        }

        $users = $platform->getTableAdapter('accounts', 'user');

        $values = array();

        // Build the datasource rows couples <key, label>
        foreach ($users as $username => $row) {
            $values[] = array($username, sprintf('%s %s (%s)', $row['FirstName'], $row['LastName'], $username));
        }

        return $values;
    }

    public function onParametersSaved($changedParameters)
    {
        if ($this->getIdentifier() === 'update') {
            $event = 'modify';
        } else {
            $event = $this->getIdentifier();
        }
        $this->getPlatform()->signalEvent(sprintf('group-%s@post-process', $event), array($this->parameters['groupname']));
    }

    public function prepareView(\Nethgui\View\ViewInterface $view)
    {
        parent::prepareView($view);
        $templates = array(
            'create' => 'NethServer\Template\Group\Modify',
            'update' => 'NethServer\Template\Group\Modify',
            'delete' => 'Nethgui\Template\Table\Delete',
        );
        $view->setTemplate($templates[$this->getIdentifier()]);
    }

}
