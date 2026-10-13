-- ========================================================
-- 1. CONFIGURATION DU PLUGIN
-- ========================================================
CREATE TABLE IF NOT EXISTS `mc_magixcartpay_config` (
    `id_config` SMALLINT(3) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `quotation_enabled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    `order_enabled` TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    `bank_wire` TINYINT(1) NOT NULL DEFAULT 0,
    `account_owner` VARCHAR(100) DEFAULT NULL,
    `bank_account` VARCHAR(50) DEFAULT NULL,
    `bank_address` VARCHAR(150) DEFAULT NULL,
    `email_contact` VARCHAR(150) DEFAULT NULL,
    `email_sender` VARCHAR(150) DEFAULT NULL,
    `price_display` ENUM('htva', 'ttc') NOT NULL DEFAULT 'ttc'
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `mc_magixcartpay_config` (`quotation_enabled`) VALUES (1);

-- ========================================================
-- 2. PANIERS ÉPHÉMÈRES (En cours d'achat)
-- ========================================================
CREATE TABLE IF NOT EXISTS `mc_magixcartpay_cart` (
    `id_cart` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `session_id` VARCHAR(128) NOT NULL,
    `id_account` INT(11) UNSIGNED DEFAULT NULL,
    `date_add` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `date_upd` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX (`session_id`),
    INDEX (`id_account`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `mc_magixcartpay_cart_item` (
    `id_item` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_cart` INT(11) UNSIGNED NOT NULL,
    `id_product` INT(11) UNSIGNED NOT NULL,
    `quantity` SMALLINT(5) UNSIGNED NOT NULL DEFAULT 1,
    `date_add` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_magixcartpay_item` FOREIGN KEY (`id_cart`) REFERENCES `mc_magixcartpay_cart`(`id_cart`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================================
-- 3. COMMANDES ET DEVIS (Archives immuables)
-- ========================================================
CREATE TABLE IF NOT EXISTS `mc_magixcartpay_order` (
    `id_order` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `reference` VARCHAR(20) NOT NULL UNIQUE,
    `id_account` INT(11) UNSIGNED DEFAULT NULL,
    `type_doc` ENUM('order', 'quotation') NOT NULL DEFAULT 'order',
    `status` ENUM('pending', 'paid', 'failed', 'shipped', 'canceled') NOT NULL DEFAULT 'pending',
    `payment_method` VARCHAR(50) DEFAULT NULL,
    `shipping_method` VARCHAR(100) NULL DEFAULT 'pickup',
    `transaction_id` VARCHAR(100) DEFAULT NULL,
    `total_products_ht` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `total_shipping_ht` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `total_tax` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `total_ttc` DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    `currency` VARCHAR(3) NOT NULL DEFAULT 'EUR',
    `date_add` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `date_upd` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX (`reference`),
    INDEX (`id_account`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================================
-- 4. LIGNES DE COMMANDE (Snapshot des produits)
-- ========================================================
CREATE TABLE IF NOT EXISTS `mc_magixcartpay_order_item` (
    `id_order_item` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_order` INT(11) UNSIGNED NOT NULL,
    `id_product` INT(11) UNSIGNED DEFAULT NULL,
    `product_reference` VARCHAR(50) DEFAULT NULL,
    `product_name` VARCHAR(255) NOT NULL,
    `quantity` SMALLINT(5) UNSIGNED NOT NULL,
    `unit_price_ht` DECIMAL(12,2) NOT NULL,
    `tax_rate` DECIMAL(5,2) NOT NULL,
    `total_ttc` DECIMAL(12,2) NOT NULL,
    CONSTRAINT `fk_magixcartpay_order_item` FOREIGN KEY (`id_order`) REFERENCES `mc_magixcartpay_order`(`id_order`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ========================================================
-- 5. ADRESSES DE COMMANDE (Snapshot)
-- ========================================================
CREATE TABLE IF NOT EXISTS `mc_magixcartpay_order_address` (
    `id_address` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `id_order` INT(11) UNSIGNED NOT NULL,
    `type_address` ENUM('billing', 'shipping') NOT NULL DEFAULT 'billing',
    `company` VARCHAR(100) DEFAULT NULL,
    `vat_number` VARCHAR(50) DEFAULT NULL,
    `firstname` VARCHAR(100) NOT NULL,
    `lastname` VARCHAR(100) NOT NULL,
    `email` VARCHAR(150) NOT NULL,
    `phone` VARCHAR(50) DEFAULT NULL,
    `street` VARCHAR(255) NOT NULL,
    `postcode` VARCHAR(20) NOT NULL,
    `city` VARCHAR(100) NOT NULL,
    `country` VARCHAR(50) NOT NULL,
    CONSTRAINT `fk_magixcartpay_address` FOREIGN KEY (`id_order`) REFERENCES `mc_magixcartpay_order`(`id_order`) ON DELETE CASCADE
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;