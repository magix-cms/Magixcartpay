{extends file="layout.tpl"}

{block name='head:title'}MagixCartpay - Commandes{/block}

{block name='article'}
    <div class="d-flex justify-content-between align-items-center mb-4">
        <h1 class="h3 mb-0 text-gray-800">
            <i class="bi bi-cart4 me-2"></i> MagixCartpay : Achats & Devis
        </h1>
        <div>
            <form action="index.php?controller=Magixcartpay&action=clean_carts" method="post" class="validate_form d-inline me-2">
                <button type="submit" class="btn btn-warning text-dark" onclick="return confirm('Nettoyer les paniers abandonnés de plus de 7 jours ?');">
                    <i class="bi bi-trash me-1"></i> Nettoyer les paniers
                </button>
            </form>
            <a href="index.php?controller=Magixcartpay&action=config" class="btn btn-primary">
                <i class="bi bi-gear me-1"></i> Configuration du plugin
            </a>
        </div>
    </div>

    <div class="card shadow-sm border-0 mb-4">
        <div class="card-header bg-white py-3 border-bottom d-flex justify-content-between align-items-center">
            <h6 class="m-0 fw-bold text-primary">Liste des commandes et devis</h6>
        </div>

        <div class="card-body p-0">
            {* INJECTION DU COMPOSANT NATIF MAGIX POUR LA GESTION DE TABLEAU *}
            {include file="components/table-forms.tpl"
            data=$ordersList
            idcolumn='id_order'
            activation=false
            sortable=false
            controller="Magixcartpay"
            }
        </div>
    </div>
{/block}