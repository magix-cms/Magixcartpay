<div class="bg-body p-4 p-md-5 rounded shadow-sm border mt-4">
    <div class="d-flex justify-content-between align-items-center mb-4 border-bottom pb-2">
        <h2 class="h4 mb-0 fw-bold">Mes commandes récentes</h2>
        {if !empty($recent_orders)}
            <a href="{$history_url}" class="btn btn-sm btn-outline-primary">Voir tout</a>
        {/if}
    </div>

    {if empty($recent_orders)}
        <div class="text-center p-4">
            <i class="bi bi-receipt fs-2 text-muted mb-2 d-block"></i>
            <p class="text-muted mb-0">Vous n'avez pas encore passé de commande.</p>
        </div>
    {else}
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0 text-nowrap">
                <thead class="table-light">
                <tr>
                    <th>Date</th>
                    <th>Référence</th>
                    <th>Statut</th>
                    <th class="text-end">Total TTC</th>
                    <th class="text-end"></th>
                </tr>
                </thead>
                <tbody>
                {foreach from=$recent_orders item=order}
                    <tr>
                        <td class="text-muted small">{$order.date_add|date_format:"%d/%m/%Y"}</td>
                        <td class="fw-bold">{$order.reference}</td>
                        <td>
                            {if $order.status == 'pending'}<span class="badge bg-warning text-dark">En attente</span>{/if}
                            {if $order.status == 'paid'}<span class="badge bg-success">Payée</span>{/if}
                            {if $order.status == 'shipped'}<span class="badge bg-info text-dark">Expédiée</span>{/if}
                            {if $order.status == 'canceled'}<span class="badge bg-secondary">Annulée</span>{/if}
                        </td>
                        <td class="text-end fw-bold">{$order.total_ttc|number_format:2:',':' '} €</td>
                        <td class="text-end">
                            <a href="{$detail_url}&id_order={$order.id_order}" class="btn btn-sm btn-light border" title="Détails de la commande">
                                <i class="bi bi-eye"></i>
                            </a>
                        </td>
                    </tr>
                {/foreach}
                </tbody>
            </table>
        </div>
    {/if}
</div>