{extends file="layout.tpl"}

{block name='head:title'}Configuration MagixCartpay{/block}

{block name='article'}
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="h3 mb-0 text-gray-800">
            <i class="bi bi-gear-fill text-primary me-2"></i> Configuration E-commerce
        </h1>
        <a href="index.php?controller=Magixcartpay" class="btn btn-outline-secondary">
            <i class="bi bi-arrow-left me-1"></i> Retour aux commandes
        </a>
    </div>

    <form action="index.php?controller=Magixcartpay&action=save_config" method="post" class="validate_form">
        <input type="hidden" name="hashtoken" value="{$hashtoken|default:''}">

        <div class="row g-4">
            {* Colonne 1 : Options globales *}
            <div class="col-md-6">
                <div class="card shadow-sm border-0 h-100">
                    <div class="card-header bg-white py-3">
                        <h6 class="m-0 fw-bold text-dark"><i class="bi bi-toggles me-2"></i> Options du module</h6>
                    </div>
                    <div class="card-body">
                        <div class="form-check form-switch mb-3">
                            <input class="form-check-input" type="checkbox" id="order_enabled" name="order_enabled" value="1" {if $config.order_enabled|default:0 == 1}checked{/if}>
                            <label class="form-check-label fw-bold" for="order_enabled">Activer le module E-commerce (Vente)</label>
                        </div>

                        <div class="form-check form-switch mb-4">
                            <input class="form-check-input" type="checkbox" id="quotation_enabled" name="quotation_enabled" value="1" {if $config.quotation_enabled|default:1 == 1}checked{/if}>
                            <label class="form-check-label fw-bold" for="quotation_enabled">Activer le module Devis</label>
                        </div>

                        <div class="mb-4">
                            <label class="form-label fw-bold">Affichage des prix (Panier Front-end)</label>
                            <select class="form-select" name="price_display">
                                <option value="ttc" {if $config.price_display|default:'ttc' == 'ttc'}selected{/if}>Prix TTC (Toutes Taxes Comprises)</option>
                                <option value="htva" {if $config.price_display|default:'ttc' == 'htva'}selected{/if}>Prix HTVA (Hors Taxes)</option>
                            </select>
                        </div>

                        <hr>
                        <h6 class="fw-bold mb-3"><i class="bi bi-envelope me-2"></i> Communication (Emails)</h6>

                        <div class="mb-3">
                            <label class="form-label">Email de contact (Reçoit les copies de commande)</label>
                            <input type="email" class="form-control" name="email_contact" value="{$config.email_contact|default:''}">
                        </div>
                        <div class="mb-3">
                            <label class="form-label">Email expéditeur (Envoie les confirmations aux clients)</label>
                            <input type="email" class="form-control" name="email_sender" value="{$config.email_sender|default:''}">
                        </div>
                    </div>
                </div>
            </div>

            {* Colonne 2 : Virement bancaire *}
            <div class="col-md-6">
                <div class="card shadow-sm border-0 h-100 border-start border-success border-4">
                    <div class="card-header bg-white py-3">
                        <h6 class="m-0 fw-bold text-success"><i class="bi bi-bank me-2"></i> Virement Bancaire Natif</h6>
                    </div>
                    <div class="card-body">
                        <div class="form-check form-switch mb-4">
                            <input class="form-check-input" type="checkbox" id="bank_wire" name="bank_wire" value="1" {if $config.bank_wire|default:0 == 1}checked{/if}>
                            <label class="form-check-label fw-bold" for="bank_wire">Activer le paiement par Virement Bancaire</label>
                        </div>

                        <div class="mb-3">
                            <label class="form-label fw-bold">Titulaire du compte</label>
                            <input type="text" class="form-control" name="account_owner" value="{$config.account_owner|default:''|escape}">
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-bold">IBAN / Numéro de compte</label>
                            <input type="text" class="form-control" name="bank_account" value="{$config.bank_account|default:''|escape}">
                        </div>
                        <div class="mb-3">
                            <label class="form-label fw-bold">Nom et Adresse de la banque</label>
                            <textarea class="form-control" name="bank_address" rows="4">{$config.bank_address|default:''|escape}</textarea>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="card mt-4 shadow-sm border-0">
            <div class="card-body text-end bg-light">
                <button type="submit" class="btn btn-primary px-4 fw-bold">
                    <i class="bi bi-save me-2"></i> Enregistrer la configuration
                </button>
            </div>
        </div>
    </form>
{/block}

{block name="javascripts" append}
    <script src="templates/js/MagixFormTools.min.js?v={$smarty.now}"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            new MagixFormTools();
        });
    </script>
{/block}