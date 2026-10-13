{extends file="emails/layout.tpl"}

{block name="email_content"}
    <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
            <td style="padding: 20px; font-family: sans-serif; font-size: 16px; line-height: 24px; color: #333333;">
                <h2 style="margin-top: 0; color: {$main_color|default:'#0d6efd'};">
                    Bonjour {$address.firstname|escape} {$address.lastname|escape},
                </h2>

                <p>
                    {if $type_doc == 'order'}
                        Nous vous remercions pour votre commande sur notre boutique.
                    {else}
                        Nous avons bien reçu votre demande de devis.
                    {/if}
                    Voici le récapitulatif de votre demande portant la référence <strong>{$reference}</strong> :
                </p>

                <hr style="border:none; border-top: 1px solid #EEEEEE; margin: 20px 0;">

                <!-- DÉTAIL DES ARTICLES -->
                <h3 style="color: #444444; font-size: 18px;">Détail de votre panier</h3>
                <table width="100%" cellpadding="10" cellspacing="0" style="border: 1px solid #dddddd; border-collapse: collapse; margin-bottom: 20px; font-size: 14px;">
                    <thead>
                    <tr style="background-color: #f8f9fa;">
                        <th style="border: 1px solid #dddddd; text-align: left;">Article</th>
                        <th style="border: 1px solid #dddddd; text-align: center;">Qté</th>
                        <th style="border: 1px solid #dddddd; text-align: right;">Prix U. HT</th>
                        <th style="border: 1px solid #dddddd; text-align: right;">Total HT</th>
                    </tr>
                    </thead>
                    <tbody>
                    {foreach from=$cart.items item=item}
                        <tr>
                            <td style="border: 1px solid #dddddd;">
                                <strong>{$item.name}</strong><br>
                                <span style="color: #777777; font-size: 12px;">Réf: {$item.reference|default:'N/A'}</span>
                            </td>
                            <td style="border: 1px solid #dddddd; text-align: center;">{$item.quantity}</td>
                            <td style="border: 1px solid #dddddd; text-align: right;">{$item.unit_price|number_format:2:',':' '} €</td>
                            <td style="border: 1px solid #dddddd; text-align: right;">{$item.total_price|number_format:2:',':' '} €</td>
                        </tr>
                    {/foreach}
                    </tbody>
                    <tfoot>
                    <tr>
                        <td colspan="3" style="border: 1px solid #dddddd; text-align: right; padding-top: 15px;"><strong>Total HT :</strong></td>
                        <td style="border: 1px solid #dddddd; text-align: right; padding-top: 15px;">{$cart.summary.total_ht|number_format:2:',':' '} €</td>
                    </tr>
                    {* --- AJOUT DE LA LIVRAISON DANS L'EMAIL (Seulement si c'est une commande) --- *}
                    {if $type_doc == 'order'}
                        <tr>
                            <td colspan="3" style="border: 1px solid #dddddd; text-align: right;"><strong>Livraison HT :</strong></td>
                            <td style="border: 1px solid #dddddd; text-align: right;">{$cart.summary.total_shipping_ht|default:'0.00'|number_format:2:',':' '} €</td>
                        </tr>
                    {/if}
                    <tr>
                        <td colspan="3" style="border: 1px solid #dddddd; text-align: right;"><strong>TVA ({$cart.summary.tax_rate|number_format:2:',':' '}%) :</strong></td>
                        <td style="border: 1px solid #dddddd; text-align: right;">{$cart.summary.total_tax|number_format:2:',':' '} €</td>
                    </tr>
                    <tr style="background-color: #f8f9fa;">
                        <td colspan="3" style="border: 1px solid #dddddd; text-align: right; font-size: 16px;"><strong>TOTAL TTC :</strong></td>
                        <td style="border: 1px solid #dddddd; text-align: right; color: {$main_color|default:'#0d6efd'}; font-weight: bold; font-size: 16px;">{$cart.summary.total_ttc|number_format:2:',':' '} €</td>
                    </tr>
                    </tfoot>
                </table>

                <!-- ADRESSES -->
                <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 25px;">
                    <tr>
                        <td width="48%" valign="top">
                            <!-- ADRESSE DE FACTURATION -->
                            <h3 style="color: #444444; font-size: 18px;">Adresse de facturation</h3>
                            <div style="background: #f8f9fa; border-left: 4px solid {$main_color|default:'#0d6efd'}; padding: 15px; font-size: 15px; line-height: 22px;">
                                {if !empty($address.company)}<strong>{$address.company}</strong><br>{/if}
                                {if !empty($address.vat_number)}TVA : {$address.vat_number}<br><br>{/if}
                                {$address.firstname} {$address.lastname}<br>
                                {$address.street}<br>
                                {$address.postcode} {$address.city}<br>
                                {$address.country}<br><br>
                                <span style="color: #666;">Tél :</span> {$address.phone|default:'Non renseigné'}<br>
                                <span style="color: #666;">Email :</span> <a href="mailto:{$address.email}" style="color: {$main_color|default:'#0d6efd'}; text-decoration: none;">{$address.email}</a>
                            </div>
                        </td>
                        <td width="4%"></td>
                        <td width="48%" valign="top">
                            <!-- ADRESSE DE LIVRAISON (Conditionnelle) -->
                            {if !empty($shippingAddress)}
                                <h3 style="color: #444444; font-size: 18px;">Adresse de livraison</h3>
                                <div style="background: #f8f9fa; border-left: 4px solid #198754; padding: 15px; font-size: 15px; line-height: 22px;">
                                    {if !empty($shippingAddress.company)}<strong>{$shippingAddress.company}</strong><br>{/if}
                                    {$shippingAddress.firstname} {$shippingAddress.lastname}<br>
                                    {$shippingAddress.street}<br>
                                    {$shippingAddress.postcode} {$shippingAddress.city}<br>
                                    {$shippingAddress.country}<br><br>
                                    <span style="color: #666;">Tél :</span> {$shippingAddress.phone|default:'Non renseigné'}<br>
                                </div>
                            {/if}
                        </td>
                    </tr>
                </table>

                <!-- INFO PAIEMENT (Uniquement si c'est une commande validée) -->
                {if $type_doc == 'order'}
                    <hr style="border:none; border-top: 1px solid #EEEEEE; margin: 25px 0;">
                    <h3 style="color: #444444; font-size: 18px;">Instructions de paiement</h3>
                    <p>Veuillez effectuer un virement bancaire pour valider définitivement votre commande :</p>
                    <ul style="background: #fff8e1; padding: 15px 15px 15px 35px; border: 1px solid #ffe082; border-radius: 4px;">
                        <li style="margin-bottom: 5px;"><strong>Bénéficiaire :</strong> {$config.account_owner|default:'À configurer'}</li>
                        <li style="margin-bottom: 5px;"><strong>IBAN :</strong> {$config.bank_account|default:'À configurer'}</li>
                        {if !empty($config.bank_address)}<li style="margin-bottom: 5px;"><strong>Banque :</strong> {$config.bank_address|nl2br}</li>{/if}
                        <li><strong>Communication (à rappeler) :</strong> <span style="font-weight: bold; color: #d32f2f;">{$reference}</span></li>
                    </ul>
                    <p style="font-size: 14px; color: #777;">Votre commande sera expédiée dès réception de votre paiement.</p>
                {/if}

                <p style="margin-top: 30px;">À très bientôt sur notre boutique.</p>
            </td>
        </tr>
    </table>
{/block}