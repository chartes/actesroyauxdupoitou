# Proposition : réglages dots-vue pour le document unique

Rien n'a été modifié dans `dots-vue` ni dans `dots-vue-elec-settings`. Ce fichier liste ce qu'il faudra changer quand la base `actesroyauxdupoitou` aura été réingérée avec `data/actesroyauxdupoitou.xml` (voir `PROPOSITION-reingestion.md`).

## Identifiant du document

Le document s'appelle `recueil_poitou` (`TEI/@xml:id`), pas `actesroyauxdupoitou`. DoTS range collections et documents dans le même registre (`resources_register.xml`, attribut `@dtsResourceId`) et les retrouve par cet identifiant (`utils_dots:getDocInRegister`, `utils_dots:getDbName`) : un document nommé comme la collection racine renverrait deux nœuds, et la collection comme le document tomberaient en erreur. L'identifiant `recueil_poitou` n'existe nulle part ailleurs dans le registre `dots` (vérifié le 30/09 en lecture). Pour en changer, il suffit de remplacer la valeur de `TEI/@xml:id` (et la ligne de `metadata/documents_metadata.tsv`).

## `dots-vue-elec-settings/actesroyauxdupoitou.conf.json`

| Réglage | Actuel | Proposé | Pourquoi |
|---|---|---|---|
| `tableOfContentsSettings.editByCiteType` | `["acte"]` | `["partie", "tome", "introduction", "acte"]` | les 4 unités du `refsDecl` ont chacune leur page : textes d'accompagnement, tomes (titre + bloc « volume »), introductions, actes |
| `tableOfContentsSettings.tableOfContentDepth` | `1` | `2` | niveau 1 = textes d'accompagnement et tomes, niveau 2 = introductions et actes (DoTS-vue relève de toute façon la profondeur au niveau le plus profond des `editByCiteType`) |
| `tableOfContentsSettings.editByLevel` | `1` | à tester : `1` (comme Montferrand) ou `2` | `editByCiteType` prime quand il est renseigné ; vérifier qu'un clic sur un tome n'ouvre pas tous ses actes |
| `aboutPageSettings` | onglets `about1` (La collection) et `about2` (Les tomes) | retirer les deux onglets | « La collection » est désormais `refId=presentation` dans le document ; « Les tomes » n'apporte rien que le sommaire ne donne |
| `homePageSettings.pageHeader.aboutButtonText` | `Présentation` | le retirer, ou le faire pointer vers `document/recueil_poitou?refId=presentation` si le composant le permet | sans `aboutPageSettings`, vérifier que le bouton ne mène pas à une page vide |
| `homePageSettings.listSection.browseButtonText` | `Consulter les douze tomes` | inchangé | |

Les fichiers `about1.vue` et `about2.vue` deviennent inutiles (leur contenu est dans le `front` du document ; `about2.vue` ne contient aucun lien). Ne pas les supprimer avant d'avoir vérifié le rendu.

## `dots-vue-elec-settings/actesroyauxdupoitou/HomePageContent.vue`

| Lien actuel | Nouveau lien |
|---|---|
| `/actesroyauxdupoitou/document/tome1` (« Ouvrir le tome I ») | `/actesroyauxdupoitou/document/recueil_poitou?refId=tome1` |
| `/actesroyauxdupoitou/document/tome1?refId=tome1_0001` (« Lire le premier acte ») | `/actesroyauxdupoitou/document/recueil_poitou?refId=tome1_0001` |
| `/actesroyauxdupoitou/document/tome12` (« Accéder au tome XII ») | `/actesroyauxdupoitou/document/recueil_poitou?refId=tome12` |

On peut ajouter un lien « Documentation » : `/actesroyauxdupoitou/document/recueil_poitou?refId=documentation`.

La phrase d'introduction (« structurée pour une consultation par tome, acte et repère stable ») reste juste.

## Poids des pages

- La page de garde (niveau 0) est demandée par DoTS-vue avec le document entier (`document?resource=recueil_poitou&mediaType=html`, sans `excludeFragments`) : BaseX transforme 16 Mo pour ne rendre que l'en-tête (la feuille masque le `text`). C'était déjà le cas, tome par tome (1 à 2 Mo). À mesurer après réingestion ; si c'est trop lent, c'est le code de `Document.vue` (niveau 0) qu'il faudrait revoir, pas la TEI.
- La page d'un tome est servie avec tout le tome (1 à 2 Mo) dans les deux formes : `excludeFragments=true` ne retire que les fragments enfants **directs**, or introductions et actes sont des petits-enfants du tome (`front/div`, `group/text`). La feuille n'en rend que le titre et le bloc « volume » (≈ 1,7 Ko de HTML).

## Anciennes adresses à rediriger

### Application DoTS-vue (`/actesroyauxdupoitou/…`)

| Ancienne adresse | Nouvelle adresse | Nombre |
|---|---|---|
| `document/tomeN` | `document/recueil_poitou?refId=tomeN` | 12 |
| `document/tomeN?refId=X` (acte ou introduction) | `document/recueil_poitou?refId=X` | 1 759 |

Règle unique : `^/actesroyauxdupoitou/document/tome(\d+)$` → `/actesroyauxdupoitou/document/recueil_poitou?refId=tome$1` ; `^/actesroyauxdupoitou/document/tome\d+\?refId=(.+)$` → `/actesroyauxdupoitou/document/recueil_poitou?refId=$1`. Les `refId` n'ont pas changé.

### API DTS (`/dots/api/dts/…`)

| Ancienne adresse | Nouvelle adresse |
|---|---|
| `collection?id=tomeN` | `navigation?resource=recueil_poitou&ref=tomeN` (le tome n'est plus une ressource) |
| `navigation?resource=tomeN[&ref=X]` | `navigation?resource=recueil_poitou&ref=X` (ou `ref=tomeN`) |
| `document?resource=tomeN` | `document?resource=recueil_poitou&ref=tomeN` |
| `document?resource=tomeN&ref=X` | `document?resource=recueil_poitou&ref=X` |

### Site Corpus historique (`http://corpus.enc.sorbonne.fr/actesroyauxdupoitou/…`), d'après `site-context/URL-MAP.tsv`

| Ancienne page | Nouvelle adresse | Nombre |
|---|---|---|
| `/` | `/actesroyauxdupoitou` (accueil) | 1 |
| `/tomeN/` | `document/recueil_poitou?refId=tomeN` | 12 |
| `/tomeN/NNNN` (ou `NNNNbis`, `NNNNter`) | `document/recueil_poitou?refId=tomeN_NNNN` | 1 436 |
| `/tomeN/front-K` | `document/recueil_poitou?refId=tomeN_introduction-K` (à vérifier sur 2 ou 3 pages : la numérotation `front-K` du site peut ne pas suivre celle des introductions) | 8 archivées |
| `/schema` | `document/recueil_poitou?refId=documentation` | 1 |
| `/credits`, `/licence` | `document/recueil_poitou` (page de garde : contributeurs, licence) | 2 |
| `/src/` (téléchargement) | `/dots/api/dts/document?resource=recueil_poitou` | 1 |
