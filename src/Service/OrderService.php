<?php
declare(strict_types=1);

namespace Plugins\Magixcartpay\src\Service;

use Magepattern\Component\Database\QueryBuilder;
use App\Frontend\Db\BaseDb;

class OrderService extends BaseDb
{
    /**
     * Transforme un panier en Commande ou Devis (Snapshot immuable)
     */
    public function convertCartToOrder(int $idLang, array $address, string $paymentMethod, string $typeDoc = 'order', float $shippingPriceHt = 0.00, string $shippingMethod = 'pickup', array $shippingAddress = []): string|false
    {
        $cartService = new CartService();
        $fullCart = $cartService->getFullCartDetails($idLang);

        if (empty($fullCart['items']) || $fullCart['summary']['items_count'] === 0) {
            return false;
        }

        // 1. Génération d'une référence unique (ex: ORD-20261009-4582)
        $prefix = $typeDoc === 'quotation' ? 'DEV-' : 'ORD-';
        $reference = $prefix . date('Ymd') . '-' . rand(1000, 9999);

        // --- CALCULS MATHÉMATIQUES GLOBAUX AVEC LA LIVRAISON ---
        $taxRate = $fullCart['summary']['tax_rate'];
        $shippingTax = $shippingPriceHt * ($taxRate / 100);
        $finalTotalTax = $fullCart['summary']['total_tax'] + $shippingTax;
        $finalTotalTtc = $fullCart['summary']['total_ht'] + $shippingPriceHt + $finalTotalTax;

        // 2. Création de l'entête de commande
        $qbOrder = new QueryBuilder();
        $orderData = [
            'reference'         => $reference,
            'id_account'        => $fullCart['id_account'],
            'type_doc'          => $typeDoc,
            'status'            => 'pending',
            'payment_method'    => $paymentMethod,
            'shipping_method'   => $shippingMethod,
            'total_products_ht' => $fullCart['summary']['total_ht'],
            'total_shipping_ht' => round($shippingPriceHt, 2),
            'total_tax'         => round($finalTotalTax, 2),
            'total_ttc'         => round($finalTotalTtc, 2),
            'currency'          => 'EUR',
            'date_add'          => date('Y-m-d H:i:s'),
            'date_upd'          => date('Y-m-d H:i:s')
        ];

        $qbOrder->insert('mc_magixcartpay_order', $orderData);

        if (!$this->executeInsert($qbOrder)) {
            return false;
        }

        $idOrder = (int)$this->getLastInsertId();

        // 3. Insertion des lignes de produits
        // 3. Insertion des lignes de produits
        foreach ($fullCart['items'] as $item) {
            $qbItem = new QueryBuilder();
            $itemData = [
                'id_order'          => $idOrder,
                'id_product'        => $item['id_product'],
                'product_reference' => $item['reference'],
                'product_name'      => $item['name'],
                'quantity'          => $item['quantity'],
                'unit_price_ht'     => $item['unit_price'],
                'is_promo'          => !empty($item['is_promo']) ? 1 : 0, // <--- AJOUT DE LA PROMO ICI
                'tax_rate'          => $taxRate,
                'total_ttc'         => round($item['total_price'] * (1 + ($taxRate / 100)), 2)
            ];
            $qbItem->insert('mc_magixcartpay_order_item', $itemData);
            $this->executeInsert($qbItem);
        }

        // 4. Insertion de l'adresse de facturation
        $qbAddress = new QueryBuilder();
        $addressData = [
            'id_order'     => $idOrder,
            'type_address' => 'billing',
            'company'      => $address['company'] ?? null,
            'vat_number'   => $address['vat_number'] ?? null,
            'firstname'    => $address['firstname'],
            'lastname'     => $address['lastname'],
            'email'        => $address['email'],
            'phone'        => $address['phone'] ?? null,
            'street'       => $address['street'],
            'postcode'     => $address['postcode'],
            'city'         => $address['city'],
            'country'      => $address['country'] ?? 'BE'
        ];
        $qbAddress->insert('mc_magixcartpay_order_address', $addressData);
        $this->executeInsert($qbAddress);

        // 5. Insertion de l'adresse de livraison (Si différente)
        if (!empty($shippingAddress)) {
            $qbShipping = new QueryBuilder();
            $shippingData = [
                'id_order'     => $idOrder,
                'type_address' => 'shipping',
                'company'      => $shippingAddress['company'] ?? null,
                'vat_number'   => null,
                'firstname'    => $shippingAddress['firstname'],
                'lastname'     => $shippingAddress['lastname'],
                'email'        => $address['email'], // On garde l'email du client
                'phone'        => $address['phone'] ?? null,
                'street'       => $shippingAddress['street'],
                'postcode'     => $shippingAddress['postcode'],
                'city'         => $shippingAddress['city'],
                'country'      => $shippingAddress['country'] ?? 'BE'
            ];
            $qbShipping->insert('mc_magixcartpay_order_address', $shippingData);
            $this->executeInsert($qbShipping);
        }

        // 6. Nettoyage du panier
        $qbDeleteCart = new QueryBuilder();
        $qbDeleteCart->delete('mc_magixcartpay_cart_item')->where('id_cart = :id_cart', ['id_cart' => $fullCart['cart_id']]);
        $this->executeDelete($qbDeleteCart);

        return $reference;
    }
}