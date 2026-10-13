# MagixCartpay - Panier & Commandes pour Magix CMS 4

[![Release](https://img.shields.io/github/release/magix-cms/Magixcartpay.svg)](https://github.com/magix-cms/Magixcartpay/releases/latest)
[![License](https://img.shields.io/github/license/magix-cms/Magixcartpay.svg)](LICENSE)
[![PHP Version](https://img.shields.io/badge/php-%3E%3D%208.2-blue.svg)](https://php.net/)
[![Magix CMS](https://img.shields.io/badge/Magix%20CMS-4.x-success.svg)](https://www.magix-cms.com/)

MagixCartpay est le moteur e-commerce léger et modulaire pour Magix CMS 4. Il gère de manière autonome la logique de panier, les mathématiques complexes (TVA), la transformation en commandes (ou devis), et l'envoi des factures.

## 🚀 Fonctionnalités principales

- **Panier Hybride Intelligent** : Le panier bascule automatiquement en "Demande de Devis" si un produit coûte 0 €, ou agit comme un "Panier d'Achat" standard si des prix sont définis.
- **Fusion de Panier (Cart Merging)** : Si un visiteur remplit son panier de manière anonyme puis se connecte à son compte, ses articles sont automatiquement fusionnés avec son ancien panier sauvegardé.
- **Calculateur Javascript temps réel** : Prise en charge native de la mise à jour dynamique des totaux (TTC, HT, TVA) lorsqu'un transporteur est sélectionné.
- **Nettoyage automatique** : Bouton d'administration pour purger les paniers abandonnés (vieux de plus de 7 jours).
- **Protection Anti-Spam** : Intégration native et automatique de Google reCAPTCHA v3.

## 📦 Installation

1. Placez le dossier `Magixcartpay` dans le répertoire `plugins/`.
2. Installez le plugin depuis l'administration. 
3. *Note : Il est fortement recommandé d'installer également `Magixaccount` pour profiter de la liaison des commandes aux comptes clients.*

## 🧩 Écosystème et Addons (Transport & Paiement)

MagixCartpay est conçu de manière totalement agnostique. Il délègue la gestion des moyens de paiement et de livraison à des plugins externes de type `addon`.

### Créer un module de livraison ou de paiement

Pour lier un module à Magixcartpay, déclarez-le dans le `manifest.json` de votre nouveau plugin avec le type `addon` :

```json
{
  "name": "MagixShippingLocal",
  "type": "addon",
  "plugin_targets": {
    "Magixcartpay": 1
  }
}
```

## 🎨 Intégration sur le site (Frontend)

Vous devez ajouter différents éléments dans votre thème pour exploiter le panier.

### 1. Ajouter un produit au panier

Sur la page de détail d'un produit (ex: `skin/votre_theme/catalog/product.tpl`), ajoutez ce hook pour générer le bouton d'ajout au panier. Il pointera automatiquement vers l'ID du produit consulté.

```smarty
{hook name="displayProductAddToCart" id_product=$productData.id|default:0}
```

### 2. Le Widget Panier (En-tête)

Pour afficher le résumé du panier (Total et quantité) dans la navigation (ex: `skin/votre_theme/layout/header.tpl`) :

```smarty
{event name="displayHeaderCartWidget"}
```

### 3. Vente de Produits Numériques (Accès conditionnel)

Si vous vendez des vidéos privées ou des fichiers à télécharger, MagixCartpay vous permet de vérifier très facilement si le visiteur connecté possède le produit. Dans votre fichier `product.tpl` :

```smarty
{* Vérifie discrètement en base de données si l'utilisateur possède une commande 'payée' contenant ce produit *}
{has_purchased id_product=$productData.id|default:0 assign="user_owns_product"}

{if $user_owns_product}
    <div class="alert alert-success">
        <h5><i class="bi bi-unlock-fill"></i> Contenu débloqué</h5>
        {* Placez votre iframe Dailymotion privée ou lien de téléchargement ici *}
    </div>
{else}
    <div class="alert alert-secondary">
        <p>Achetez ce produit pour débloquer la vidéo explicative.</p>
        {hook name="displayProductAddToCart" id_product=$productData.id|default:0}
    </div>
{/if}
```

## 🛠️ Pour les Développeurs (Créer une extension)

MagixCartpay est conçu pour être étendu par d'autres plugins (Ex: Module de livraison locale).
Pour lier automatiquement votre futur module à MagixCartpay, utilisez le paramètre `plugin_targets` dans le `manifest.json` de votre module :

```json
{
  "name": "MagixShippingLocal",
  "type": "addon",
  "plugin_targets": {
    "Magixcartpay": 1
  }
}
```

Une fois installé, votre module pourra injecter son code directement dans la page de commande (Checkout) de MagixCartpay en écoutant le Hook suivant :

```smarty
{* Dans la vue de votre module de livraison, injectez un bouton radio *}
<input type="radio" class="shipping-method-radio" name="shipping_method" value="local" data-price="15.00">
```

MagixCartpay s'occupera automatiquement d'intercepter le `data-price` via JavaScript, de calculer la TVA sur la livraison, et de mettre à jour le Total TTC en temps réel.

---

## 📄 Licence

Ce projet est sous licence **GPLv3**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.
Copyright (C) 2008 - 2026 Gerits Aurelien (Magix CMS)