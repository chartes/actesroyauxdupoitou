<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <xsl:import href="../../renderers/hteiml/xsl/tei2html.xsl"/>
  <xsl:output indent="no"/><!-- autopilote 2026-09-11 : sinon DoTS-vue colle les mots (condense) -->

  <xsl:template match="*[local-name() = 'x']" priority="20">
    <span class="x"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="*[local-name() = 'x']" mode="a" priority="20">
    <span class="x"><xsl:apply-templates/></span>
  </xsl:template>

  <!--
    Page de garde a la racine (meme correctif que chroniqueslatines.xsl) :

    DoTS Vue charge le document complet a la racine (Document.vue, currentLevel=0).
    Ce rendu contient le <teiHeader> (page de garde produite par teiHeader2html.xsl)
    PUIS tout le corps (les actes). Sans correctif, la page de titre s'affiche puis
    le corps entier la recouvre.

    On neutralise le corps <text> UNIQUEMENT quand le teiHeader est present, c.-a-d.
    au rendu du document entier (la racine). Les fragments (un acte) sont transformes
    isolement dans un <dts:wrapper> SANS teiHeader : ils ne sont pas touches.
    Priorite 15 pour dominer proprement les templates priorite 10 ci-dessous.
  -->
  <!-- Cas 1 : rendu du TEI complet (racine) : masquer le corps <text>. -->
  <xsl:template match="tei:text[//tei:teiHeader]" priority="15"/>

  <!-- Cas 2 : contenu servi dans un <dts:wrapper> embarquant le teiHeader
       (rendu racine via excludeFragments) : ne produire que la page de garde. -->
  <xsl:template match="*[local-name() = 'wrapper'][tei:teiHeader]" priority="20">
    <xsl:apply-templates select="tei:teiHeader"/>
  </xsl:template>

  <!--
    Actes royaux du Poitou : les notes de bas de page sont encodees INLINE, mais
    la convention varie selon les tomes :
      - tome 1        : <note type="footnote" n="N">…</note>
      - tomes 5,8,12… : <note>…</note>  (nues, sans type ni numero)
    La generique ne rend que l'appel et deporte les corps de facon incoherente
    (souvent rien) : texte des notes perdu, liens casses.

    Correctif : on traite les deux formes (note type=footnote OU note nue). Chaque
    division-feuille (introduction, tradition, transcription) rend son contenu
    normal (apply-imports) puis DEPORTE ses notes en pied, avec un numero (=@n si
    present, sinon numerotation automatique par division). generate-id() lie
    l'appel et son corps. Le "footnotes" generique est neutralise.
  -->

  <xsl:template name="footnotes"/>

  <!-- D43 (2026-09-14) : TROISIEME convention relevee dans le corpus, le tome 6.
       32 notes y portent <note type="a"> (32 sur 5 189 ; le tome 6 n'a aucune
       note @n ni @type='footnote', ses 414 notes sont 382 nues + 32 « a »).
       Elles n'entraient dans AUCUN des deux motifs ci-dessous : la generique
       hteiml en produisait l'appel (href="#noteN") et le modele nomme
       « footnotes », neutralise l. 57 de cette feuille, n'en produisait aucun
       corps. Douze mots de note editoriale (« Mot omis », « Sic. Lisez… »)
       etaient donc perdus, l'appel pointant dans le vide. On les traite
       exactement comme les autres notes de bas de page, numerotation comprise :
       dans le tome 6 aucune note n'a de @n, la serie automatique redevient
       simplement complete. -->

  <!-- numero d'une note : @n si present, sinon auto par division-feuille -->
  <xsl:template name="actes-note-n">
    <xsl:choose>
      <xsl:when test="normalize-space(@n) != ''"><xsl:value-of select="@n"/></xsl:when>
      <xsl:otherwise>
        <xsl:number count="tei:note[@type = 'footnote' or @type = 'a' or not(@type)]" level="any"
          from="tei:text | tei:front/tei:div[@type = 'introduction']"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- appel de note (inline) -->
  <xsl:template match="tei:note[@type = 'footnote' or @type = 'a' or not(@type)]" priority="10">
    <a class="noteref" id="fn-{generate-id()}-ref" href="#fn-{generate-id()}"
       style="text-decoration:none;color:#a73136;font-weight:bold"><sup><xsl:call-template name="actes-note-n"/></sup></a>
  </xsl:template>

  <!-- deport des corps en pied de chaque acte / division d'introduction -->
  <xsl:template match="tei:group/tei:text | tei:front/tei:div[@type = 'introduction'] | tei:div[parent::*[local-name() = 'wrapper']] | tei:text[parent::*[local-name() = 'wrapper']]" priority="10">
    <xsl:apply-imports/>
    <xsl:variable name="notes" select=".//tei:note[@type = 'footnote' or @type = 'a' or not(@type)]"/>
    <xsl:if test="$notes">
      <section class="footnotes" style="margin:1.2rem 0 0;padding-top:.7rem;border-top:1px solid #d7d1ca;font-size:.9rem;color:#333">
        <xsl:for-each select="$notes">
          <aside class="note" id="fn-{generate-id()}" style="margin:.35rem 0;line-height:1.45">
            <a class="noteback" href="#fn-{generate-id()}-ref" style="text-decoration:none;color:#a73136;font-weight:bold"><sup><xsl:call-template name="actes-note-n"/></sup></a>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
          </aside>
        </xsl:for-each>
      </section>
    </xsl:if>
  </xsl:template>

  <!--
    Avec excludeFragments=true, le resolver conserve le dts:wrapper mais retire
    le div d'introduction lui-meme. Les notes sont alors des enfants indirects
    du wrapper : le template ci-dessus ne peut plus les deporter. On les ajoute
    donc apres le rendu du wrapper, en reutilisant exactement les memes ancres.

    D43 (2026-09-14) — CORRECTION DU DOUBLE. Ce modele n'etait garde par aucune
    condition : il s'appliquait AUSSI au mode normal (celui du front DoTS-vue,
    qui ne demande jamais excludeFragments), ou le porteur — <text> d'un acte,
    <div> d'introduction — est present et a DEJA deporte ses notes par le
    modele precedent. Mesure du 2026-09-14 sur 85 unites des tomes 1, 5, 6, 8
    et 12 : 726 corps de notes rendus pour 363 notes reelles, soit chaque note
    en double, avec deux elements portant le meme id (l'ancre de retour de la
    seconde copie etait donc inatteignable). On restreint desormais le modele
    aux seules notes qu'aucun porteur ne prendra en charge : celles qui n'ont
    ni <text> ancetre, ni <div> ancetre enfant du wrapper, ni <div
    type="introduction"> ancetre — exactement les trois motifs du modele
    precedent. En mode normal l'ensemble est vide, le modele ne s'applique
    plus, et hteiml rend le wrapper comme d'habitude ; en mode
    excludeFragments il se comporte comme avant.
  -->
  <xsl:template match="*[local-name() = 'wrapper'][.//tei:note[@type = 'footnote' or @type = 'a' or not(@type)][not(ancestor::tei:text)][not(ancestor::tei:div[parent::*[local-name() = 'wrapper']])][not(ancestor::tei:div[@type = 'introduction'][parent::tei:front])]]" priority="11">
    <xsl:apply-imports/>
    <xsl:variable name="notes" select=".//tei:note[@type = 'footnote' or @type = 'a' or not(@type)][not(ancestor::tei:text)][not(ancestor::tei:div[parent::*[local-name() = 'wrapper']])][not(ancestor::tei:div[@type = 'introduction'][parent::tei:front])]"/>
    <section class="footnotes" style="margin:1.2rem 0 0;padding-top:.7rem;border-top:1px solid #d7d1ca;font-size:.9rem;color:#333">
      <xsl:for-each select="$notes">
        <aside class="note" id="fn-{generate-id()}" style="margin:.35rem 0;line-height:1.45">
          <a class="noteback" href="#fn-{generate-id()}-ref" style="text-decoration:none;color:#a73136;font-weight:bold"><sup><xsl:call-template name="actes-note-n"/></sup></a>
          <xsl:text> </xsl:text>
          <xsl:apply-templates/>
        </aside>
      </xsl:for-each>
    </section>
  </xsl:template>

  <!-- D5-DEBUT (autopilote 2026-09-12) : liens vers les anciens sites ELEC -->
  <!-- hteiml fait un lien de tout tei:idno commencant par « http » (tei2html.xsl l. 1805),
       du tei:title voisin d'un idno[@type='URI'] (l. 1796) et de tei:ref/@target (l. 1456).
       Les anciens sites ELEC ferment : le TEXTE affiche est conserve mot pour mot (c'est
       l'identifiant de la publication d'origine), seule la cible devient la route locale.
       Table et bloc produits par dots-autopilot/scripts/d5_legacy_links_fix.py. -->
  <!-- adresse ELEC de cette edition (12 tomes) -->
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/actesroyauxdupoitou/']" priority="14">
    <a class="idno d5-local" href="/actesroyauxdupoitou"><xsl:apply-templates/></a>
  </xsl:template>
  <!-- portail ELEC -->
  <xsl:template match="tei:title[../tei:idno[@type = 'URI'][normalize-space(.) = 'http://elec.enc.sorbonne.fr' or normalize-space(.) = 'http://elec.enc.sorbonne.fr/']]" priority="14">
    <a class="title d5-local" href="/"><xsl:apply-templates/></a>
  </xsl:template>
  <!-- D5-FIN -->

  <!--
    Page de depart d'un acte (2026-09-30). DoTS sert chaque acte seul : le
    dernier <pb> qui le precede reste dans l'acte d'avant, et la page de
    l'edition imprimee ou il commence n'etait plus affichee (l'ELEC, qui
    travaillait sur le tome entier, l'affichait). Elle est portee par la TEI
    en tete du front, <milestone unit="page" n="N" type="depart"/>, et rendue
    comme un <pb>. Absente quand l'acte commence lui-meme par un <pb>.
  -->
  <xsl:template match="tei:milestone[@unit = 'page'][@type = 'depart']">
    <span class="pb depart" title="Page de l'édition imprimée où commence l'acte">
      <xsl:text>{p. </xsl:text>
      <xsl:value-of select="@n"/>
      <xsl:text>}</xsl:text>
    </span>
  </xsl:template>

</xsl:transform>
