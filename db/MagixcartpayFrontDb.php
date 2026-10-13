<?php
/*
# Copyright (C) 2008 - 2026 Gerits Aurelien (Magix CMS).
# License GPLv3
*/

declare(strict_types=1);

namespace Plugins\Magixcartpay\db;

use App\Frontend\Db\BaseDb;
use Magepattern\Component\Database\QueryBuilder;

class MagixcartpayFrontDb extends BaseDb
{
    /**
     * Récupère la configuration globale du e-commerce (Prix TTC/HT, Virements, etc.)
     */
    public function getCartConfig(): array
    {
        $qb = new QueryBuilder();
        $qb->select('*')->from('mc_magixcartpay_config')->limit(1);
        $res = $this->executeRow($qb);

        return $res ?: [
            'quotation_enabled' => 1,
            'order_enabled'     => 0,
            'price_display'     => 'ttc',
            'bank_wire'         => 0
        ];
    }

    /**
     * Récupère l'historique des commandes d'un client connecté (pour l'espace membre)
     */
    public function getOrdersByAccount(int $idAccount): array
    {
        $qb = new QueryBuilder();
        $qb->select(['id_order', 'reference', 'type_doc', 'status', 'total_ttc', 'date_add', 'payment_method'])
            ->from('mc_magixcartpay_order')
            ->where('id_account = :id', ['id' => $idAccount])
            ->orderBy('date_add', 'DESC');

        return $this->executeAll($qb) ?: [];
    }

    /**
     * Récupère le détail complet d'une commande passée (Lignes + Adresse)
     */
    public function getOrderDetails(int $idOrder, ?int $idAccount = null): array
    {
        $qb = new QueryBuilder();
        $qb->select('*')->from('mc_magixcartpay_order');

        if ($idAccount !== null) {
            $qb->where('id_order = :id AND id_account = :account', ['id' => $idOrder, 'account' => $idAccount]);
        } else {
            $qb->where('id_order = :id', ['id' => $idOrder]);
        }

        $order = $this->executeRow($qb);

        if (!$order) {
            return [];
        }

        // Lignes du panier
        $qbItems = new QueryBuilder();
        $qbItems->select('*')->from('mc_magixcartpay_order_item')->where('id_order = :id', ['id' => $idOrder]);
        $order['items'] = $this->executeAll($qbItems) ?: [];

        // Adresse de facturation
        $qbAddress = new QueryBuilder();
        $qbAddress->select('*')->from('mc_magixcartpay_order_address')
            ->where('id_order = :id AND type_address = "billing"', ['id' => $idOrder])->limit(1);
        $order['billing_address'] = $this->executeRow($qbAddress) ?: [];

        // Adresse de livraison (NOUVEAU)
        $qbShipping = new QueryBuilder();
        $qbShipping->select('*')->from('mc_magixcartpay_order_address')
            ->where('id_order = :id AND type_address = "shipping"', ['id' => $idOrder])->limit(1);
        $order['shipping_address'] = $this->executeRow($qbShipping) ?: [];

        return $order;
    }

    /**
     * Tente de récupérer les informations de l'utilisateur s'il est connecté via Magixaccount
     * Cela permet de pré-remplir le formulaire de commande
     */
    public function getAccountProfile(int $idAccount): array
    {
        // Nous vérifions si la table mc_account existe (au cas où le plugin Magixaccount ne serait pas installé)
        try {
            $qb = new QueryBuilder();
            $qb->select('a.email, a.firstname, a.lastname, p.company, p.phone')
                ->from('mc_account', 'a')
                ->leftJoin('mc_account_profile', 'p', 'a.id_account = p.id_account')
                ->where('a.id_account = :id', ['id' => $idAccount])
                ->limit(1);

            return $this->executeRow($qb) ?: [];
        } catch (\Exception $e) {
            // Le plugin Magixaccount n'est probablement pas installé, on retourne un tableau vide
            return [];
        }
    }
    /**
     * Vérifie si un client a acheté un produit spécifique et si la commande est payée.
     */
    public function hasPurchasedProduct(int $idAccount, int $idProduct): bool
    {
        $qb = new QueryBuilder();
        $qb->select('o.id_order')
            ->from('mc_magixcartpay_order', 'o')
            ->join('mc_magixcartpay_order_item', 'i', 'o.id_order = i.id_order')
            ->where('o.id_account = :id_account AND i.id_product = :id_product AND o.status = "paid"', [
                'id_account' => $idAccount,
                'id_product' => $idProduct
            ])
            ->limit(1);

        $result = $this->executeRow($qb);

        // Renvoie true si on trouve au moins une ligne, sinon false
        return !empty($result);
    }
}