{extends file="layout.tpl"}

{block name='head:title'}Opération validée{/block}

{block name='article'}
    <div class="container py-5 text-center">
        <div class="row justify-content-center">
            <div class="col-md-8 col-lg-6">
                <div class="card shadow border-0 p-5">
                    <div class="mb-4">
                        <i class="bi bi-check-circle-fill text-success" style="font-size: 4rem;"></i>
                    </div>
                    <h1 class="h2 fw-bold text-dark mb-3">Merci !</h1>
                    <p class="lead text-muted mb-4">
                        Votre demande portant la référence <strong class="text-primary">{$smarty.get.success|escape}</strong> a bien été enregistrée.
                        Vous recevrez un e-mail de confirmation d'ici quelques instants.
                    </p>
                    <div class="d-grid gap-2 d-md-block">
                        {* CORRECTION DU LIEN DE RETOUR À L'ACCUEIL *}
                        <a href="{$site_url|trim:'/'}/{$current_lang.iso_lang|lower}/" class="btn btn-outline-secondary px-4 fw-bold">
                            Retour à l'accueil
                        </a>
                    </div>
                </div>
            </div>
        </div>
    </div>
{/block}