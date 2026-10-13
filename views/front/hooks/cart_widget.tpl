{* Widget Panier pour l'en-tête du site *}
<a href="{$base_url}{$current_lang.iso_lang}/magixcartpay/view" class="btn btn-link text-dark text-decoration-none position-relative p-2" aria-label="Mon Panier">
    <i class="bi bi-cart3 fs-5"></i>

    {* Bulle rouge affichant le nombre d'articles (cachée si 0) *}
    {if isset($cart_summary.items_count) && $cart_summary.items_count > 0}
        <span class="position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger" style="font-size: 0.65rem;">
            {$cart_summary.items_count}
            <span class="visually-hidden">articles dans le panier</span>
        </span>
    {/if}
</a>