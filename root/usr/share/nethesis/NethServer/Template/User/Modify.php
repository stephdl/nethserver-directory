<?php

$view->requireFlag($view::INSET_FORM);

if ($view->getModule()->getIdentifier() == 'update') {
    $headerText = 'Update user `${0}`';
} else {
    $headerText = 'Create a new user';
}

echo $view->header('username')->setAttribute('template', $headerText);

$basicInfo = $view->panel()
    ->setAttribute('title', $T('BasicInfo_Title'))
    ->insert($view->textInput('username', ($view->getModule()->getIdentifier() == 'update' ? $view::STATE_READONLY : 0)))
    ->insert($view->textInput('FirstName'))
    ->insert($view->textInput('LastName'))
    ->insert($view->objectPicker('Groups')
    ->setAttribute('objects', 'GroupsDatasource')
    ->setAttribute('template', 'Groups')
    ->setAttribute('objectLabel', 1));


$infoTab = $view->panel()
    ->setAttribute('title', $T('ExtraInfo_Title'))
    ->insert($view->textInput('Company'))
    ->insert($view->textInput('Dept'))
    ->insert($view->textInput('Street'))
    ->insert($view->textInput('City'))
    ->insert($view->textInput('Phone'));

$tabs = $view->tabs()
    ->insert($basicInfo)
    ->insert($infoTab)
    ->insertPlugins()
;

echo $tabs;

$buttons = $view->buttonList($view::BUTTON_SUBMIT | $view::BUTTON_HELP);

if ($view->getModule()->getIdentifier() == 'update') {
    $buttons->insert($view->button('change-password', $view::BUTTON_LINK));
}
$buttons->insert($view->button('Cancel', $view::BUTTON_CANCEL));

echo $buttons;

