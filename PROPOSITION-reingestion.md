# Proposition : réingérer `actesroyauxdupoitou` (12 documents → 1)

Rien n'a été écrit dans BaseX. Recette à appliquer par REST (`bxq.py`), **une requête à la fois**, dans l'ordre, sans jamais interrompre une requête d'écriture en cours (une update tuée laisse `data\actesroyauxdupoitou\upd.basex` et la base inutilisable jusqu'au `db:restore`). Ne pas utiliser `project_create.sh` (chemin à espaces non quoté : il supprime la base puis échoue).

`$D` ci-dessous = le dossier de cette branche, copié si besoin dans un chemin sans espace.

## État de la base au 30/09 (lu, pas écrit)

- ressources : `tome1.xml` … `tome12.xml` **à la racine** de la base, `metadata/collection.tsv`, `metadata/collections.tsv`, `metadata/documents_metadata.tsv`, `metadata/dots_metadata_mapping.xml`, `dots/resources_register.xml`, `dots/fragments_register.xml` ;
- options : `updindex=false`, `autooptimize=false` (donc : `db:optimize` à la fin) ;
- registre : 1 collection (`actesroyauxdupoitou`, `totalChildren=13` : bogue connu, 12 attendus), 12 documents, 1 759 fragments ;
- switcher `dots` : le projet + 12 entrées `document` `tome1` … `tome12` ;
- sauvegardes : `actesroyauxdupoitou-2026-09-18-11-03-53`, `…-2026-09-14-21-20-14`.
- **La base est en retard sur le dépôt** (0 `milestone[@type='depart']` en base contre 1 441 dans le dépôt) ; `@ref` du `teiHeader` : 48 des deux côtés. Rien, a priori, n'existe en base sans exister sur le disque ; le revérifier le jour J (étape 0).

## Étapes

**0. Comparer base et dépôt** (lecture) : compter en base et dans `data/actesroyauxdupoitou.xml` les `@ref` d'en-tête, les `milestone[@type='depart']`, les `table/head`, les `@xml:id` ; tout ce qui serait en base et pas dans le fichier doit être reversé avant d'aller plus loin.

**1. Sauvegarder** : `db:create-backup('actesroyauxdupoitou')` (requête seule). Noter le nom de la sauvegarde.

**2. Remplacer les ressources** (une seule transaction) :

```xquery
let $db := 'actesroyauxdupoitou'
let $D := 'C:/…/poitou-document-unique/'
let $tsv := map { 'header': true(), 'separator': 'tab' }
return (
  for $n in 1 to 12 return db:delete($db, 'tome' || $n || '.xml'),
  db:delete($db, 'metadata/collections.tsv'),
  db:put($db, doc($D || 'data/actesroyauxdupoitou.xml'), 'actesroyauxdupoitou.xml'),
  db:put($db, doc($D || 'metadata/dots_metadata_mapping.xml'), 'metadata/dots_metadata_mapping.xml'),
  db:put($db, csv:doc($D || 'metadata/collection.tsv', $tsv), 'metadata/collection.tsv'),
  db:put($db, csv:doc($D || 'metadata/documents_metadata.tsv', $tsv), 'metadata/documents_metadata.tsv')
)
```

Le document va **à la racine** (`actesroyauxdupoitou.xml`), comme les tomes aujourd'hui, et surtout pas dans un dossier `actesroyauxdupoitou/` : c'est ce qui a fait créer la collection racine en double pour `comptes` (voir étape 4).

**3. Reconstruire les registres** (une transaction) :

```xquery
import module namespace resources = "backend/resources_register_builder";
resources:createResourcesRegister('actesroyauxdupoitou', 'actesroyauxdupoitou')
```

**4. Contrôler le registre des ressources** (lecture) : exactement **une** `collection[@dtsResourceId='actesroyauxdupoitou']` (sans `@parentIds`) et **un** `document[@dtsResourceId='recueil_poitou'][@parentIds='actesroyauxdupoitou']`. S'il existe une seconde collection `actesroyauxdupoitou` avec `@parentIds='actesroyauxdupoitou'` (piège de `collection.tsv` qui déclare l'identifiant racine, vécu sur `comptes` : `/collection` en 500 XPTY0004), la supprimer. Corriger `totalChildren` de la racine à **1** (bogue DoTS : `count(db:dir($db, ''))` compte aussi `dots/`). Le registre des fragments doit compter **1 773** `fragment` (2 `partie`, 12 `tome`, 13 `introduction`, 1 746 `acte`), `maxCiteDepth="2"`.

**5. Switcher `dots`, en deux requêtes séparées** (elles modifient le même compteur `totalProjects`) :

```xquery
(: 5a : retirer le projet et ses 12 anciens documents :)
delete nodes db:get('dots')/*:dbSwitch/*:member/*[@dbName = 'actesroyauxdupoitou'],
replace value of node db:get('dots')/*:dbSwitch/*:metadata/*:totalProjects
  with count(db:get('dots')/*:dbSwitch/*:member/*:project) - 1
```

```xquery
(: 5b : réinscrire le projet et son document recueil_poitou :)
import module namespace dots.update = "backend/dots_switcher_update";
dots.update:switcher('actesroyauxdupoitou', false())
```

Vérifier ensuite : plus aucune entrée `tome1` … `tome12` dans `dots`, une entrée `project` et une `document recueil_poitou`.

**6. Vider le cache** du projet (`store_clear:clear('actesroyauxdupoitou', 'recueil_poitou')` et `store_clear:clear('actesroyauxdupoitou', 'actesroyauxdupoitou')`, module `backend/update/store_clear`).

**7. Optimiser** : `db:optimize('actesroyauxdupoitou')`, **sans** `true()` (la reconstruction complète renumérote les node-id et casse le registre des fragments) et **après** l'étape 3.

**8. Vérifier l'API** (toutes doivent répondre 200) :

- `/api/dts/collection` (racine : ne pas se contenter du document) ;
- `/api/dts/collection?id=actesroyauxdupoitou` : un seul membre, `recueil_poitou` ;
- `/api/dts/navigation?resource=recueil_poitou` : 14 membres de niveau 1 (La collection, Documentation, Tome I … Tome XII) ;
- `/api/dts/navigation?resource=recueil_poitou&ref=tome6&down=1` : 5 introductions + 150 actes ;
- `/api/dts/document?resource=recueil_poitou&ref=tome6_0748&mediaType=html` : notes « a » en pied ; `ref=tome2_0184` : `{p. 2}` en tête ;
- `/api/dts/document?resource=recueil_poitou&ref=tome6&mediaType=html&excludeFragments=true` : titre du tome et bloc « volume » seulement ;
- `/api/dts/document?resource=recueil_poitou&ref=documentation&mediaType=html` ;
- `/api/dts/document?resource=recueil_poitou&mediaType=html` : page de garde de la collection (temps de réponse à noter : 16 Mo transformés).

**Retour arrière** : `db:restore('<nom de la sauvegarde de l'étape 1>')` (requête seule), puis refaire 5a et 5b (5b relit le registre restauré et réinscrit `tome1` … `tome12`) : la restauration ne touche pas au switcher `dots`.

Ensuite seulement, appliquer `PROPOSITION-dots-vue.md`.
