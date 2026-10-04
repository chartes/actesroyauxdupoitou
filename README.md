# Actes royaux du Poitou (1302-1483)

Édition électronique du *Recueil des documents concernant le Poitou contenus dans les registres de la Chancellerie de France*, publié par Paul Guérin, en 12 tomes. Ce dépôt en est la version préparée pour DoTS (branche `migration`).

## Origine du texte

Le texte provient des 12 fichiers **TEI d'origine** du site Corpus de l'École des chartes, `http://corpus.enc.sorbonne.fr/actesroyauxdupoitou/` (moteur Diple), un par tome. Ce ne sont pas des pages HTML reconverties. Depuis le 30/09/2026, ces 12 fichiers sont réunis dans un seul document, `data/actesroyauxdupoitou.xml` (voir plus bas) ; les fichiers par tome restent dans l'historique git (jusqu'au commit `0ee3a5e`).

- Le texte vient d'une **numérisation OCR**, par l'École des chartes, des PDF de Gallica (BnF). Il en garde des fautes de lecture (« ll » pour « Il », « Ton » pour « l'on »…), qui n'ont pas été relues.
- Encodage : Vincent Jolivet en 2011 pour les tomes 1, 6 et 10 (avec Joana Casenave, parties du discours, et Laura Gilli, relecture) ; Mathilde Henriquet de 2013 à 2015 pour les tomes 2 à 5, 7 à 9, 11 et 12.
- Les fichiers ont été versés tels quels dans ce dépôt en 2018 (commit `e5bea71`). Leur empreinte d'origine est conservée dans `provenance.json`.

**Le texte des actes n'a pas été réécrit.** Deux corrections seulement touchent aux mots (« Poitoux » dans le titre du tome 10, un point final replacé dans un régeste du tome 4). Les autres modifications portent sur l'en-tête (`teiHeader`), la structure (unités citables, titres de tableau, repères de page) et la conformité TEI.

## Contenu du dépôt

| Dossier | Contenu |
|---|---|
| `data/` | le document TEI unique `actesroyauxdupoitou.xml` (identifiant DoTS `royaux_poitou`), qui contient les 12 tomes |
| `metadata/` | métadonnées pour DoTS : `collection.tsv` (collection racine), `dots_metadata_mapping.xml` (métadonnées du document, lues dans l'en-tête), `documents_metadata.tsv` (liste du document ; non lue par le mapping actuel) |
| `transform/` | feuille XSL propre au corpus (`actesroyauxdupoitou.xsl`), qui surcharge la feuille commune `hteiml` |
| `schema/` | schéma d'origine du projet (`actesroyauxdupoitou.rng`) ; il inclut `../../diple/schema/acte.rng`, absent de ce dépôt |
| `provenance.json` | empreintes SHA-256 des 12 fichiers d'origine (2018), des 12 fichiers juste avant leur réunion et du document unique |

Les pages du site Corpus archivées lors de la migration (`site-context/`, 1 474 pages) ne sont pas versionnées (`.gitignore`).

## Structure du document unique

```
TEI  xml:id="royaux_poitou"
├── teiHeader            en-tête de la collection : titre, Paul Guérin, 4 contributeurs
│                        (VJ, JC, LG, MH), financeur, éditeur, licence, 12 volumes
│                        imprimés (sourceDesc/listBibl), historique de chaque tome
└── text
    ├── front            textes d'accompagnement (sommaire, niveau 1, unité « partie »)
    │   ├── div xml:id="presentation"     La collection
    │   └── div xml:id="documentation"    Documentation (schéma du site Corpus)
    └── group
        ├── text xml:id="tome1" n="I"     un tome (sommaire, niveau 1, unité « tome »)
        │   ├── front
        │   │   ├── head                  titre du tome (d'origine)
        │   │   ├── div type="volume"     volume imprimé, actes, encodeurs du tome
        │   │   └── div type="introduction" xml:id="tome1_introduction-1" …
        │   │                             (niveau 2, unité « introduction » ; tomes I, VI, X)
        │   └── group                     actes, inchangés : text xml:id="tome1_0001" …
        │                                 (niveau 2, unité « acte »)
        ├── text xml:id="tome2" n="II"
        └── …  text xml:id="tome12" n="XII"
```

Le sommaire DoTS compte 1 773 entrées : 2 textes d'accompagnement, 12 tomes (« Tome VI (1390-1403) »), 13 introductions et 1 746 actes. Les identifiants des tomes, des introductions et des actes n'ont pas changé ; ils ne sont plus des documents mais des passages du document `royaux_poitou`.

L'identifiant du document n'est pas `actesroyauxdupoitou` : c'est déjà celui de la collection racine, et DoTS cherche collections et documents dans le même registre (`@dtsResourceId`) ; un document du même nom rendrait la collection et le document inaccessibles.

Adresses (application DoTS) : `…/actesroyauxdupoitou/document/royaux_poitou` pour la page de garde, `…?refId=tome6` pour un tome, `…?refId=tome6_0748` pour un acte, `…?refId=documentation` pour la documentation. API : `/api/dts/document?resource=royaux_poitou&ref=tome6_0748`.

La **Documentation** reprend la page « Documentation » du site Corpus (`/actesroyauxdupoitou/schema`), rédigée par Frédéric Glorieux et Vincent Jolivet ; elle est convertie en TEI (sections, tableaux de grammaire, exemple en `egXML`, éléments en `gi`, attributs en `att`, valeurs en `val`), sans coupe.

## Modifications apportées à la TEI

| Commit | Modification |
|---|---|
| `fafc602` | Déclaration des actes comme unités citables (`refsDecl`) ; notice BnF de l'ouvrage (`title/@ref`) ; autorités de l'École (`funder/@ref`) |
| `0ce3995` | `publisher/@ref` : site de l'École (`https://www.chartes.psl.eu/`) |
| `b7af68c` | Report du travail fait directement en base les 14 et 18/09 : autorités de Paul Guérin (Wikidata `Q34639346`, BnF `cb12382835z`, IdRef `032885288`), sommaire à deux niveaux (introductions et actes), identifiants des introductions |
| `cb0ac26` | Identifiants des 13 introductions préfixés par le tome (`tome6_introduction-1`…) : ils se répétaient d'un tome à l'autre, et les introductions des tomes 6 et 10 affichaient celles du tome 1 |
| `3e756d6` | Titres du sommaire : plus de « () » pour les 4 actes sans date ; le titre d'une introduction ne reprend plus le texte de ses notes |
| `3a5467f` | Conformité `tei_all` : 53 erreurs corrigées (titres des 17 tableaux du tome 7, ordre `publisher`/`date`/`idno`, « Et au dos : » hors paragraphe, point hors du régeste, `term/@typ`) |
| `aa6c686` | Défauts de source : numéro de note isolé (`tome10_1273`), numéro d'acte en double (`tome11_1463`), « Poitoux » dans le titre du tome 10 |
| `8e30af2` | Licence déclarée dans un élément `<licence>` (CC BY-NC-ND 2.0 FR), lue par le mapping |
| `d481c8b` | Page de départ de 1 441 actes (`<milestone unit="page" type="depart"/>`), que DoTS ne pouvait plus afficher en servant chaque acte seul |
| `fc5af5a` | Réunion des 12 tomes en un seul document : en-tête commun, textes d'accompagnement (présentation, documentation du site Corpus), tomes en parties du sommaire. Le contenu des 1 746 actes et des 13 introductions est identique (XML canonique) à celui des 12 fichiers |

La feuille `transform/` a été remplacée par celle réellement servie (`dd7e6eb`) : notes de type « a », page de garde des tomes, liens vers l'ancien site ; puis elle a reçu l'affichage de la page de départ et le texte des notes en infobulle (`64857da`), comme sur Corpus. Avec le document unique (`fc5af5a`), la page de garde est celle de la collection ; la page d'un tome montre son titre et son bloc « volume » ; la feuille rend aussi les valeurs d'attribut de la documentation et plafonne ses titres à `h6`.

## Non traité, volontairement

| Cas | Nombre | Raison |
|---|---|---|
| `listWit/@type` (`copie`, `edition`), refusé par `tei_all` | 3 490 | Laissé tel quel (décision du 30/09) |
| `date/@when=""` (date normalisée vide) | 130 | Laissé tel quel |
| Élément `x`, inexistant en TEI | 2 | Laissé tel quel |
| Fautes d'OCR dans le texte | — | Relecture éditoriale à part, non engagée |

État de conformité : **3 622 erreurs `tei_all`** (3 675 à l'origine), dont 3 490 pour `listWit/@type`.

## Import dans DoTS

Le corpus s'importe dans une base BaseX `actesroyauxdupoitou` (collection racine `actesroyauxdupoitou`, un seul document `royaux_poitou`) avec les scripts du dépôt DoTS. La recette de passage de 12 documents à 1 est dans `PROPOSITION-reingestion.md`. Avant toute réingestion :

- sauvegarder la base (`db:create-backup`) ;
- vérifier que la base ne porte pas de travail absent du dépôt (c'était le cas avant `b7af68c`) ;
- après reconstruction des registres, vérifier la collection racine (`/api/dts/collection`) et pas seulement les documents.

## Droits

Le document est diffusé par l'École nationale des chartes sous licence **Creative Commons BY-NC-ND 2.0 France** (voir `availability/licence` dans l'en-tête).
