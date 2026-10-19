<?php
declare(strict_types=1);

namespace Plugins\Magixcartpay\src\Service;

use Magepattern\Component\Database\QueryBuilder;
use App\Frontend\Db\BaseDb;
use App\Frontend\Db\SettingDb;
use Magepattern\Component\HTTP\Session;

class CartService extends BaseDb
{
    private Session $sessionManager;
    private string $sessionId;
    private ?int $idAccount = null;

    public function __construct()
    {
        $this->sessionManager = new Session(true, 'magix_sess_id');
        $this->sessionManager->start();
        $this->sessionId = session_id() ?: '';

        $id = $this->sessionManager->get('id_account');
        if (!empty($id)) {
            $this->idAccount = (int)$id;
        }
    }

    /**
     * Récupère le panier actif courant et gère la véritable fusion lors de la connexion
     */
    public function getCurrentCart(): array
    {
        $sessionCartId = (int)$this->sessionManager->get('cart_id');

        if ($this->idAccount !== null) {
            // 1. Cherche le panier sauvegardé du compte
            $qbSaved = new QueryBuilder();
            $qbSaved->select('*')->from('mc_magixcartpay_cart')
                ->where('id_account = :id', ['id' => $this->idAccount])
                ->orderBy('date_upd', 'DESC')->limit(1);
            $savedCart = $this->executeRow($qbSaved);

            // 2. Cherche un potentiel panier anonyme fraîchement rempli
            $anonCart = null;
            if ($sessionCartId > 0) {
                $qbAnon = new QueryBuilder();
                $qbAnon->select('*')->from('mc_magixcartpay_cart')
                    ->where('id_cart = :id AND id_account IS NULL', ['id' => $sessionCartId]);
                $anonCart = $this->executeRow($qbAnon);
            }

            // 3. Logique de fusion (Cart Merge)
            if ($savedCart && $anonCart) {
                if ((int)$savedCart['id_cart'] !== (int)$anonCart['id_cart']) {
                    // On bascule les articles vers le compte
                    $this->mergeCartItems((int)$anonCart['id_cart'], (int)$savedCart['id_cart']);

                    // On supprime le panier anonyme devenu inutile
                    $qbDel = new QueryBuilder();
                    $qbDel->delete('mc_magixcartpay_cart')->where('id_cart = :id', ['id' => $anonCart['id_cart']]);
                    $this->executeDelete($qbDel);
                }
                $this->sessionManager->set('cart_id', (int)$savedCart['id_cart']);
                return $savedCart;

            } elseif (!$savedCart && $anonCart) {
                // Aucun ancien panier, on lie simplement le panier anonyme au compte
                $this->linkCartToAccount((int)$anonCart['id_cart'], $this->idAccount);
                $anonCart['id_account'] = $this->idAccount;
                return $anonCart;

            } elseif ($savedCart && !$anonCart) {
                // Seulement un panier sauvegardé
                $this->sessionManager->set('cart_id', (int)$savedCart['id_cart']);
                return $savedCart;
            }
        } else {
            // 4. Client visiteur (non connecté)
            if ($sessionCartId > 0) {
                $qb = new QueryBuilder();
                $qb->select('*')->from('mc_magixcartpay_cart')
                    ->where('id_cart = :id AND id_account IS NULL', ['id' => $sessionCartId]);
                $cart = $this->executeRow($qb);
                if ($cart) return $cart;
            }

            // Fallback de sécurité via session PHP native
            $qbFall = new QueryBuilder();
            $qbFall->select('*')->from('mc_magixcartpay_cart')
                ->where('session_id = :sess AND id_account IS NULL', ['sess' => $this->sessionId])
                ->orderBy('date_upd', 'DESC')->limit(1);
            $cartFall = $this->executeRow($qbFall);

            if ($cartFall) {
                $this->sessionManager->set('cart_id', (int)$cartFall['id_cart']);
                return $cartFall;
            }
        }

        // 5. Aucun panier trouvé nulle part : on en crée un tout neuf
        $idCart = $this->createCart();
        $this->sessionManager->set('cart_id', $idCart);
        return $this->getCartById($idCart);
    }

    /**
     * Transfère les articles d'un panier à un autre, en gérant les doublons
     */
    private function mergeCartItems(int $fromCartId, int $toCartId): void
    {
        $qb = new QueryBuilder();
        $qb->select('*')->from('mc_magixcartpay_cart_item')->where('id_cart = :id', ['id' => $fromCartId]);
        $itemsToMerge = $this->executeAll($qb) ?: [];

        foreach ($itemsToMerge as $item) {
            $qbCheck = new QueryBuilder();
            $qbCheck->select('*')->from('mc_magixcartpay_cart_item')
                ->where('id_cart = :id_cart AND id_product = :id_product', [
                    'id_cart' => $toCartId,
                    'id_product' => $item['id_product']
                ]);
            $existing = $this->executeRow($qbCheck);

            if ($existing) {
                // Le produit existe déjà dans l'ancien panier : on additionne les quantités
                $newQty = (int)$existing['quantity'] + (int)$item['quantity'];

                $qbUpd = new QueryBuilder();
                $qbUpd->update('mc_magixcartpay_cart_item', ['quantity' => $newQty])
                    ->where('id_item = :id', ['id' => $existing['id_item']]);
                $this->executeUpdate($qbUpd);

                // On efface la ligne du panier temporaire puisqu'elle a été fusionnée
                $qbDel = new QueryBuilder();
                $qbDel->delete('mc_magixcartpay_cart_item')->where('id_item = :id', ['id' => $item['id_item']]);
                $this->executeDelete($qbDel);
            } else {
                // Le produit n'y est pas : on le déplace simplement vers le panier final
                $qbUpd = new QueryBuilder();
                $qbUpd->update('mc_magixcartpay_cart_item', ['id_cart' => $toCartId])
                    ->where('id_item = :id', ['id' => $item['id_item']]);
                $this->executeUpdate($qbUpd);
            }
        }

        $this->touchCart($toCartId);
    }

    private function createCart(): int
    {
        $qb = new QueryBuilder();
        $data = [
            'session_id' => $this->sessionId,
            'id_account' => $this->idAccount,
            'date_add'   => date('Y-m-d H:i:s'),
            'date_upd'   => date('Y-m-d H:i:s')
        ];
        $qb->insert('mc_magixcartpay_cart', $data);
        $this->executeInsert($qb);
        return (int)$this->getLastInsertId();
    }

    private function linkCartToAccount(int $idCart, int $idAccount): void
    {
        $qb = new QueryBuilder();
        $qb->update('mc_magixcartpay_cart', [
            'id_account' => $idAccount,
            'date_upd'   => date('Y-m-d H:i:s')
        ])->where('id_cart = :id', ['id' => $idCart]);
        $this->executeUpdate($qb);
    }

    /**
     * Ajoute un produit au panier
     */
    public function addItem(int $idProduct, int $quantity = 1): bool
    {
        if ($quantity <= 0) return false;

        $cart = $this->getCurrentCart();
        $idCart = (int)$cart['id_cart'];

        $qb = new QueryBuilder();
        $qb->select('*')
            ->from('mc_magixcartpay_cart_item')
            ->where('id_cart = :id_cart AND id_product = :id_product', [
                'id_cart' => $idCart,
                'id_product' => $idProduct
            ]);

        $existingItem = $this->executeRow($qb);

        if ($existingItem) {
            $newQuantity = (int)$existingItem['quantity'] + $quantity;
            $qbUpdate = new QueryBuilder();
            $qbUpdate->update('mc_magixcartpay_cart_item', ['quantity' => $newQuantity])
                ->where('id_item = :id_item', ['id_item' => $existingItem['id_item']]);
            $this->executeUpdate($qbUpdate);
        } else {
            $qbInsert = new QueryBuilder();
            $qbInsert->insert('mc_magixcartpay_cart_item', [
                'id_cart'    => $idCart,
                'id_product' => $idProduct,
                'quantity'   => $quantity,
                'date_add'   => date('Y-m-d H:i:s')
            ]);
            $this->executeInsert($qbInsert);
        }

        $this->touchCart($idCart);
        return true;
    }

    /**
     * Met à jour la quantité d'un article spécifique (depuis la page panier)
     */
    public function updateItemQuantity(int $idItem, int $quantity): bool
    {
        $cart = $this->getCurrentCart();
        $idCart = (int)$cart['id_cart'];

        if ($quantity <= 0) {
            return $this->removeItem($idItem);
        }

        $qb = new QueryBuilder();
        $qb->update('mc_magixcartpay_cart_item', ['quantity' => $quantity])
            ->where('id_item = :id_item AND id_cart = :id_cart', [
                'id_item' => $idItem,
                'id_cart' => $idCart
            ]);

        if ($this->executeUpdate($qb) !== false) {
            $this->touchCart($idCart);
            return true;
        }
        return false;
    }

    /**
     * Supprime un article du panier
     */
    public function removeItem(int $idItem): bool
    {
        $cart = $this->getCurrentCart();
        $idCart = (int)$cart['id_cart'];

        $qb = new QueryBuilder();
        $qb->delete('mc_magixcartpay_cart_item')
            ->where('id_item = :id_item AND id_cart = :id_cart', [
                'id_item' => $idItem,
                'id_cart' => $idCart
            ]);

        if ($this->executeDelete($qb) !== false) {
            $this->touchCart($idCart);
            return true;
        }
        return false;
    }

    private function touchCart(int $idCart): void
    {
        $qb = new QueryBuilder();
        $qb->update('mc_magixcartpay_cart', ['date_upd' => date('Y-m-d H:i:s')])
            ->where('id_cart = :id', ['id' => $idCart]);
        $this->executeUpdate($qb);
    }

    private function getCartById(int $idCart): array
    {
        $qb = new QueryBuilder();
        $qb->select('*')->from('mc_magixcartpay_cart')->where('id_cart = :id', ['id' => $idCart]);
        return $this->executeRow($qb) ?: [];
    }

    /**
     * Récupère le panier complet pour l'affichage (Jointures avec le catalogue)
     */
    public function getFullCartDetails(int $idLang): array
    {
        $cart = $this->getCurrentCart();
        $idCart = (int)$cart['id_cart'];

        $qb = new QueryBuilder();
        $qb->select([
            'ci.id_item', 'ci.quantity', 'ci.date_add',
            'p.id_product', 'p.reference_p', 'p.price_p', 'p.price_promo_p', // <--- AJOUT DE price_promo_p
            'pc.name_p', 'pc.url_p',
            'i.name_img'
        ])
            ->from('mc_magixcartpay_cart_item', 'ci')
            ->join('mc_catalog_product', 'p', 'ci.id_product = p.id_product')
            ->join('mc_catalog_product_content', 'pc', 'p.id_product = pc.id_product AND pc.id_lang = :id_lang')
            ->leftJoin('mc_catalog_product_img', 'i', 'p.id_product = i.id_product AND i.default_img = 1')
            ->where('ci.id_cart = :id_cart', [
                'id_cart' => $idCart,
                'id_lang' => $idLang
            ])
            ->orderBy('ci.date_add', 'ASC');

        $rawItems = $this->executeAll($qb) ?: [];

        $settingDb = new SettingDb();
        $siteSettings = $settingDb->fetchAllSettings();

        $taxRate = 21.00;
        if (isset($siteSettings['vat_rate']['value']) && is_numeric($siteSettings['vat_rate']['value'])) {
            $taxRate = (float)$siteSettings['vat_rate']['value'];
        }

        $items = [];
        $totalHt = 0.0;
        $totalItemsCount = 0;

        foreach ($rawItems as $row) {
            $qty = (int)$row['quantity'];

            // --- NOUVELLE LOGIQUE DE PRIX ---
            // On vérifie si un prix promo existe ET est supérieur à 0
            $priceBaseHt = (float)$row['price_p'];
            $pricePromoHt = isset($row['price_promo_p']) ? (float)$row['price_promo_p'] : 0.0;

            // Si la promo est active, c'est ce prix qui est utilisé
            $finalPriceHt = ($pricePromoHt > 0) ? $pricePromoHt : $priceBaseHt;

            // Calcul du total de la ligne
            $lineTotalHt = $finalPriceHt * $qty;

            $totalHt += $lineTotalHt;
            $totalItemsCount += $qty;

            $imageUrl = null;
            if (!empty($row['name_img'])) {
                $imageUrl = '/upload/product/' . $row['id_product'] . '/s_' . $row['name_img'];
            }

            $items[] = [
                'id_item'      => $row['id_item'],
                'id_product'   => $row['id_product'],
                'reference'    => $row['reference_p'],
                'name'         => $row['name_p'],
                'url'          => $row['url_p'],
                'image_url'    => $imageUrl,
                'quantity'     => $qty,
                'unit_price'   => $finalPriceHt, // <--- ON ASSIGNE LE BON PRIX ICI
                'original_price'=> $priceBaseHt, // (Optionnel) Pour afficher l'ancien prix barré dans le template
                'is_promo'     => ($pricePromoHt > 0), // (Optionnel) Pour un badge "Promo"
                'total_price'  => $lineTotalHt
            ];
        }

        $totalTax = $totalHt * ($taxRate / 100);
        $totalTtc = $totalHt + $totalTax;

        return [
            'cart_id'     => $idCart,
            'session_id'  => $cart['session_id'],
            'id_account'  => $cart['id_account'],
            'date_upd'    => $cart['date_upd'],
            'items'       => $items,
            'summary'     => [
                'items_count' => $totalItemsCount,
                'tax_rate'    => $taxRate,
                'total_ht'    => round($totalHt, 2),
                'total_tax'   => round($totalTax, 2),
                'total_ttc'   => round($totalTtc, 2)
            ]
        ];
    }
}