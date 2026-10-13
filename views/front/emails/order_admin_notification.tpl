{extends file="emails/layout.tpl"}

{block name="email_content"}
    <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
            <td style="padding: 20px; font-family: sans-serif; font-size: 16px; line-height: 24px; color: #333333;">
                <h2 style="margin-top: 0; color: #d32f2f;">
                    Nouvelle activité E-commerce
                </h2>

                <p>
                    Bonjour, une nouvelle demande a été effectuée sur votre site web.<br>
                    <strong>Type :</strong> {if $type_doc == 'order'}Commande (Vente){else}Demande de Devis{/if}<br>
                    <strong>Référence :</strong> {$reference}
                </p>

                <hr style="border:none; border-top: 1px solid #EEEEEE; margin: 20px 0;">

                <table width="100%" border="0" cellspacing="0" cellpadding="0" style="margin-bottom: 25px;">
                    <tr>
                        <td width="48%" valign="top">
                            <!-- COORDONNÉES CLIENT / FACTURATION -->
                            <h3 style="color: #444444; font-size: 18px;">Facturation</h3>
                            <div style="background: #f8f9fa; border-left: 4px solid #d32f2f; padding: 15px; font-size: 15px; line-height: 22px;">
                                {if !empty($address.company)}<strong>{$address.company}</strong><br>{/if}
                                {if !empty($address.vat_number)}TVA : {$address.vat_number}<br><br>{/if}
                                {$address.firstname} {$address.lastname}<br>
                                {$address.street}<br>
                                {$address.postcode} {$address.city}<br>
                                {$address.country}<br><br>
                                <strong>Tél :</strong> {$address.phone|default:'Non renseigné'}<br>
                                <strong>Email :</strong> <a href="mailto:{$address.email}" style="color: #d32f2f; text-decoration: none;">{$address.email}</a>
                            </div>
                        </td>
                        <td width="4%"></td>
                        <td width="48%" valign="top">
                            <!-- ADRESSE DE LIVRAISON (Conditionnelle) -->
                            {if !empty($shippingAddress)}
                                <h3 style="color: #444444; font-size: 18px;">Livraison</h3>
                                <div style="background: #f8f9fa; border-left: 4px solid #198754; padding: 15px; font-size: 15px; line-height: 22px;">
                                    {if !empty($shippingAddress.company)}<strong>{$shippingAddress.company}</strong><br>{/if}
                                    {$shippingAddress.firstname} {$shippingAddress.lastname}<br>
                                    {$shippingAddress.street}<br>
                                    {$shippingAddress.postcode} {$shippingAddress.city}<br>
                                    {$shippingAddress.country}<br><br>
                                    <strong>Tél :</strong> {$shippingAddress.phone|default:'Non renseigné'}<br>
                                </div>
                            {/if}
                        </td>
                    </tr>
                </table>

                <!-- DÉTAIL DES ARTICLES -->
                <h3 style="color: #444444; font-size: 18px; margin-top: 25px;">Contenu du panier</h3>
                <table width="100%" cellpadding="10" cellspacing="0" style="border: 1px solid #dddddd; border-collapse: collapse; margin-bottom: 20px; font-size: 14px;">
                    <thead>
                    <tr style="background-color: #f8f9fa;">
                        <th style="border: 1px solid #dddddd; text-align: left;">Article</th>
                        <th style="border: 1px solid #dddddd; text-align: center;">Qté</th>
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
                            <td style="border: 1px solid #dddddd; text-align: right;">{$item.total_price|number_format:2:',':' '} €</td>
                        </tr>
                    {/foreach}
                    </tbody>
                    <tfoot>
                    <tr>
                        <td colspan="2" style="border: 1px solid #dddddd; text-align: right; padding-top: 15px;"><strong>Total HT :</strong></td>
                        <td style="border: 1px solid #dddddd; text-align: right; padding-top: 15px;">{$cart.summary.total_ht|number_format:2:',':' '} €</td>
                    </tr>
                    {* --- AJOUT DE LA LIVRAISON DANS L'EMAIL ADMIN (Seulement si commande) --- *}
                    {if $type_doc == 'order'}
                        <tr>
                            <td colspan="2" style="border: 1px solid #dddddd; text-align: right;"><strong>Livraison HT :</strong></td>
                            <td style="border: 1px solid #dddddd; text-align: right;">{$cart.summary.total_shipping_ht|default:'0.00'|number_format:2:',':' '} €</td>
                        </tr>
                    {/if}
                    <tr style="background-color: #f8f9fa;">
                        <td colspan="2" style="border: 1px solid #dddddd; text-align: right; font-size: 16px;"><strong>TOTAL TTC :</strong></td>
                        <td style="border: 1px solid #dddddd; text-align: right; color: #d32f2f; font-weight: bold; font-size: 16px;">{$cart.summary.total_ttc|number_format:2:',':' '} €</td>
                    </tr>
                    </tfoot>
                </table>

                <p style="margin-top: 25px; text-align: center;">
                    <a href="{$site_url|trim:'/'}/magixadmin/index.php?controller=Magixcartpay" style="display: inline-block; padding: 10px 20px; background-color: #333; color: #fff; text-decoration: none; border-radius: 4px;">Voir dans l'administration</a>
                </p>
            </td>
        </tr>
    </table>
{/block}