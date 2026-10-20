<?php
/*
# Copyright (C) 2008 - 2026 Gerits Aurelien (Magix CMS).
# License GPLv3
*/

declare(strict_types=1);

namespace Plugins\Magixcartpay;

use App\Component\Hook\HookManager;

class Boot
{
    public function register(): void
    {
        // Widget Header : Panier global
        HookManager::register('displayHeaderCartWidget', 'Magixcartpay', function(array $params) {
            $class = '\Plugins\Magixcartpay\src\FrontendController';
            if (class_exists($class)) {
                return $class::renderWidget();
            }
            return '';
        });

        // Fiche Produit : Bouton "Ajouter au panier"
        HookManager::register('displayProductAddToCart', 'Magixcartpay', function(array $params) {
            $class = '\Plugins\Magixcartpay\src\FrontendController';
            if (class_exists($class)) {
                return $class::renderAddToCartWidget($params);
            }
            return '';
        });

        // --- ESPACE MEMBRE MAGIXACCOUNT ---

        // Injecte un lien "Mes Commandes" dans la barre latérale du profil
        HookManager::register('displayAccountProfileMenu', 'Magixcartpay', function(array $params) {
            $class = '\Plugins\Magixcartpay\src\FrontendController';
            if (class_exists($class)) {
                return $class::hookAccountProfileMenu($params);
            }
            return '';
        });

        // Injecte le bloc "Historique des commandes" dans le profil
        HookManager::register('displayAccountProfileContent', 'Magixcartpay', function(array $params) {
            $class = '\Plugins\Magixcartpay\src\FrontendController';
            if (class_exists($class)) {
                return $class::hookAccountProfileContent($params);
            }
            return '';
        });

        $view = \Magepattern\Component\Tool\SmartyTool::getInstance('front');
        $view->registerPlugin('function', 'has_purchased', function(array $params, $smarty) {
            $class = '\Plugins\Magixcartpay\src\FrontendController';
            if (class_exists($class)) {
                return $class::smartyHasPurchased($params, $smarty);
            }
            return false;
        });
    }

    public function hookDisplayCartWidget(): string
    {
        $class = '\Plugins\Magixcartpay\src\FrontendController';
        if (class_exists($class)) {
            return $class::renderWidget();
        }
        return '';
    }
}