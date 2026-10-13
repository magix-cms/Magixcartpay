{extends file="layout.tpl"}

{block name='head:title'}Mes commandes{/block}

{block name='article'}
    <div class="container py-5">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <h1 class="h2 fw-bold mb-0"><i class="bi bi-clock-history text-primary me-2"></i> Mes commandes</h1>
            <a href="{$site_url|trim:'/'}/{$current_lang.iso_lang|lower}/magixaccount" class="btn btn-outline-secondary">
                <i class="bi bi-person me-1"></i> Mon compte
            </a>
        </div>

        {if empty($orders)}
            <div class="alert alert-light text-center p-5 shadow-sm border">
                <i class="bi bi-receipt fs-1 text-muted d-block mb-3"></i>
                <h5 class="fw-bold">Vous n'avez passé aucune commande.</h5>
                <a href="{$site_url|trim:'/'}/{$current_lang.iso_lang|lower}/catalog/" class="btn btn-primary mt-3">Aller à la boutique</a>
            </div>
        {else}
            <div class="card shadow-sm border-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                        <tr>
                            <th class="px-4 py-3">Date</th>
                            <th>Référence</th>
                            <th>Type</th>
                            <th>Total TTC</th>
                            <th>Statut</th>
                            <th class="text-end px-4">Action</th>
                        </tr>
                        </thead>
                        <tbody>
                        {foreach from=$orders item=order}
                            <tr>
                                <td class="px-4 text-muted">{$order.date_add|date_format:"%d/%m/%Y"}</td>
                                <td class="fw-bold text-dark">{$order.reference}</td>
                                <td>
                                    {if $order.type_doc == 'order'}Commande{else}Devis{/if}
                                </td>
                                <td class="fw-bold">{$order.total_ttc|number_format:2:',':' '} €</td>
                                <td>
                                    {if $order.status == 'pending'}<span class="badge bg-warning text-dark">En attente</span>{/if}
                                    {if $order.status == 'paid'}<span class="badge bg-success">Payée</span>{/if}
                                    {if $order.status == 'shipped'}<span class="badge bg-info text-dark">Expédiée</span>{/if}
                                    {if $order.status == 'canceled'}<span class="badge bg-secondary">Annulée</span>{/if}
                                </td>
                                <td class="text-end px-4">
                                    <a href="{$site_url|trim:'/'}/{$current_lang.iso_lang|lower}/?controller=Magixcartpay&action=order_detail&id_order={$order.id_order}" class="btn btn-sm btn-outline-primary">
                                        Détails <i class="bi bi-chevron-right ms-1"></i>
                                    </a>
                                </td>
                            </tr>
                        {/foreach}
                        </tbody>
                    </table>
                </div>
            </div>
        {/if}
    </div>
{/block}