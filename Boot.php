<?php
/*
# Copyright (C) 2008 - 2026 Gerits Aurelien (Magix CMS).
# License GPLv3
*/

declare(strict_types=1);

namespace Plugins\Magixcartpay;

use App\Component\Hook\HookManager;
use Plugins\Magixcartpay\src\FrontendController;

class Boot
{
    public function register(): void
    {
        // Widget Header : Panier global
        HookManager::register('displayHeaderCartWidget', 'Magixcartpay', [FrontendController::class, 'renderWidget']);

        // Fiche Produit : Bouton "Ajouter au panier"
        HookManager::register('displayProductAddToCart', 'Magixcartpay', [FrontendController::class, 'renderAddToCartWidget']);

        // --- NOUVEAU : ESPACE MEMBRE MAGIXACCOUNT ---

        // Injecte un lien "Mes Commandes" dans la barre latérale du profil
        HookManager::register('displayAccountProfileMenu', 'Magixcartpay', [FrontendController::class, 'hookAccountProfileMenu']);

        // Injecte le bloc "Historique des commandes" dans le profil
        HookManager::register('displayAccountProfileContent', 'Magixcartpay', [FrontendController::class, 'hookAccountProfileContent']);

        $view = \Magepattern\Component\Tool\SmartyTool::getInstance('front');
        $view->registerPlugin('function', 'has_purchased', [FrontendController::class, 'smartyHasPurchased']);
    }

    public function hookDisplayCartWidget(): string
    {
        // On fait appel à la méthode statique que nous avons ajoutée dans le FrontendController
        return FrontendController::renderWidget();
    }
}