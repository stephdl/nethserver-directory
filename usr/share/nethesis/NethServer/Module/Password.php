<?php
namespace NethServer\Module;

use Nethgui\System\PlatformInterface as Validate;
#use Nethgui\Controller\Table\Modify as Table;

/**
 * Manage the password policy
 *
 * @author Stephane de Labrusse <stephdl@de-labrusse.fr>
 */

class Password extends \Nethgui\Controller\AbstractController
{

    protected function initializeAttributes(\Nethgui\Module\ModuleAttributesInterface $base)
    {
        return \Nethgui\Module\SimpleModuleAttributesProvider::extendModuleAttributes($base, 'Management', 30);
    }

    public function setDefaultValues($parameterName, $value)
    {
        $this->defaultValues[$parameterName] = $value;
        return $this;
    }

    public function initialize()
    {
    $this->declareParameter('Users', $this->createValidator()->memberOf('none', 'strong'), array('configuration', 'passwordstrength', 'Users'));
    $this->declareParameter('Ibays', $this->createValidator()->memberOf('none', 'strong'), array('configuration', 'passwordstrength', 'Ibays'));
    $this->declareParameter('Admin', $this->createValidator()->memberOf('none', 'strong'), array('configuration', 'passwordstrength', 'Admin'));
    $this->declareParameter('MaxPassAge', Validate::POSITIVE_INTEGER, array('configuration', 'passwordstrength', 'MaxPassAge'));
    $this->declareParameter('MinPassAge', $this->createValidator()->memberOf('0','30','60','90','180','365'), array('configuration', 'passwordstrength', 'MinPassAge'));
    $this->declareParameter('PassExpires', $this->createValidator()->memberOf('yes', 'no'), array('configuration', 'passwordstrength', 'PassExpires'));
    $this->declareParameter('PassWarning', Validate::POSITIVE_INTEGER, array('configuration', 'passwordstrength', 'PassWarning'));

    $this->setDefaultValues('Users', 'strong');
    $this->setDefaultValues('Ibays', 'strong');
    $this->setDefaultValues('Admin', 'strong');
    $this->setDefaultValues('MaxPassAge', '180');
    $this->setDefaultValues('MinPassAge', '0');
    $this->setDefaultValues('PassExpires', 'yes');
    $this->setDefaultValues('PassWarning', '7');


parent::initialize();
    }

    public function prepareView(\Nethgui\View\ViewInterface $view)
    {
        parent::prepareView($view);


        $view['MaxPassAgeDatasource'] = \Nethgui\Renderer\AbstractRenderer::hashToDatasource(array(
                '30' => $view->translate('${0} days', array(30)),
                '60' => $view->translate('${0} days', array(60)),
                '90' => $view->translate('${0} days', array(90)),
                '180' => $view->translate('${0} days', array(180)),
                '365' => $view->translate('${0} days', array(365)),
        ));
        $view['MinPassAgeDatasource'] = \Nethgui\Renderer\AbstractRenderer::hashToDatasource(array(
                '0' => $view->translate('${0} days', array(0)),
                '30' => $view->translate('${0} days', array(30)),
                '60' => $view->translate('${0} days', array(60)),
                '90' => $view->translate('${0} days', array(90)),
                '180' => $view->translate('${0} days', array(180)),
                '365' => $view->translate('${0} days', array(365)),
        ));
        $view['PassWarningDatasource'] = \Nethgui\Renderer\AbstractRenderer::hashToDatasource(array(
                '7' => $view->translate('${0} days', array(7)),
                '15' => $view->translate('${0} days', array(15)),
                '30' => $view->translate('${0} days', array(30)),
        ));


     }

    protected function onParametersSaved($changes)
    {
        $this->getPlatform()->signalEvent('password-policy-update@post-process');
    }

}

