{* Widget d'ajout au panier avec gestion de quantité *}
<div class="magixcartpay-add-widget mt-4">

    <form action="{$cart_add_url}" method="post" class="validate_form">
        <input type="hidden" name="id_product" value="{$product_cart_id}">

        <div class="d-flex align-items-center mb-3">

            {* 1. Sélecteur de quantité avec une largeur fixe raisonnable *}
            <div class="input-group shadow-sm me-3" style="width: 140px; height: 48px;">
                <button class="btn btn-light border border-secondary-subtle" type="button" onclick="this.nextElementSibling.stepDown()">
                    <i class="bi bi-dash fs-5"></i>
                </button>
                <input type="number" name="quantity" class="form-control form-control-lg text-center fw-bold border-secondary-subtle" value="1" min="1" aria-label="Quantité" style="padding:0;">
                <button class="btn btn-light border border-secondary-subtle" type="button" onclick="this.previousElementSibling.stepUp()">
                    <i class="bi bi-plus fs-5"></i>
                </button>
            </div>

            {* 2. Bouton d'ajout (ne prend que la place nécessaire) *}
            <button type="submit" class="btn btn-primary shadow-sm cartpay-submit-btn" style="height: 48px; padding-left: 1.5rem; padding-right: 1.5rem;">
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