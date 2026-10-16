<?php
declare(strict_types=1);

namespace Plugins\Magixcartpay\src;

use App\Frontend\Controller\BaseController;
use Plugins\Magixcartpay\src\Service\CartService;
use Plugins\Magixcartpay\src\Service\OrderService;
use Plugins\Magixcartpay\db\MagixcartpayFrontDb;
use Magepattern\Component\HTTP\Request;
use Magepattern\Component\Tool\FormTool;
use Magepattern\Component\Tool\SmartyTool;
use Magepattern\Component\Tool\StringTool;
use Magepattern\Component\Tool\MailTool;
use Magepattern\Component\HTTP\Session;

class FrontendController extends BaseController
{
    private Session $sessionManager;

    public function __construct()
    {
        parent::__construct();
        $this->sessionManager = new Session(true, 'magix_sess_id');
        $this->sessionManager->start();
    }

    public function run(): void
    {
        SmartyTool::addTemplateDir(
            'front',
            ROOT_DIR . 'plugins' . DS . 'Magixcartpay' . DS . 'views' . DS . 'front'
        );

        $action = Request::isGet('action') ? $_GET['action'] : 'view';

        switch ($action) {
            case 'add':
                $this->addToCart();
                break;
            case 'update':
                $this->updateQuantity();
                break;
            case 'remove':
                $this->removeItem();
                break;
            case 'checkout':
                $this->processCheckout();
                break;
            case 'history':
                $this->viewHistory();
                break;
            case 'order_detail':
                $this->viewOrderDetail();
                break;
            case 'view':
            default:
                $this->viewCart();
                break;
        }
    }

    /**
     * Action AJAX : Traite la validation de la commande, envoie les emails et protège via reCAPTCHA
     */
    private function processCheckout(): void
    {
        if (ob_get_length()) ob_clean();

        // 1. LE BOUCLIER HONEYPOT
        if (!empty($_POST['website_url'])) {
            $this->jsonResponse(true, 'Opération validée avec succès.', ['type' => 'success']);
        }

        // VÉRIFICATION SÉCURITÉ ESPACE MEMBRE
        $isAccountPluginActive = class_exists('\Plugins\Magixaccount\src\FrontendController');
        $idAccount = $this->sessionManager->get('id_account');

        if ($isAccountPluginActive && empty($idAccount)) {
            $this->jsonResponse(false, 'Vous devez être connecté à votre compte pour valider cette demande.');
        }

        // 2. RÉCUPÉRATION DU PANIER & DÉTERMINATION DU TYPE (Devis ou Commande)
        $idLang = (int)($this->currentLang['id_lang'] ?? 1);
        $cartService = new CartService();
        $fullCart = $cartService->getFullCartDetails($idLang);

        if (empty($fullCart['items'])) {
            $this->jsonResponse(false, 'Votre panier est vide.');
        }

        $frontDb = new MagixcartpayFrontDb();
        $config = $frontDb->getCartConfig();

        // LOGIQUE D'AFFICHAGE DU PANIER (Devis ou Vente)
        $typeDoc = 'order';
        if (!empty($config['quotation_enabled']) && empty($config['order_enabled'])) {
            $typeDoc = 'quotation';
        } elseif (!empty($config['quotation_enabled']) && !empty($config['order_enabled'])) {
            // MIXTE : On analyse les prix UNIQUEMENT si le panier n'est pas vide
            if (!empty($fullCart['items'])) {
                if ($fullCart['summary']['total_ttc'] <= 0) {
                    $typeDoc = 'quotation';
                } else {
                    foreach ($fullCart['items'] as $item) {
                        if ((float)$item['unit_price'] <= 0) {
                            $typeDoc = 'quotation';
                            break;
                        }
                    }
                }
            }
        }

        // 3. VÉRIFICATION DES MODULES EXTERNES (Paiement et Livraison)
        $paymentMethod = FormTool::simpleClean($_POST['payment_method'] ?? '');
        $shippingMethod = FormTool::simpleClean($_POST['shipping_method'] ?? 'pickup'); // <-- NOUVEAU
        $shippingPriceHt = (float)($_POST['shipping_price'] ?? 0.00);

        if ($typeDoc === 'order' && empty($paymentMethod)) {
            $this->jsonResponse(false, 'Veuillez sélectionner un moyen de paiement.');
        } elseif ($typeDoc === 'quotation') {
            $paymentMethod = 'quotation';
            $shippingMethod = 'none'; // <-- NOUVEAU
            $shippingPriceHt = 0.00;
        }

        // 4. VÉRIFICATION DES DONNÉES D'ADRESSE (Facturation)
        $address = [
            'firstname'  => FormTool::simpleClean($_POST['firstname'] ?? ''),
            'lastname'   => FormTool::simpleClean($_POST['lastname'] ?? ''),
            'email'      => FormTool::simpleClean($_POST['email'] ?? ''),
            'phone'      => FormTool::simpleClean($_POST['phone'] ?? ''),
            'company'    => FormTool::simpleClean($_POST['company'] ?? ''),
            'vat_number' => FormTool::simpleClean($_POST['vat_number'] ?? ''),
            'street'     => FormTool::simpleClean($_POST['street'] ?? ''),
            'postcode'   => FormTool::simpleClean($_POST['postcode'] ?? ''),
            'city'       => FormTool::simpleClean($_POST['city'] ?? ''),
            'country'    => FormTool::simpleClean($_POST['country'] ?? 'BE'),
        ];

        if (empty($address['firstname']) || empty($address['lastname']) || empty($address['email']) || empty($address['street'])) {
            $this->jsonResponse(false, 'Veuillez remplir tous les champs obligatoires de l\'adresse de facturation.');
        }

        if (!StringTool::isMail((string)$address['email'])) {
            $this->jsonResponse(false, 'L\'adresse e-mail renseignée est invalide.');
        }

        // 4 Bis. VÉRIFICATION ADRESSE DE LIVRAISON (Optionnelle) <-- NOUVEAU
        $shippingAddress = [];
        if (isset($_POST['different_shipping']) && $_POST['different_shipping'] == '1') {
            $shippingAddress = [
                'firstname'  => FormTool::simpleClean($_POST['shipping_firstname'] ?? ''),
                'lastname'   => FormTool::simpleClean($_POST['shipping_lastname'] ?? ''),
                'company'    => FormTool::simpleClean($_POST['shipping_company'] ?? ''),
                'street'     => FormTool::simpleClean($_POST['shipping_street'] ?? ''),
                'postcode'   => FormTool::simpleClean($_POST['shipping_postcode'] ?? ''),
                'city'       => FormTool::simpleClean($_POST['shipping_city'] ?? ''),
                'country'    => FormTool::simpleClean($_POST['shipping_country'] ?? 'BE'),
            ];

            // Si la case est cochée, ces champs deviennent obligatoires
            if (empty($shippingAddress['firstname']) || empty($shippingAddress['lastname']) || empty($shippingAddress['street'])) {
                $this->jsonResponse(false, 'Veuillez remplir tous les champs obligatoires de l\'adresse de livraison.');
            }
        }

        // 5. LE BOUCLIER GOOGLE RECAPTCHA v3
        $isHuman = true;
        if (class_exists('\Plugins\GoogleRecaptcha\src\FrontendController')) {
            $recaptcha = new \Plugins\GoogleRecaptcha\src\FrontendController();
            $isHuman = $recaptcha->verify('checkout');
        }

        if (!$isHuman) {
            $this->jsonResponse(false, 'La vérification de sécurité a échoué. Veuillez réessayer.');
        }

        // 6. TRANSFORMATION EN COMMANDE / DEVIS
        $orderService = new OrderService();

        // <-- NOUVEAU : On passe $shippingMethod et $shippingAddress au Service !
        $reference = $orderService->convertCartToOrder($idLang, $address, $paymentMethod, $typeDoc, $shippingPriceHt, $shippingMethod, $shippingAddress);

        if ($reference) {
            $this->sendOrderEmails($reference, $address, $fullCart, $config, $typeDoc, $paymentMethod);

            $baseUrl = rtrim((string)$this->view->getTemplateVars('site_url'), '/');
            $iso = strtolower($this->currentLang['iso_lang'] ?? 'fr');
            $successUrl = $baseUrl . '/' . $iso . '/magixcartpay/view?success=' . $reference;

            $this->jsonResponse(true, 'Opération validée avec succès.', ['redirect' => $successUrl]);
        } else {
            $this->jsonResponse(false, 'Une erreur est survenue.');
        }
    }

    private function sendOrderEmails(string $reference, array $address, array $cartData, array $config, string $typeDoc, string $paymentMethod): void{
        {
            $isSmtp = isset($this->siteSettings['smtp_enabled']['value']) && $this->siteSettings['smtp_enabled']['value'] == '1';
            $type = $isSmtp ? 'smtp' : 'mail';

            $options = [
                'setHost'       => $this->siteSettings['set_host']['value'] ?? '',
                'setPort'       => (int)($this->siteSettings['set_port']['value'] ?? 25),
                'setEncryption' => $this->siteSettings['set_encryption']['value'] ?? '',
                'setUsername'   => $this->siteSettings['set_username']['value'] ?? '',
                'setPassword'   => $this->siteSettings['set_password']['value'] ?? '',
            ];

            $mailer = new MailTool($type, $options);

            $emailData = [
                'reference'      => $reference,
                'address'        => $address,
                'cart'           => $cartData,
                'type_doc'       => $typeDoc,
                'config'         => $config,
                'payment_method' => $paymentMethod // <-- NOUVEAU
            ];

            $fullName = trim($address['firstname'] . ' ' . $address['lastname']);
            $senderEmail = !empty($config['email_sender']) ? $config['email_sender'] : ($this->siteSettings['mail_sender']['value'] ?? 'noreply@votresite.com');
            $contactEmail = !empty($config['email_contact']) ? $config['email_contact'] : $senderEmail;

            $subjectPrefix = ($typeDoc === 'order') ? 'Confirmation de votre commande' : 'Confirmation de votre demande de devis';
            $clientSubject = $subjectPrefix . ' - ' . $reference;
            $adminSubject  = 'Nouvelle ' . ($typeDoc === 'order' ? 'commande' : 'demande de devis') . ' : ' . $reference;

            try {
                $mailer->sendTemplate(
                    'front',
                    'emails/order_confirmation.tpl',
                    $emailData,
                    $clientSubject,
                    'Service Commercial <' . $senderEmail . '>',
                    [$address['email'] => $fullName],
                    [],
                    $senderEmail
                );

                $mailer->sendTemplate(
                    'front',
                    'emails/order_admin_notification.tpl',
                    $emailData,
                    $adminSubject,
                    'Site Web <' . $senderEmail . '>',
                    [$contactEmail => 'Administrateur'],
                    [],
                    $senderEmail
                );
            } catch (\Throwable $e) {
                $this->logger->log("Erreur SMTP ({$reference}) : " . $e->getMessage(), "error");
            }
        }
    }

    private function addToCart(): void
    {
        if (ob_get_length()) ob_clean();

        $idProduct = Request::isPost('id_product') ? (int)$_POST['id_product'] : 0;
        $quantity = Request::isPost('quantity') ? (int)$_POST['quantity'] : 1;

        if ($idProduct <= 0 || $quantity <= 0) {
            $this->jsonResponse(false, 'Produit ou quantité invalide.');
        }

        $cartService = new CartService();
        if ($cartService->addItem($idProduct, $quantity)) {
            $this->jsonResponse(true, 'Produit ajouté au panier.');
        } else {
            $this->jsonResponse(false, 'Erreur lors de l\'ajout.');
        }
    }

    private function updateQuantity(): void
    {
        if (ob_get_length()) ob_clean();

        $idItem = Request::isPost('id_item') ? (int)$_POST['id_item'] : 0;
        $quantity = Request::isPost('quantity') ? (int)$_POST['quantity'] : 1;

        if ($idItem <= 0 || $quantity <= 0) {
            $this->jsonResponse(false, 'Données invalides.');
        }

        $cartService = new CartService();
        if ($cartService->updateItemQuantity($idItem, $quantity)) {
            $this->jsonResponse(true, 'Quantité mise à jour.', ['reload' => true]);
        } else {
            $this->jsonResponse(false, 'Erreur de mise à jour.');
        }
    }

    private function removeItem(): void
    {
        if (ob_get_length()) ob_clean();

        $idItem = Request::isPost('id_item') ? (int)$_POST['id_item'] : 0;

        if ($idItem <= 0) {
            $this->jsonResponse(false, 'ID invalide.');
        }

        $cartService = new CartService();
        if ($cartService->removeItem($idItem)) {
            $this->jsonResponse(true, 'Article retiré.', ['reload' => true]);
        } else {
            $this->jsonResponse(false, 'Erreur de suppression.');
        }
    }

    private function viewCart(): void
    {
        if (isset($_GET['success'])) {
            $this->view->assign('seo_title', 'Demande validée');
            $this->view->display('success.tpl');
            return;
        }

        // VÉRIFICATION DE LA PRÉSENCE DE MAGIXACCOUNT
        // Si le plugin Magixaccount est installé, on exige que le client soit connecté pour voir le panier
        $isAccountPluginActive = class_exists('\Plugins\Magixaccount\src\FrontendController');
        $idAccount = $this->sessionManager->get('id_account');

        if ($isAccountPluginActive && empty($idAccount)) {
            $baseUrl = rtrim((string)$this->view->getTemplateVars('site_url'), '/');
            $iso = strtolower($this->currentLang['iso_lang'] ?? 'fr');

            // Redirection vers la page de login de Magixaccount
            header('Location: ' . $baseUrl . '/' . $iso . '/magixaccount/login');
            exit;
        }

        $idLang = (int)($this->currentLang['id_lang'] ?? 1);
        $cartService = new CartService();
        $fullCart = $cartService->getFullCartDetails($idLang);

        $frontDb = new MagixcartpayFrontDb();
        $config = $frontDb->getCartConfig();

        // LOGIQUE D'AFFICHAGE DU PANIER (Devis ou Vente)
        $typeDoc = 'order';
        if (!empty($config['quotation_enabled']) && empty($config['order_enabled'])) {
            $typeDoc = 'quotation';
        } elseif (!empty($config['quotation_enabled']) && !empty($config['order_enabled'])) {
            if (!empty($fullCart['items'])) {
                if ($fullCart['summary']['total_ttc'] <= 0) {
                    $typeDoc = 'quotation';
                } else {
                    foreach ($fullCart['items'] as $item) {
                        if ((float)$item['unit_price'] <= 0) {
                            $typeDoc = 'quotation';
                            break;
                        }
                    }
                }
            }
        }

        // Pré-remplissage profil
        $accountProfile = [];
        if (!empty($idAccount)) {
            $accountProfile = $frontDb->getAccountProfile((int)$idAccount);
        }

        $this->view->assign([
            'cart'           => $fullCart,
            'cart_type_doc'  => $typeDoc,
            'accountProfile' => $accountProfile,
            'seo_title'      => ($typeDoc === 'quotation') ? 'Demande de devis' : 'Mon Panier',
            // ---> AJOUT : On passe la config complète à Smarty pour lire 'bank_wire'
            'cart_config'    => $config
        ]);

        $this->view->caching = 0;

        // Informe Magix CMS qu'il peut charger les modules de paiement/livraison
        $this->initPluginsAddons();

        $this->view->display('index.tpl');
    }

    public static function renderWidget(): string
    {
        $view = SmartyTool::getInstance('front');
        $cartService = new CartService();

        $langVars = $view->getTemplateVars('current_lang');
        $idLang = isset($langVars['id_lang']) ? (int)$langVars['id_lang'] : 1;

        $cartData = $cartService->getFullCartDetails($idLang);

        $view->assign('cart_summary', $cartData['summary']);
        $view->caching = 0;

        return $view->fetch(ROOT_DIR . 'plugins/Magixcartpay/views/front/hooks/cart_widget.tpl');
    }

    public static function renderAddToCartWidget(array $params = []): string
    {
        $idProduct = (int)($params['id_product'] ?? 0);
        if ($idProduct <= 0) {
            return '';
        }

        $view = SmartyTool::getInstance('front');
        $baseUrl = rtrim((string)$view->getTemplateVars('site_url'), '/');
        $langVars = $view->getTemplateVars('current_lang');
        $iso = strtolower($langVars['iso_lang'] ?? 'fr');

        $view->assign([
            'product_cart_id' => $idProduct,
            'cart_add_url'    => $baseUrl . '/' . $iso . '/magixcartpay/add'
        ]);

        return $view->fetch(ROOT_DIR . 'plugins/Magixcartpay/views/front/hooks/add_to_cart_widget.tpl');
    }

    private function viewHistory(): void
    {
        $idAccount = $this->sessionManager->get('id_account');
        if (!$idAccount) {
            $baseUrl = rtrim((string)$this->view->getTemplateVars('site_url'), '/');
            header('Location: ' . $baseUrl . '/');
            exit;
        }

        $db = new \Plugins\Magixcartpay\db\MagixcartpayFrontDb();
        $this->view->assign([
            'orders'    => $db->getOrdersByAccount((int)$idAccount),
            'seo_title' => 'Mes commandes'
        ]);

        $this->view->display('history.tpl');
    }

    private function viewOrderDetail(): void
    {
        $idAccount = $this->sessionManager->get('id_account');
        $idOrder = (int)($_GET['id_order'] ?? 0);

        if (!$idAccount || $idOrder <= 0) {
            $baseUrl = rtrim((string)$this->view->getTemplateVars('site_url'), '/');
            header('Location: ' . $baseUrl . '/');
            exit;
        }

        $db = new \Plugins\Magixcartpay\db\MagixcartpayFrontDb();
        $order = $db->getOrderDetails($idOrder, (int)$idAccount);

        if (!$order) {
            $baseUrl = rtrim((string)$this->view->getTemplateVars('site_url'), '/');
            header('Location: ' . $baseUrl . '/');
            exit;
        }

        $this->view->assign([
            'order'     => $order,
            'seo_title' => 'Détail de la commande ' . $order['reference']
        ]);

        $this->view->display('order_detail.tpl');
    }

    public static function hookAccountProfileMenu(array $params = []): string
    {
        $idAccount = (int)($params['id_account'] ?? 0);
        if ($idAccount <= 0) return '';

        $view = \Magepattern\Component\Tool\SmartyTool::getInstance('front');
        $baseUrl = rtrim((string)$view->getTemplateVars('site_url'), '/');
        $langVars = $view->getTemplateVars('current_lang');
        $iso = strtolower($langVars['iso_lang'] ?? 'fr');

        $view->assign('history_url', $baseUrl . '/' . $iso . '/?controller=Magixcartpay&action=history');

        return $view->fetch(ROOT_DIR . 'plugins/Magixcartpay/views/front/hooks/account_menu.tpl');
    }

    public static function hookAccountProfileContent(array $params = []): string
    {
        $idAccount = (int)($params['id_account'] ?? 0);
        if ($idAccount <= 0) return '';

        $db = new MagixcartpayFrontDb();
        $orders = $db->getOrdersByAccount($idAccount);
        $recentOrders = array_slice($orders, 0, 5);

        $view = \Magepattern\Component\Tool\SmartyTool::getInstance('front');
        $baseUrl = rtrim((string)$view->getTemplateVars('site_url'), '/');
        $langVars = $view->getTemplateVars('current_lang');
        $iso = strtolower($langVars['iso_lang'] ?? 'fr');

        $view->assign([
            'recent_orders' => $recentOrders,
            'history_url'   => $baseUrl . '/' . $iso . '/?controller=Magixcartpay&action=history',
            'detail_url'    => $baseUrl . '/' . $iso . '/?controller=Magixcartpay&action=order_detail'
        ]);

        return $view->fetch(ROOT_DIR . 'plugins/Magixcartpay/views/front/hooks/account_content.tpl');
    }

    /**
     * Fonction Smarty personnalisée : {has_purchased id_product=X assign="var"}
     */
    public static function smartyHasPurchased(array $params, $smarty)
    {
        $idProduct = (int)($params['id_product'] ?? 0);
        $hasPurchased = false;

        if ($idProduct > 0) {
            // Vérification de la session Magixaccount
            $session = new \Magepattern\Component\HTTP\Session(true, 'magix_sess_id');
            $session->start();
            $idAccount = (int)$session->get('id_account');

            if ($idAccount > 0) {
                $db = new \Plugins\Magixcartpay\db\MagixcartpayFrontDb();
                $hasPurchased = $db->hasPurchasedProduct($idAccount, $idProduct);
            }
        }

        // Si l'utilisateur demande à assigner le résultat à une variable (recommandé)
        if (isset($params['assign'])) {
            $smarty->assign($params['assign'], $hasPurchased);
            return '';
        }

        return $hasPurchased;
    }

    /**
     * Initialise et enregistre les hooks des addons liés à Magixcartpay (Paiement, Livraison)
     */
    private function initPluginsAddons(): void
    {
        try {
            $db = new MagixcartpayFrontDb();
            // On récupère la liste des noms de plugins qui sont liés à Magixcartpay et activés
            $activeAddonsNames = $db->getActiveAddonsForCart();

            foreach ($activeAddonsNames as $pluginName) {
                $bootClass = "Plugins\\" . $pluginName . "\\Boot";

                if (class_exists($bootClass)) {
                    $bootInstance = new $bootClass();
                    if (method_exists($bootInstance, 'register')) {
                        $bootInstance->register();
                    }
                }
            }
        } catch (\Throwable $e) {
            $this->logger->log("Erreur chargement addons Magixcartpay : " . $e->getMessage(), "error");
        }
    }
}