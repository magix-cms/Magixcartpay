{* Widget d'ajout au panier avec gestion de quantité *}
{* Widget d'ajout au panier avec gestion de quantité *}
<div class="magixcartpay-add-widget mb-4">

    <form action="{$cart_add_url}" method="post" class="validate_form">
        <input type="hidden" name="id_product" value="{$product_cart_id}">

        {*
           - flex-column : Empile verticalement sur mobile
           - align-items-stretch : Étire les enfants à 100% sur mobile (C'est ÇA qui rend le bouton full-width !)
           - flex-sm-row : Place côte à côte à partir de la tablette
           - align-items-sm-center : Annule l'étirement et centre verticalement sur desktop
        *}
        <div class="d-flex flex-column flex-sm-row align-items-stretch align-items-sm-center gap-3 mb-3">

            {* 1. Sélecteur de quantité *}
            <div class="input-group shadow-sm cartpay-qty-group">
                <button class="btn btn-light border border-secondary-subtle" type="button" onclick="this.nextElementSibling.stepDown()">
                    <i class="bi bi-dash fs-5"></i>
                </button>
                <input type="number" name="quantity" class="form-control form-control-lg text-center fw-bold border-secondary-subtle px-1" value="1" min="1" aria-label="Quantité">
                <button class="btn btn-light border border-secondary-subtle" type="button" onclick="this.previousElementSibling.stepUp()">
                    <i class="bi bi-plus fs-5"></i>
                </button>
            </div>

            {* 2. Bouton d'ajout : On a retiré w-100 et w-sm-auto *}
            <button type="submit" class="btn btn-primary btn-lg shadow-sm cartpay-submit-btn px-4">
                <span class="fw-bold fs-6"><i class="bi bi-cart-plus me-2"></i> Ajouter au panier</span>
            </button>

        </div>
    </form>
</div>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const form = document.querySelector('.magixcartpay-add-widget input[value="{$product_cart_id}"]').closest('form');

        if (form && !form.dataset.eventAttached) {
            form.dataset.eventAttached = "true";

            // Écoute de l'événement déclenché par MagixFrontForms.js
            form.addEventListener('magix:form:success', function(e) {
                const formData = new FormData(this);
                const addedQty = parseInt(formData.get('quantity')) || 1;
                updateHeaderCartBadge(addedQty);
            });
        }

        function updateHeaderCartBadge(addedQty) {
            const cartIcon = document.querySelector('a[href*="/magixcartpay/view"] .bi-cart3');
            if (!cartIcon) return;

            const linkParent = cartIcon.closest('a');
            let badge = linkParent.querySelector('.badge');

            if (badge) {
                let currentQty = parseInt(badge.innerText);
                badge.innerText = currentQty + addedQty;
                badge.style.transform = 'scale(1.4)';
                setTimeout(() => { badge.style.transform = 'translate(-50%, -50%) scale(1)'; }, 200);
            } else {
                badge = document.createElement('span');
                badge.className = 'position-absolute top-0 start-100 translate-middle badge rounded-pill bg-danger';
                badge.style.fontSize = '0.65rem';
                badge.style.transition = 'transform 0.2s';
                badge.innerText = addedQty;
                linkParent.appendChild(badge);
            }
        }
    });
</script>