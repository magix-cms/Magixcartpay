<?php
declare(strict_types=1);

namespace Plugins\Magixcartpay\db;

use App\Backend\Db\BaseDb;
use Magepattern\Component\Database\QueryBuilder;
use Magepattern\Component\Tool\DateTool;

class MagixcartpayDb extends BaseDb
{
    /**
     * Récupère la configuration du plugin
     */
    public function getConfig(): array
    {
        $qb = new QueryBuilder();
        $qb->select('*')->from('mc_magixcartpay_config')->limit(1);
        $res = $this->executeRow($qb);

        return $res ?: [];
    }

    /**
     * Sauvegarde la configuration
     */
    public function saveConfig(array $data): bool
    {
        $config = $this->getConfig();
        $qb = new QueryBuilder();

        if (isset($config['id_config'])) {
            $qb->update('mc_magixcartpay_config', $data);
            return $this->executeUpdate($qb) !== false;
        } else {
            $qb->insert('mc_magixcartpay_config', $data);
            return $this->executeInsert($qb);
        }
    }

    /**
     * Récupère la liste paginée et filtrée de toutes les commandes
     */
    public function getOrdersList(int $page = 1, int $limit = 25, array $search = []): array|false
    {
        $qb = new QueryBuilder();

        $qb->select([
            'o.id_order',
            'o.reference',
            'o.type_doc',
            'o.status',
            'o.total_ttc',
            'o.date_add',
            "CONCAT_WS(' ', a.firstname, a.lastname) AS customer_name"
        ])
            ->from('mc_magixcartpay_order', 'o')
            ->leftJoin('mc_magixcartpay_order_address', 'a', 'o.id_order = a.id_order AND a.type_address = "billing"');

        if (!empty($search)) {
            $qb->orderBy('o.id_order', 'DESC');
            $nbc = 1;

            foreach ($search as $key => $q) {
                if ($q !== '') {
                    $paramName = 'p' . $nbc;
                    $binds = [];

                    switch ($key) {
                        case 'id_order':
                            $binds[$paramName] = $q;
                            $qb->where("o.id_order = :{$paramName}", $binds);
                            break;
                        case 'reference':
                            $binds[$paramName] = '%' . $q . '%';
                            $qb->where("o.reference LIKE :{$paramName}", $binds);
                            break;
                        case 'type_doc':
                            $binds[$paramName] = $q;
                            $qb->where("o.type_doc = :{$paramName}", $binds);
                            break;
                        case 'status':
                            $binds[$paramName] = $q;
                            $qb->where("o.status = :{$paramName}", $binds);
                            break;
                        case 'customer_name':
                            $binds[$paramName] = '%' . $q . '%';
                            $qb->where("CONCAT_WS(' ', a.firstname, a.lastname) LIKE :{$paramName}", $binds);
                            break;
                        case 'date_add':
                            // Si DateTool est dispo dans votre namespace Magix, sinon gardez $q simple
                            $formattedDate = class_exists('\Magepattern\Component\Tool\DateTool') ? DateTool::toSql((string)$q) : $q;
                            $binds[$paramName] = '%' . $formattedDate . '%';
                            $qb->where("o.date_add LIKE :{$paramName}", $binds);
                            break;
                    }
                    $nbc++;
                }
            }
        } else {
            $qb->orderBy('o.id_order', 'DESC');
        }

        return $this->executePaginatedQuery($qb, $page, $limit);
    }

    /**
     * Récupère le détail d'une commande passée (Lignes + Adresse)
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
     * Met à jour le statut d'une commande
     */
    public function updateOrderStatus(int $idOrder, string $status): bool
    {
        $qb = new QueryBuilder();
        $qb->update('mc_magixcartpay_order', ['status' => $status])
            ->where('id_order = :id', ['id' => $idOrder]);

        return $this->executeUpdate($qb) !== false;
    }

    /**
     * Supprime une commande et toutes ses données liées
     */
    public function deleteOrder(int $idOrder): bool
    {
        $qb = new QueryBuilder();
        $qb->delete('mc_magixcartpay_order')->where('id_order = :id', ['id' => $idOrder]);
        return $this->executeDelete($qb);
    }
    /**
     * Supprime les paniers non validés de plus de X jours
     */
    public function cleanAbandonedCarts(int $days = 7): int
    {
        $dateLimit = date('Y-m-d H:i:s', strtotime("-{$days} days"));

        $qb = new QueryBuilder();
        $qb->select('id_cart')->from('mc_magixcartpay_cart')->where('date_upd < :date', ['date' => $dateLimit]);
        $oldCarts = $this->executeAll($qb);

        if (empty($oldCarts)) return 0;

        $ids = array_column($oldCarts, 'id_cart');
        $idList = implode(',', array_map('intval', $ids));

        // Supprime les articles puis le panier
        $qbDelItems = new QueryBuilder();
        $qbDelItems->delete('mc_magixcartpay_cart_item')->where("id_cart IN ($idList)");
        $this->executeDelete($qbDelItems);

        $qbDelCarts = new QueryBuilder();
        $qbDelCarts->delete('mc_magixcartpay_cart')->where("id_cart IN ($idList)");
        $this->executeDelete($qbDelCarts);

        return count($ids);
    }
}