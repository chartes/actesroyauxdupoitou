# Actes royaux du Poitou

This is a non-destructive DoTS import package.

* `data/` contains the unmodified TEI documents accepted by DoTS.
* `metadata/` supplies the collection and document metadata mapping.
* `site-context/` preserves the pages and assets reachable from the corresponding ÉLEC/CORPUS site path, including the home page, credits and footer where supplied by the site.
* `provenance.json` records the source revision and SHA-256 of every importable TEI document.

Import with the DoTS project script (from the DoTS repository):

```bash
./scripts/project_create.sh \
  --basex_path /path/to/basex/bin \
  --project_dir_path /path/to/actesroyauxdupoitou \
  --top_collection_id actesroyauxdupoitou \
  --db_name actesroyauxdupoitou \
  --root_id actesroyauxdupoitou \
  --root_title "Actes royaux du Poitou"
```

The corpus source declares its own rights and credit statements in each TEI header. Do not publish an altered transcription without confirming that those terms permit it.
