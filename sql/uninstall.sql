-- ========================================================
-- DÉSINSTALLATION DU PLUGIN MAGIXCARTPAY
-- ========================================================

-- 1. Suppression des adresses et lignes de commande (Enfants de Order)
DROP TABLE IF EXISTS `mc_magixcartpay_order_address`;
DROP TABLE IF EXISTS `mc_magixcartpay_order_item`;

-- 2. Suppression des lignes de panier (Enfants de Cart)
DROP TABLE IF EXISTS `mc_magixcartpay_cart_item`;

-- 3. Suppression des tables principales (Parents)
DROP TABLE IF EXISTS `mc_magixcartpay_order`;
DROP TABLE IF EXISTS `mc_magixcartpay_cart`;

-- 4. Suppression de la table de configuration
DROP TABLE IF EXISTS `mc_magixcartpay_config`;