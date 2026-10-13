<?php
declare(strict_types=1);

namespace Plugins\Magixcartpay\src;

use App\Backend\Controller\BaseController;
use Plugins\Magixcartpay\db\MagixcartpayDb;
use Magepattern\Component\HTTP\Request;
use Magepattern\Component\Tool\FormTool;
use Magepattern\Component\Tool\SmartyTool;

class BackendController extends BaseController
{
    public function run(): void
    {
        SmartyTool::addTemplateDir('admin', ROOT_DIR . 'plugins' . DS . 'Magixcartpay' . DS . 'views' . DS . 'admin');

        $action =$_GET['action'] ?? null;

        if (isset($_GET['edit'])) {$action = 'edit';
        }
        if ($action === 'clean_carts') {
            $this->processCleanCarts();
            return;
        }

        if ($action === 'save_config' && Request::isMethod('POST')) {$this->processSaveConfig();
            return;
        }

        if ($action === 'update_status' && Request::isMethod('POST')) {$this->processUpdateStatus();
            return;
        }

        if ($action === 'delete') {$this->processDelete();
            return;
        }

        if ($action && method_exists($this,$action)) {
            $this->$action();
            return;
        }

        $this->index();
    }

    /**
     * Liste les commandes (Point d'entrée par défaut)
     */
    public function index(): void
    {
        $db = new MagixcartpayDb();

        // 1. Schéma pour le composant table-forms
        $targetColumns = ['id_order', 'reference', 'type_doc', 'customer_name', 'total_ttc', 'status', 'date_add'];$rawScheme = $db->getTableScheme('mc_magixcartpay_order');$rawScheme[] = ['column' => 'customer_name', 'type' => 'varchar(255)'];

        $associations = [
            'id_order' => [
                'title' => 'id', 'type' => 'text', 'class' => 'text-center text-muted small px-4',
                'input' => ['type' => 'text']
            ],
            'reference' => [
                'title' => 'Référence', 'type' => 'text', 'class' => 'fw-bold',
                'input' => ['type' => 'text']
            ],
            'type_doc' => [
                'title' => 'Type', 'type' => 'enum', 'class' => 'text-center px-3', 'enum' => 'doc_',
                'input' => [
                    'type' => 'select',
                    'values' => [['v' => 'order', 'name' => 'Vente'], ['v' => 'quotation', 'name' => 'Devis']]
                ]
            ],
            'customer_name' => [
                'title' => 'Client', 'type' => 'text', 'class' => '',
                'input' => ['type' => 'text']
            ],
            'total_ttc' => [
                'title' => 'Total', 'type' => 'price', 'class' => 'text-end fw-bold text-success',
                'input' => ['type' => 'text']
            ],
            'status' => [
                'title' => 'Statut', 'type' => 'enum', 'class' => 'text-center px-3', 'enum' => 'order_',
                'input' => [
                    'type' => 'select',
                    'values' => [
                        ['v' => 'pending', 'name' => 'En attente'],
                        ['v' => 'paid', 'name' => 'Payée'],
                        ['v' => 'shipped', 'name' => 'Expédiée'],
                        ['v' => 'canceled', 'name' => 'Annulée']
                    ]
                ]
            ],
            'date_add' => [
                'title' => 'Date', 'type' => 'date', 'class' => 'text-center text-nowrap text-muted small',
                'input' => ['type' => 'text', 'placeholder' => 'JJ/MM/AAAA']
            ]
        ];

        $this->getScheme($rawScheme, $targetColumns,$associations);

        // 2. Récupération et Pagination
        $page   = Request::isGet('page') ? (int)($_GET['page']) : 1;
        $limit  = Request::isGet('offset') ? (int)($_GET['offset']) : 25;
        $search =$_GET['search'] ?? [];

        $result = $db->getOrdersList($page, $limit,$search);

        $meta = [];
        if ($result !== false) {$this->getItems('ordersList', $result['data'], true,$result['meta']);
            $meta =$result['meta'];
        }

        // 3. Assignation
        $token = $this->session->getToken();$this->view->assign([
        'idcolumn'   => 'id_order',
        'hashtoken'  => $token,
        'url_token'  => urlencode($token),
        'get_search' => $search,
        'sortable'   => false,
        'checkbox'   => true,
        'edit'       => true,
        'dlt'        => true,
        'meta'       => $meta
    ]);

        $this->view->display('index.tpl');
    }

    /**
     * Affiche le détail d'une commande
     */
    /**
     * Affiche le détail d'une commande
     */
    public function edit(): void
    {
        $idOrder = (int)($_GET['edit'] ?? $_GET['id_order'] ?? 0);

        if ($idOrder <= 0) {
            header('Location: index.php?controller=Magixcartpay');
            exit;
        }

        $db = new MagixcartpayDb();
        $this->view->assign([
            'order'     => $db->getOrderDetails($idOrder),
            'hashtoken' => $this->session->getToken()
        ]);

        $this->view->display('edit.tpl');
    }

    /**
     * Page de configuration
     */
    public function config(): void
    {
        $db = new MagixcartpayDb();$this->view->assign([
        'config'    => $db->getConfig(),
        'hashtoken' => $this->session->getToken()
    ]);
        $this->view->display('config.tpl');
    }

    private function processSaveConfig(): void
    {
        if (ob_get_length()) ob_clean();

        $token =$_POST['hashtoken'] ?? '';
        if (!$this->session->validateToken($token)) {$this->jsonResponse(false, 'Session expirée.');
        }

        $data = [
            'quotation_enabled' => isset($_POST['quotation_enabled']) ? 1 : 0,
            'order_enabled'     => isset($_POST['order_enabled']) ? 1 : 0,             'bank_wire'         => isset($_POST['bank_wire']) ? 1 : 0,
            'price_display'     => in_array($_POST['price_display'] ?? '', ['htva', 'ttc']) ?$_POST['price_display'] : 'ttc',
            'account_owner'     => FormTool::simpleClean($_POST['account_owner'] ?? ''),
            'bank_account'      => FormTool::simpleClean($_POST['bank_account'] ?? ''),
            'bank_address'      => FormTool::simpleClean($_POST['bank_address'] ?? ''),
            'email_contact'     => FormTool::simpleClean($_POST['email_contact'] ?? ''),
            'email_sender'      => FormTool::simpleClean($_POST['email_sender'] ?? '')
        ];

        $db = new MagixcartpayDb();
        if ($db->saveConfig($data)) {$this->jsonResponse(true, 'Configuration enregistrée.', ['type' => 'update']);
        } else {
            $this->jsonResponse(false, 'Erreur lors de l\'enregistrement.');
        }
    }

    /**
     * Change le statut de la commande depuis l'interface `edit.tpl`
     */
    private function processUpdateStatus(): void
    {
        if (ob_get_length()) ob_clean();

        $token =$_POST['hashtoken'] ?? '';
        if (!$this->session->validateToken($token)) {$this->jsonResponse(false, 'Session expirée.');
        }

        $idOrder = (int)($_POST['id_order'] ?? 0);
        $status = FormTool::simpleClean($_POST['status'] ?? '');

        if ($idOrder > 0 && in_array($status, ['pending', 'paid', 'failed', 'shipped', 'canceled'])) {
            $db = new MagixcartpayDb();
            if ($db->updateOrderStatus($idOrder, $status)) {
                // On ajoute 'reload' => true dans le tableau de réponse
                // MagixForms.js l'interceptera et rechargera la page après 1.5s
                $this->jsonResponse(true, 'Le statut de la commande a été mis à jour.', [
                    'type' => 'update',
                    'reload' => true
                ]);
            }
        }
        $this->jsonResponse(false, 'Erreur lors de la mise à jour.');
    }

    private function processDelete(): void
    {
        if (ob_get_length()) ob_clean();

        $ids = $_POST['ids'] ?? [$_POST['id'] ?? null];
        $cleanIds = array_filter(array_map('intval', (array)$ids));

        if (!empty($cleanIds)) {
            $db = new MagixcartpayDb();$successCount = 0;

            foreach ($cleanIds as$idOrder) {
                if ($db->deleteOrder($idOrder)) {$successCount++;
                }
            }

            if ($successCount > 0) {
                $msg =$successCount > 1 ? 'Les commandes ont été supprimées.' : 'La commande a été supprimée.';
                echo $this->json->encode(['success' => true, 'message' => $msg, 'ids' =>$cleanIds]);
                exit;
            }
        }
        echo $this->json->encode(['success' => false, 'message' => 'Aucune commande sélectionnée.']);
        exit;
    }

    /**
     * @return void
     */
    private function processCleanCarts(): void
    {
        if (ob_get_length()) ob_clean();
        $db = new MagixcartpayDb();
        $deletedCount = $db->cleanAbandonedCarts(7); // Supprime ceux de plus de 7 jours
        $this->jsonResponse(true, "Nettoyage terminé : {$deletedCount} panier(s) abandonné(s) supprimé(s).", ['type' => 'success']);
    }
}