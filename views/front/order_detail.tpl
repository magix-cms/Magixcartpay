{extends file="layout.tpl"}

{block name='head:title'}Détail de la commande {$order.reference}{/block}

{block name='article'}
    <div class="container py-5">

        {* --- EN-TÊTE --- *}
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h1 class="h2 fw-bold mb-0">
                <i class="bi bi-receipt text-primary me-2"></i>
                {if $order.type_doc == 'order'}Commande{else}Devis{/if} {$order.reference}
            </h1>
            <a href="{$base_url}{$current_lang.iso_lang|lower}/?controller=Magixcartpay&action=history" class="btn btn-outline-secondary">
                <i class="bi bi-arrow-left me-1"></i> Retour aux commandes
            </a>
        </div>

        <div class="row g-4">
            {* --- COLONNE GAUCHE : STATUT ET ARTICLES --- *}
            <div class="col-lg-8">

                <div class="card shadow-sm border-0 mb-4">
                    <div class="card-header bg-white py-3">
                        <h5 class="mb-0 fw-bold">Statut de la demande</h5>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            <div class="col-sm-6 mb-3">
                                <div class="text-muted small">Date</div>
                                <div class="fw-bold">{$order.date_add|date_format:"%d/%m/%Y à %H:%M"}</div>
                            </div>
                            <div class="col-sm-6 mb-3">
                                <div class="text-muted small">Statut actuel</div>
                                <div>
                                    {if $order.status == 'pending'}<span class="badge bg-warning text-dark">En attente de paiement</span>{/if}
                                    {if $order.status == 'paid'}<span class="badge bg-success">Payée</span>{/if}
                                    {if $order.status == 'shipped'}<span class="badge bg-info text-dark">Expédiée</span>{/if}
                                    {if $order.status == 'canceled'}<span class="badge bg-secondary">Annulée</span>{/if}
                                </div>
                            </div>
                            <div class="col-sm-6">
                                <div class="text-muted small">Moyen de paiement choisi</div>
                                <div class="fw-bold">
                                    {if $order.payment_method == 'bank_wire'}
                                        <i class="bi bi-bank text-success me-1"></i> Virement bancaire
                                    {else}
                                        {$order.payment_method|capitalize}
                                    {/if}
                                </div>
                            </div>

                            {* Affichage du transporteur dans le FrontEnd client *}
                            {if $order.type_doc == 'order'}
                                <div class="col-sm-6">
                                    <div class="text-muted small">Transporteur</div>
                                    <div class="fw-bold">
                                        {if $order.shipping_method == 'pickup'}
                                            <i class="bi bi-shop text-primary me-1"></i> Retrait en magasin
                                        {elseif $order.shipping_method == 'none'}
                                            <span class="text-muted">---</span>
                                        {else}
                                            <i class="bi bi-box-seam text-info me-1"></i> {$order.shipping_method|capitalize}
                                        {/if}
                                    </div>
                                </div>
                            {/if}
                        </div>
                    </div>
                </div>

                <div class="card shadow-sm border-0">
                    <div class="card-header bg-white py-3">
                        <h5 class="mb-0 fw-bold">Articles commandés</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle mb-0">
                                <thead class="table-light">
                                <tr>
                                    <th class="px-4">Produit</th>
                                    <th class="text-center">Qté</th>
                                    <th class="text-end">Prix U. HT</th>
                                    <th class="text-end px-4">Total HT</th>
                                </tr>
                                </thead>
                                <tbody>
                                {foreach from=$order.items item=item}
                                    <tr>
                                        <td class="px-4">
                                            <div class="fw-bold">{$item.product_name}</div>
                                            <div class="text-muted small">Réf: {$item.product_reference|default:'-'}</div>
                                        </td>
                                        <td class="text-center"><span class="badge bg-light text-dark border">{$item.quantity}</span></td>
                                        <td class="text-end">{$item.unit_price_ht|number_format:2:',':' '} €</td>
                                        <td class="text-end px-4 fw-bold">
                                            {($item.unit_price_ht * $item.quantity)|number_format:2:',':' '} €
                                        </td>
                                    </tr>
                                {/foreach}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>

            {* --- COLONNE DROITE : TOTAUX ET ADRESSES --- *}
            <div class="col-lg-4">

                <div class="card shadow-sm border-0 mb-4">
                    <div class="card-header bg-white py-3">
                        <h5 class="mb-0 fw-bold">Totaux</h5>
                    </div>
                    <div class="card-body bg-light">
                        <div class="d-flex justify-content-between mb-2 text-muted">
                            <span>Total HT</span>
                            <span>{$order.total_products_ht|number_format:2:',':' '} €</span>
                        </div>

                        {* --- Ligne de Livraison Ajoutée dans les totaux --- *}
                        {if $order.type_doc == 'order'}
                            <div class="d-flex justify-content-between mb-2 text-muted">
                                <span>Livraison HT</span>
                                <span>{$order.total_shipping_ht|number_format:2:',':' '} €</span>
                            </div>
                        {/if}

                        <div class="d-flex justify-content-between mb-3 text-muted border-bottom border-secondary pb-3">
                            <span>TVA globale</span>
                            <span>{$order.total_tax|number_format:2:',':' '} €</span>
                        </div>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="fw-bold fs-5">TOTAL TTC</span>
                            <span class="fw-bold fs-4 text-primary">{$order.total_ttc|number_format:2:',':' '} €</span>
                        </div>
                    </div>
                </div>

                {* Affichage Facturation / Livraison empilés, exactement comme dans l'admin *}
                <div class="row g-4">
                    <div class="{if !empty($order.shipping_address)}col-12{else}col-12{/if}">
                        <div class="card shadow-sm border-0 h-100">
                            <div class="card-header bg-white py-3">
                                <h5 class="mb-0 fw-bold">Facturation</h5>
                            </div>
                            <div class="card-body">
                                {if !empty($order.billing_address.company)}
                                    <div class="fw-bold">{$order.billing_address.company}</div>
                                    {if !empty($order.billing_address.vat_number)}
                                        <div class="text-muted small mb-3">TVA : {$order.billing_address.vat_number}</div>
                                    {/if}
                                {/if}
                                <div class="fw-bold">{$order.billing_address.firstname} {$order.billing_address.lastname}</div>
                                <div class="text-dark">{$order.billing_address.street}</div>
                                <div class="text-dark">{$order.billing_address.postcode} {$order.billing_address.city}</div>
                                <div class="text-dark">{$order.billing_address.country}</div>

                                <hr class="text-muted opacity-25 my-3">

                                <div class="small"><i class="bi bi-envelope text-muted me-2"></i> <a href="mailto:{$order.billing_address.email}" class="text-decoration-none">{$order.billing_address.email}</a></div>
                                {if !empty($order.billing_address.phone)}
                                    <div class="small mt-2"><i class="bi bi-telephone text-muted me-2"></i> {$order.billing_address.phone}</div>
                                {/if}
                            </div>
                        </div>
                    </div>

                    {* Bloc Adresse de Livraison Conditionnelle *}
                    {if !empty($order.shipping_address)}
                        <div class="col-12">
                            <div class="card shadow-sm border-0 h-100 border-start border-4 border-success">
                                <div class="card-header bg-white py-3">
                                    <h5 class="mb-0 fw-bold text-success">Livraison</h5>
                                </div>
                                <div class="card-body">
                                    {if !empty($order.shipping_address.company)}
                                        <div class="fw-bold">{$order.shipping_address.company}</div>
                                    {/if}
                                    <div class="fw-bold">{$order.shipping_address.firstname} {$order.shipping_address.lastname}</div>
                                    <div class="text-dark">{$order.shipping_address.street}</div>
                                    <div class="text-dark">{$order.shipping_address.postcode} {$order.shipping_address.city}</div>
                                    <div class="text-dark">{$order.shipping_address.country}</div>

                                    {if !empty($order.shipping_address.phone)}
                                        <hr class="text-muted opacity-25 my-3">
                                        <div class="small mt-2"><i class="bi bi-telephone text-muted me-2"></i> {$order.shipping_address.phone}</div>
                                    {/if}
                                </div>
                            </div>
                        </div>
                    {/if}
                </div>

            </div>
        </div>
    </div>
{/block}