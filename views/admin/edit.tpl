{extends file="layout.tpl"}

{block name='head:title'}Détail de la commande {$order.reference}{/block}

{block name="article"}
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="h3 mb-0 text-gray-800">
            <i class="bi bi-receipt me-2"></i>
            {if $order.type_doc == 'order'}Commande{else}Devis{/if} {$order.reference}
        </h1>
        <a href="index.php?controller=Magixcartpay" class="btn btn-outline-secondary">
            <i class="bi bi-arrow-left me-1"></i> Retour à la liste
        </a>
    </div>

    <div class="row g-4">
        {* --- INFO CLIENT & ADRESSE --- *}
        <div class="col-md-4">
            <div class="row g-4">
                {* Adresse de facturation *}
                <div class="{if !empty($order.shipping_address)}col-12{else}col-12{/if}">
                    <div class="card shadow-sm border-0 h-100">
                        <div class="card-header bg-white py-3">
                            <h6 class="m-0 fw-bold text-primary"><i class="bi bi-person-lines-fill me-2"></i> Client & Facturation</h6>
                        </div>
                        <div class="card-body">
                            {if !empty($order.billing_address.company)}
                                <div class="fw-bold">{$order.billing_address.company}</div>
                                {if !empty($order.billing_address.vat_number)}
                                    <div class="text-muted small">TVA : {$order.billing_address.vat_number}</div>
                                {/if}
                                <hr class="my-2 text-muted">
                            {/if}

                            <div class="fw-bold text-dark">{$order.billing_address.firstname} {$order.billing_address.lastname}</div>
                            <div class="mb-2"><a href="mailto:{$order.billing_address.email}" class="text-decoration-none">{$order.billing_address.email}</a></div>

                            {if !empty($order.billing_address.phone)}
                                <div class="mb-3"><i class="bi bi-telephone text-muted me-1"></i> {$order.billing_address.phone}</div>
                            {/if}

                            <div class="bg-light p-3 rounded text-dark small mt-3">
                                <i class="bi bi-geo-alt-fill text-muted me-1"></i> <strong>Adresse :</strong><br>
                                {$order.billing_address.street}<br>
                                {$order.billing_address.postcode} {$order.billing_address.city}<br>
                                {$order.billing_address.country}
                            </div>
                        </div>
                    </div>
                </div>

                {* Adresse de livraison (affichée uniquement si elle existe en base de données) *}
                {if !empty($order.shipping_address)}
                <div class="col-12">
                    <div class="card shadow-sm border-0 h-100 border-start border-4 border-success">
                        <div class="card-header bg-white py-3">
                            <h6 class="m-0 fw-bold text-success"><i class="bi bi-truck me-2"></i> Adresse de livraison</h6>
                        </div>
                        <div class="card-body">
                            {if !empty($order.shipping_address.company)}
                                <div class="fw-bold">{$order.shipping_address.company}</div>
                                <hr class="my-2 text-muted">
                            {/if}

                            <div class="fw-bold text-dark">{$order.shipping_address.firstname} {$order.shipping_address.lastname}</div>

                            <div class="bg-light p-3 rounded text-dark small mt-3">
                                <i class="bi bi-geo-alt-fill text-muted me-1"></i> <strong>Adresse :</strong><br>
                                {$order.shipping_address.street}<br>
                                {$order.shipping_address.postcode} {$order.shipping_address.city}<br>
                                {$order.shipping_address.country}
                            </div>
                        </div>
                    </div>
                </div>
                {/if}
            </div>
        </div>

        {* --- INFO COMMANDE & STATUT --- *}
        <div class="col-md-8">
            <div class="card shadow-sm border-0 mb-4 h-100">
                <div class="card-header bg-white py-3">
                    <h6 class="m-0 fw-bold text-primary"><i class="bi bi-info-circle me-2"></i> Détails & Statut</h6>
                </div>
                <div class="card-body">
                    <div class="row mb-4">
                        <div class="col-sm-6">
                            <div class="text-muted small">Type de document</div>
                            <div class="fw-bold fs-6">
                                {if $order.type_doc == 'order'}
                                    <span class="badge bg-primary">Vente E-commerce</span>
                                {else}
                                    <span class="badge bg-secondary">Devis</span>
                                {/if}
                            </div>
                        </div>
                        <div class="col-sm-6">
                            <div class="text-muted small">Date de création</div>
                            <div class="fw-bold fs-6">{$order.date_add|date_format:"%d/%m/%Y à %H:%M"}</div>
                        </div>
                        <div class="col-sm-6 mt-4">
                            <div class="text-muted small">Moyen de paiement</div>
                            <div class="fw-bold fs-6">
                                {if $order.payment_method == 'bank_wire'}
                                    <i class="bi bi-bank text-success me-1"></i> Virement Bancaire
                                {else}
                                    <i class="bi bi-credit-card text-primary me-1"></i> {$order.payment_method|capitalize}
                                {/if}
                            </div>
                        </div>
                        <div class="col-sm-6 mt-4">
                            <div class="text-muted small">Statut actuel</div>
                            <div>
                                {if $order.status == 'pending'}<span class="badge bg-warning text-dark fs-6"><i class="bi bi-hourglass-split me-1"></i> En attente</span>{/if}
                                {if $order.status == 'paid'}<span class="badge bg-success fs-6"><i class="bi bi-check-circle me-1"></i> Payée</span>{/if}
                                {if $order.status == 'shipped'}<span class="badge bg-info text-dark fs-6"><i class="bi bi-truck me-1"></i> Expédiée</span>{/if}
                                {if $order.status == 'canceled'}<span class="badge bg-secondary fs-6"><i class="bi bi-x-circle me-1"></i> Annulée</span>{/if}
                                {if $order.status == 'failed'}<span class="badge bg-danger fs-6"><i class="bi bi-exclamation-triangle me-1"></i> Échouée</span>{/if}
                            </div>
                        </div>
                    </div>

                    <hr class="text-muted opacity-25">

                    {* Formulaire Ajax de changement de statut *}
                    <form action="index.php?controller=Magixcartpay&action=update_status" method="post" class="validate_form bg-light p-3 rounded border">
                        <input type="hidden" name="hashtoken" value="{$hashtoken}">
                        <input type="hidden" name="id_order" value="{$order.id_order}">

                        <label class="form-label fw-bold">Modifier le statut de la commande :</label>
                        <div class="input-group">
                            <span class="input-group-text bg-white"><i class="bi bi-activity text-muted"></i></span>
                            <select name="status" class="form-select">
                                <option value="pending" {if $order.status == 'pending'}selected{/if}>En attente de paiement</option>
                                <option value="paid" {if $order.status == 'paid'}selected{/if}>Paiement validé (Payée)</option>
                                <option value="shipped" {if $order.status == 'shipped'}selected{/if}>Commande Expédiée</option>
                                <option value="canceled" {if $order.status == 'canceled'}selected{/if}>Commande Annulée</option>
                            </select>
                            <button class="btn btn-primary fw-bold px-4" type="submit">Mettre à jour</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    {* --- ARTICLES DE LA COMMANDE --- *}
    <div class="card shadow-sm border-0 mb-4">
        <div class="card-header bg-white py-3">
            <h6 class="m-0 fw-bold text-primary"><i class="bi bi-box-seam me-2"></i> Contenu de la commande</h6>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                    <tr>
                        <th class="px-4 text-muted">Référence</th>
                        <th>Produit</th>
                        <th class="text-center">Quantité</th>
                        <th class="text-end">Prix unitaire HT</th>
                        <th class="text-center">TVA</th>
                        <th class="text-end px-4">Total TTC</th>
                    </tr>
                    </thead>
                    <tbody>
                    {foreach from=$order.items item=item}
                        <tr>
                            <td class="px-4 font-monospace text-muted small">{$item.product_reference|default:'---'}</td>
                            <td class="fw-bold">{$item.product_name}</td>
                            <td class="text-center">
                                <span class="badge bg-light text-dark border">{$item.quantity}</span>
                            </td>
                            <td class="text-end">{$item.unit_price_ht|number_format:2:',':' '} €</td>
                            <td class="text-center text-muted small">{$item.tax_rate|number_format:2:',':' '} %</td>
                            <td class="text-end px-4 fw-bold">{$item.total_ttc|number_format:2:',':' '} €</td>
                        </tr>
                    {/foreach}
                    </tbody>

                    {* --- NOUVEAU FOOTER AVEC LIVRAISON --- *}
                    <tfoot class="table-light">
                    <tr>
                        <td colspan="4" class="border-0"></td>
                        <td class="text-end fw-bold border-0 pt-4">Total articles HT :</td>
                        <td class="text-end fw-bold border-0 pt-4 px-4">{$order.total_products_ht|number_format:2:',':' '} €</td>
                    </tr>

                    {* On affiche la ligne de livraison uniquement si c'est une commande *}
                    {if $order.type_doc == 'order'}
                        <tr>
                            <td colspan="4" class="border-0"></td>
                            <td class="text-end fw-bold border-0 text-muted">Livraison HT :</td>
                            <td class="text-end fw-bold border-0 px-4 text-muted">{$order.total_shipping_ht|number_format:2:',':' '} €</td>
                        </tr>
                    {/if}

                    <tr>
                        <td colspan="4" class="border-0"></td>
                        <td class="text-end fw-bold border-0 text-muted">Total TVA :</td>
                        <td class="text-end fw-bold border-0 px-4 text-muted">{$order.total_tax|number_format:2:',':' '} €</td>
                    </tr>
                    <tr>
                        <td colspan="4" class="border-0 pb-4"></td>
                        <td class="text-end fw-bold text-primary fs-5 border-0 pb-4">TOTAL TTC :</td>
                        <td class="text-end fw-bold text-primary fs-5 border-0 pb-4 px-4">{$order.total_ttc|number_format:2:',':' '} €</td>
                    </tr>
                    </tfoot>
                </table>
            </div>
        </div>
    </div>
{/block}

{block name="javascripts" append}
    <script src="templates/js/MagixFormTools.min.js?v={$smarty.now}"></script>
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            new MagixFormTools();
        });
    </script>
{/block}