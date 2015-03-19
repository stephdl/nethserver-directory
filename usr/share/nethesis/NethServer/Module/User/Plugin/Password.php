<?php
namespace NethServer\Module\User\Plugin;

use Nethgui\System\PlatformInterface as Validate;
use Nethgui\Controller\Table\Modify as Table;

/**
 * Password user plugin
 * 
 * @author Stephane de Labrusse <stephdl@de-labrusse.fr> 
 */
class Password extends \Nethgui\Controller\Table\RowPluginAction
{

    protected function initializeAttributes(\Nethgui\Module\ModuleAttributesInterface $base)
    {
        return \Nethgui\Module\SimpleModuleAttributesProvider::extendModuleAttributes($base, 'Service', 10);
    }

    public function initialize()
    {
        $this->setSchemaAddition(array(
            array('PassExpires',$this->createValidator()->memberOf('yes', 'no') , Table::FIELD),
        ));
        $this->setDefaultValue('PassExpires', 'yes');
        parent::initialize();
    }

}
