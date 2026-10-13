{extends file="layout.tpl"}

{block name='head:title'}{if $cart_type_doc == 'quotation'}Demande de devis{else}Mon Panier{/if}{/block}

{block name='article'}
    {$action_base_url = "`$base_url``$current_lang.iso_lang|lower`/magixcartpay"}

    <div class="container py-5">
        <h1 class="mb-4 fw-bold">
            {if $cart_type_doc == 'quotation'}Demande de devis{else}Mon Panier{/if}
        </h1>

        {if empty($cart.items)}
            <div class="alert alert-info text-center p-5 shadow-sm border-0">
                <i class="bi bi-cart-x fs-1 text-muted mb-3 d-block"></i>
                <h4 class="alert-heading fw-bold">Votre panier est actuellement vide.</h4>
                <a href="{$base_url}{$current_lang.iso_lang}/catalog/" class="btn btn-primary mt-3 px-4 fw-bold">
                    Retour à la boutique
                </a>
            </div>
        {else}
            <div class="row g-5">

                <div class="col-lg-8">
                    {* 1. Liste des articles *}
                    <div class="card shadow-sm border-0 mb-5">
                        <div class="card-header bg-white py-3">
                            <h5 class="mb-0 fw-bold">
                                <i class="bi bi-box-seam me-2 text-primary"></i> Articles ({$cart.summary.items_count})
                            </h5>
                        </div>
                        <div class="card-body p-0">
                            <ul class="list-group list-group-flush">
                                {foreach from=$cart.items item=item}
                                    <li class="list-group-item py-4 px-4">
                                        <div class="row align-items-center">
                                            <div class="col-3 col-md-2">
                                                {if $item.image_url}
                                                    <img src="{$item.image_url}" alt="{$item.name|escape}" class="img-fluid rounded border">
                                                {else}
                                                    <div class="bg-light text-center text-muted rounded p-3 border"><i class="bi bi-image fs-4"></i></div>
                                                {/if}
                                            </div>
                                            <div class="col-9 col-md-4">
                                                <h6 class="fw-bold mb-1">
                                                    <a href="{$base_url}{$current_lang.iso_lang}/{$item.url}" class="text-dark text-decoration-none">{$item.name}</a>
                                                </h6>
                                                <div class="text-muted small mb-2">Réf: {$item.reference|default:'N/A'}</div>
                                                <div class="text-muted small">Prix unitaire : {$item.unit_price|number_format:2:',':' '} € HT</div>
                                            </div>
                                            <div class="col-6 col-md-3 mt-3 mt-md-0">
                                                <form action="{$action_base_url}/update" method="post" class="validate_form d-flex align-items-center m-0">
                                                    <input type="hidden" name="id_item" value="{$item.id_item}">
                                                    <div class="input-group input-group-sm" style="max-width: 110px;">
                                                        <input type="number" name="quantity" class="form-control text-center fw-bold" value="{$item.quantity}" min="1">
                                                        <button type="submit" class="btn btn-outline-secondary"><i class="bi bi-arrow-clockwise"></i></button>
                                                    </div>
                                                </form>
                                            </div>
                                            <div class="col-6 col-md-3 mt-3 mt-md-0 d-flex justify-content-end align-items-center">
                                                <span class="fw-bold fs-5 me-3">{$item.total_price|number_format:2:',':' '} €</span>
                                                <form action="{$action_base_url}/remove" method="post" class="validate_form m-0">
                                                    <input type="hidden" name="id_item" value="{$item.id_item}">
                                                    <button type="submit" class="btn btn-sm btn-outline-danger border-0"><i class="bi bi-trash fs-5"></i></button>
                                                </form>
                                            </div>
                                        </div>
                                    </li>
                                {/foreach}
                            </ul>
                        </div>
                    </div>

                    {* 2. Formulaire *}
                    <div class="card shadow-sm border-0">
                        <div class="card-header bg-white py-3">
                            <h5 class="mb-0 fw-bold">
                                <i class="bi bi-person-lines-fill me-2 text-primary"></i>
                                {if $cart_type_doc == 'quotation'}Vos coordonnées{else}Détails de facturation{/if}
                            </h5>
                        </div>
                        <div class="card-body p-4">
                            <form action="{$action_base_url}/checkout" method="post" class="validate_form" id="checkoutForm">

                                <h6 class="fw-bold mb-3">Informations personnelles</h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-md-6">
                                        <label class="form-label text-muted small mb-1">Prénom <span class="text-danger">*</span></label>
                                        <input type="text" name="firstname" class="form-control" value="{$accountProfile.firstname|default:''}" required>
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label text-muted small mb-1">Nom <span class="text-danger">*</span></label>
                                        <input type="text" name="lastname" class="form-control" value="{$accountProfile.lastname|default:''}" required>
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label text-muted small mb-1">Email <span class="text-danger">*</span></label>
                                        <input type="email" name="email" class="form-control" value="{$accountProfile.email|default:''}" required>
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label text-muted small mb-1">Téléphone</label>
                                        <input type="text" name="phone" class="form-control" value="{$accountProfile.phone|default:''}">
                                    </div>
                                </div>

                                <hr class="text-muted opacity-25">

                                <h6 class="fw-bold mb-3 mt-4">Coordonnées de l'entreprise (Optionnel)</h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-md-6">
                                        <label class="form-label text-muted small mb-1">Nom de l'entreprise</label>
                                        <input type="text" name="company" class="form-control" value="{$accountProfile.company|default:''}">
                                    </div>
                                    <div class="col-md-6">
                                        <label class="form-label text-muted small mb-1">N° de TVA</label>
                                        <input type="text" name="vat_number" class="form-control">
                                    </div>
                                </div>

                                <h6 class="fw-bold mb-3 mt-4">Adresse de facturation {if $cart_type_doc == 'quotation'}(Requise pour le devis){/if}</h6>
                                <div class="row g-3 mb-4">
                                    <div class="col-12">
                                        <label class="form-label text-muted small mb-1">Rue et numéro <span class="text-danger">*</span></label>
                                        <input type="text" name="street" class="form-control" required>
                                    </div>
                                    <div class="col-md-4">
                                        <label class="form-label text-muted small mb-1">Code postal <span class="text-danger">*</span></label>
                                        <input type="text" name="postcode" class="form-control" required>
                                    </div>
                                    <div class="col-md-8">
                                        <label class="form-label text-muted small mb-1">Ville <span class="text-danger">*</span></label>
                                        <input type="text" name="city" class="form-control" required>
                                    </div>
                                    <div class="col-12">
                                        <label class="form-label text-muted small mb-1">Pays <span class="text-danger">*</span></label>
                                        <input type="text" name="country" class="form-control" value="Belgique" required>
                                    </div>
                                </div>

                                {* SI MODE COMMANDE => AFFICHE LA LIVRAISON ET LE PAIEMENT *}
                                {if $cart_type_doc == 'order'}

                                    {* --- NOUVEAU : FORMULAIRE ADRESSE DE LIVRAISON ENVELOPPÉ --- *}
                                    <div id="shipping-address-container" style="display: none;">
                                        <div class="form-check form-switch mb-4 mt-3">
                                            <input class="form-check-input" type="checkbox" id="different_shipping" name="different_shipping" value="1" onchange="document.getElementById('shipping_address_block').style.display = this.checked ? 'block' : 'none';">
                                            <label class="form-check-label fw-bold" for="different_shipping">Livrer à une adresse différente</label>
                                        </div>

                                        <div id="shipping_address_block" style="display: none;" class="bg-light p-4 rounded border mb-4">
                                            <h6 class="fw-bold mb-3"><i class="bi bi-truck me-2"></i> Adresse de livraison</h6>
                                            <div class="row g-3">
                                                <div class="col-md-6">
                                                    <label class="form-label text-muted small mb-1">Prénom <span class="text-danger">*</span></label>
                                                    <input type="text" name="shipping_firstname" class="form-control">
                                                </div>
                                                <div class="col-md-6">
                                                    <label class="form-label text-muted small mb-1">Nom <span class="text-danger">*</span></label>
                                                    <input type="text" name="shipping_lastname" class="form-control">
                                                </div>
                                                <div class="col-12">
                                                    <label class="form-label text-muted small mb-1">Nom de l'entreprise (Optionnel)</label>
                                                    <input type="text" name="shipping_company" class="form-control">
                                                </div>
                                                <div class="col-12">
                                                    <label class="form-label text-muted small mb-1">Rue et numéro <span class="text-danger">*</span></label>
                                                    <input type="text" name="shipping_street" class="form-control">
                                                </div>
                                                <div class="col-md-4">
                                                    <label class="form-label text-muted small mb-1">Code postal <span class="text-danger">*</span></label>
                                                    <input type="text" name="shipping_postcode" class="form-control">
                                                </div>
                                                <div class="col-md-8">
                                                    <label class="form-label text-muted small mb-1">Ville <span class="text-danger">*</span></label>
                                                    <input type="text" name="shipping_city" class="form-control">
                                                </div>
                                                <div class="col-12">
                                                    <label class="form-label text-muted small mb-1">Pays <span class="text-danger">*</span></label>
                                                    <input type="text" name="shipping_country" class="form-control" value="Belgique">
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    {* --- FIN FORMULAIRE ADRESSE LIVRAISON --- *}

                                    <h5 class="fw-bold mb-3 mt-5 border-top pt-4">Mode de livraison / retrait</h5>
                                    <div class="mb-4" id="shipping-methods-container">

                                        {* OPTION 1 : Retrait en magasin (Native et toujours gratuite) *}
                                        <div class="border rounded p-3 mb-2 bg-light">
                                            <div class="form-check mb-0">
                                                <input class="form-check-input mt-1 shipping-method-radio" type="radio" name="shipping_method" id="shipping_pickup" value="pickup" data-price="0.00" checked required style="cursor:pointer;">
                                                <label class="form-check-label w-100 ps-1" for="shipping_pickup" style="cursor:pointer;">
                                                    <div class="d-flex justify-content-between align-items-center">
                                                        <span class="fw-bold"><i class="bi bi-shop text-primary me-2 fs-5 align-middle"></i> Retrait en magasin</span>
                                                        <span class="fw-bold text-success">Gratuit</span>
                                                    </div>
                                                    <div class="text-muted small mt-1">Venez retirer votre commande directement dans notre établissement.</div>
                                                </label>
                                            </div>
                                        </div>

                                        {* OPTION 2 : Les transporteurs (Injectés par les futurs addons) *}
                                        {hook name="displayCartShipping" cart=$cart}

                                        {* Ce champ caché enverra le prix calculé au Backend *}
                                        <input type="hidden" name="shipping_price" id="shipping_price_input" value="0.00">
                                    </div>

                                    <h5 class="fw-bold mb-3 mt-4 border-top pt-4">Moyen de paiement</h5>
                                    <div class="mb-4">
                                        <div class="border rounded p-3 mb-2 bg-light">
                                            <div class="form-check mb-0">
                                                <input class="form-check-input mt-1" type="radio" name="payment_method" id="bank_wire" value="bank_wire" checked required style="cursor:pointer;">
                                                <label class="form-check-label fw-bold w-100 ps-1" for="bank_wire" style="cursor:pointer;">
                                                    <i class="bi bi-bank text-success me-2 fs-5 align-middle"></i> Virement bancaire
                                                    <div class="text-muted small fw-normal mt-1">Vous recevrez nos coordonnées bancaires par e-mail après validation de votre commande.</div>
                                                </label>
                                            </div>
                                        </div>
                                    </div>

                                {else}
                                    {* SI MODE DEVIS => CACHE LE PAIEMENT ET LA LIVRAISON *}
                                    <input type="hidden" name="shipping_method" value="none">
                                    <input type="hidden" name="shipping_price" value="0.00">
                                    <input type="hidden" name="payment_method" value="quotation">
                                {/if}

                                <div style="display:none;" aria-hidden="true">
                                    <label>Leave this empty: <input type="text" name="website_url" autocomplete="off" tabindex="-1"></label>
                                </div>
                                <div class="d-grid gap-2 mt-5">
                                    <button type="submit" class="btn btn-primary btn-lg fw-bold py-3 shadow-sm">
                                        {if $cart_type_doc == 'order'}
                                            <i class="bi bi-shield-lock me-2"></i> Valider ma commande et payer
                                        {else}
                                            <i class="bi bi-file-earmark-text me-2"></i> Valider ma demande de devis
                                        {/if}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>

                {* COLONNE DROITE : RÉSUMÉ *}
                <div class="col-lg-4">
                    <div class="card shadow-sm border-0 position-sticky" style="top: 2rem;">
                        <div class="card-header bg-white py-3">
                            <h5 class="mb-0 fw-bold">Résumé</h5>
                        </div>
                        <div class="card-body p-4 bg-light">
                            <div class="d-flex justify-content-between mb-2">
                                <span class="text-muted">Total des articles HT</span>
                                <span class="fw-medium">{$cart.summary.total_ht|number_format:2:',':' '} €</span>
                            </div>

                            {* Ligne dynamique pour la livraison *}
                            {if $cart_type_doc == 'order'}
                                <div class="d-flex justify-content-between mb-2" id="cart-summary-shipping">
                                    <span class="text-muted">Livraison HT</span>
                                    <span class="fw-medium shipping-amount-display">0,00 €</span>
                                </div>
                            {/if}

                            <div class="d-flex justify-content-between mb-3 border-bottom border-secondary pb-3">
                                <span class="text-muted">TVA estimée ({$cart.summary.tax_rate|number_format:2:',':' '}%)</span>
                                <span class="fw-medium tax-amount-display">{$cart.summary.total_tax|number_format:2:',':' '} €</span>
                            </div>
                            <div class="d-flex justify-content-between align-items-center mb-4 pt-2">
                                <span class="fw-bold fs-5 text-dark">TOTAL TTC</span>
                                <span class="fw-bold fs-3 text-primary total-ttc-display">{$cart.summary.total_ttc|number_format:2:',':' '} €</span>
                            </div>

                            {if $cart_type_doc == 'quotation'}
                                <div class="alert alert-warning small text-center mt-3 mb-0">
                                    <i class="bi bi-info-circle me-1"></i> Ceci est une demande de devis, aucun paiement ne vous sera demandé à cette étape.
                                </div>
                            {/if}
                        </div>
                    </div>
                </div>

            </div>
        {/if}
    </div>

    {* --- SCRIPT JS : CALCULATEUR DYNAMIQUE DES FRAIS DE PORT ET ADRESSE --- *}
    {if $cart_type_doc == 'order' && !empty($cart.items)}
        <script>
            document.addEventListener('DOMContentLoaded', function() {
                const shippingRadios = document.querySelectorAll('.shipping-method-radio');
                const shippingPriceInput = document.getElementById('shipping_price_input');

                const displayShipping = document.querySelector('.shipping-amount-display');
                const displayTax = document.querySelector('.tax-amount-display');
                const displayTotalTtc = document.querySelector('.total-ttc-display');

                // Le bloc complet contenant le switch et le formulaire de livraison
                const shippingAddressContainer = document.getElementById('shipping-address-container');

                const baseTotalHt = parseFloat("{$cart.summary.total_ht|string_format:'%.2f'}");
                const baseTotalTax = parseFloat("{$cart.summary.total_tax|string_format:'%.2f'}");
                const taxRate = parseFloat("{$cart.summary.tax_rate|string_format:'%.2f'}") / 100;

                function updateCartTotals() {
                    let selectedRadio = document.querySelector('.shipping-method-radio:checked');
                    if (!selectedRadio) return;

                    // 1. Gestion de l'affichage du formulaire de livraison
                    if (selectedRadio.value === 'pickup') {
                        // Retrait en magasin : on cache tout le bloc adresse
                        if (shippingAddressContainer) shippingAddressContainer.style.display = 'none';
                        // Et on décoche le switch pour être sûr qu'il ne s'envoie pas
                        const diffCheckbox = document.getElementById('different_shipping');
                        if (diffCheckbox) {
                            diffCheckbox.checked = false;
                            document.getElementById('shipping_address_block').style.display = 'none';
                        }
                    } else {
                        // Transporteur classique : on affiche le bloc adresse
                        if (shippingAddressContainer) shippingAddressContainer.style.display = 'block';
                    }

                    // 2. Calcul des totaux
                    let shippingPriceHt = parseFloat(selectedRadio.getAttribute('data-price')) || 0;
                    shippingPriceInput.value = shippingPriceHt.toFixed(2);

                    let shippingTax = shippingPriceHt * taxRate;
                    let newTotalTax = baseTotalTax + shippingTax;
                    let newTotalTtc = baseTotalHt + shippingPriceHt + newTotalTax;

                    if (displayShipping) displayShipping.innerText = shippingPriceHt.toFixed(2).replace('.', ',') + ' €';
                    if (displayTax) displayTax.innerText = newTotalTax.toFixed(2).replace('.', ',') + ' €';
                    if (displayTotalTtc) displayTotalTtc.innerText = newTotalTtc.toFixed(2).replace('.', ',') + ' €';
                }

                shippingRadios.forEach(radio => {
                    radio.addEventListener('change', updateCartTotals);
                });

                updateCartTotals();
            });
        </script>
    {/if}
{/block}

{block name="javascript_data"}
    {$page_js = [
    'defer' => ['MagixToast','MagixFrontForms']
    ] scope="parent"}
{/block}