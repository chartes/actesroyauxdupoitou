<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <xsl:import href="../../renderers/hteiml/xsl/tei2html.xsl"/>
  <xsl:output indent="no"/><!-- autopilote 2026-09-11 : sinon DoTS-vue colle les mots (condense) -->

  <!-- 2026-10-08 : page de garde generique (modele Montferrand), commune a tous les corpus.
       Remplace la garde propre a ce corpus (teiHeader rendu en entier, corps masque).
       Sauvegarde : dossier chantier/garde2, fichier arp_avant_garde_commun.xsl. -->
  <xsl:include href="garde.xsl"/>

  <xsl:template match="*[local-name() = 'x']" priority="20">
    <span class="x"><xsl:apply-templates/></span>
  </xsl:template>

  <xsl:template match="*[local-name() = 'x']" mode="a" priority="20">
    <span class="x"><xsl:apply-templates/></span>
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

  <!-- Bloc des notes en pied (2026-10-02) : un seul modele pour les deux cas (porteur
       present / notes enfants du wrapper), qui en avaient deux copies. Plus de styles en
       dur : couleurs, filet et corps sont dans la CSS du corpus (section.footnotes,
       aside.note, a.noteref, a.noteback). -->
  <xsl:template name="actes-notes-pied">
    <xsl:param name="notes"/>
    <section class="footnotes">
      <xsl:for-each select="$notes">
        <aside class="note" id="fn-{generate-id()}">
          <a class="noteback" href="#fn-{generate-id()}-ref"><sup><xsl:call-template name="actes-note-n"/></sup></a>
          <xsl:text> </xsl:text>
          <xsl:apply-templates/>
        </aside>
      </xsl:for-each>
    </section>
  </xsl:template>

  <!-- appel de note (inline) -->
  <!-- Infobulle (2026-09-30) : le texte de la note dans @title de l'appel, comme
       sur le site Corpus historique (a.refnote title="1 Guillaume VI, …"). -->
  <xsl:template match="tei:note[@type = 'footnote' or @type = 'a' or not(@type)]" priority="10">
    <xsl:variable name="n"><xsl:call-template name="actes-note-n"/></xsl:variable>
    <a class="noteref" id="fn-{generate-id()}-ref" href="#fn-{generate-id()}"
       title="{normalize-space(concat($n, ' ', .))}"><sup><xsl:value-of select="$n"/></sup></a>
  </xsl:template>

  <!-- deport des corps en pied de chaque acte / division d'introduction -->
  <xsl:template match="tei:group/tei:text | tei:front/tei:div[@type = 'introduction'] | tei:div[parent::*[local-name() = 'wrapper']] | tei:text[parent::*[local-name() = 'wrapper']]" priority="10">
    <xsl:apply-imports/>
    <xsl:variable name="notes" select=".//tei:note[@type = 'footnote' or @type = 'a' or not(@type)]"/>
    <xsl:if test="$notes">
      <xsl:call-template name="actes-notes-pied">
        <xsl:with-param name="notes" select="$notes"/>
      </xsl:call-template>
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
    <xsl:apply-templates/>
    <xsl:variable name="notes" select=".//tei:note[@type = 'footnote' or @type = 'a' or not(@type)][not(ancestor::tei:text)][not(ancestor::tei:div[parent::*[local-name() = 'wrapper']])][not(ancestor::tei:div[@type = 'introduction'][parent::tei:front])]"/>
    <xsl:call-template name="actes-notes-pied">
      <xsl:with-param name="notes" select="$notes"/>
    </xsl:call-template>
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

  <xsl:template match="tei:licence/@target">
    <a class="licence" href="{.}">
      <xsl:choose>
        <xsl:when test="contains(., 'by-nc-nd/2.0/fr')">Licence Creative Commons BY-NC-ND 2.0 France</xsl:when>
        <xsl:otherwise>Licence</xsl:otherwise>
      </xsl:choose>
    </a>
  </xsl:template>

  <!--
    Document unique (2026-09-30). Les 12 tomes sont reunis dans un seul
    document : TEI/text/front porte les textes d'accompagnement (presentation,
    documentation), TEI/text/group les 12 tomes, chacun text[@xml:id='tomeN']
    avec son front (titre, div[@type='volume'], introductions) et son group
    d'actes.

    Page d'un tome. DoTS la sert sous deux formes :
      - fragment normal : dts:wrapper > text[@xml:id='tomeN'] ;
      - excludeFragments=true : dts:wrapper > front, group (les introductions
        et les actes ne sont pas des enfants directs du tome : DoTS ne les
        retire pas).
    Dans les deux cas on n'affiche que le titre du tome et son bloc « volume »
    (volume imprime, actes, encodeurs) ; introductions et actes ont leurs
    propres pages. Priorite 25 : au-dessus du deport des notes (10-11).
  -->
  <xsl:template match="tei:text[tei:group][parent::*[local-name() = 'wrapper']]" priority="25">
    <article class="text tome" id="{@xml:id}">
      <xsl:call-template name="arp-page-tome"/>
    </article>
  </xsl:template>
  <xsl:template match="*[local-name() = 'wrapper'][tei:front][tei:group][not(tei:teiHeader)]" priority="25">
    <article class="text tome">
      <xsl:call-template name="arp-page-tome"/>
    </article>
  </xsl:template>
  <xsl:template name="arp-page-tome">
    <header class="front">
      <xsl:apply-templates select="tei:front/tei:head"/>
      <xsl:apply-templates select="tei:front/tei:div[@type = 'volume']"/>
    </header>
  </xsl:template>

  <!-- ===== HTEIML RESPONSIVE (2026-10-08) : corrections de compatibilite =====
       La branche responsive de hteiml ne traverse pas dts:wrapper (elle le rend en
       marque d'erreur), ne donne pas la cartouche d'acte pour un fragment, ne garde
       pas les blancs contenant un saut de ligne entre deux noeuds (DoTS-vue colle
       les mots), et produit un signet « § » a href vide quand un titre n'a pas de div. -->

  <!-- DoTS sert certains fragments dans un conteneur dts:wrapper : on le traverse. -->
  <xsl:template match="*[local-name() = 'wrapper']" priority="10">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Cartouche d'entete d'acte dans un fragment (dts:wrapper/text/front) : <header class="front">,
       comme la generique du tei2html local ; la responsive ne couvre que le cas group/text/front. -->
  <xsl:template match="*[local-name() = 'wrapper']/tei:text/tei:front" priority="10">
    <header class="front">
      <xsl:call-template name="atts"/>
      <xsl:apply-templates/>
      <xsl:apply-templates select=".//tei:witness[@ana='edited']" mode="according"/>
    </header>
  </xsl:template>

  <!-- Blanc contenant un saut de ligne entre deux noeuds : une espace simple (DoTS-vue
       compile le HTML en « condense », qui colle sinon les mots). Meme regle que le hteiml local. -->
  <xsl:template match="text()[not(normalize-space())][contains(., '&#10;')]
      [preceding-sibling::node()][following-sibling::node()]
      [not(../tei:w) or not(following-sibling::*[1][self::tei:w or self::tei:pc])]
      [not(parent::tei:choice or parent::tei:app or parent::tei:subst or parent::tei:table or parent::tei:row
           or parent::tei:list or parent::tei:listBibl)]">
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- Titre hors division (titre d'acte, de tome) : meme rendu que la responsive, sans signet
       quand il n'y a pas de division a laquelle renvoyer (href vide = retour a l'accueil dans DoTS-vue). -->
  <xsl:template match="tei:head[not(ancestor::tei:div)]" priority="3">
    <xsl:param name="level" select="count(ancestor::tei:*) - 2"/>
    <xsl:variable name="name">
      <xsl:choose>
        <xsl:when test="normalize-space(.) = ''"/>
        <xsl:when test="parent::tei:front | parent::tei:text | parent::tei:back">h1</xsl:when>
        <xsl:when test="$level &lt; 1">h1</xsl:when>
        <xsl:when test="$level &gt; 7">h6</xsl:when>
        <xsl:otherwise>h<xsl:value-of select="$level"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$name != ''">
      <xsl:apply-templates select="tei:pb"/>
      <xsl:element name="{$name}" namespace="http://www.w3.org/1999/xhtml">
        <xsl:call-template name="atts">
          <xsl:with-param name="class"><xsl:value-of select="../@type"/></xsl:with-param>
        </xsl:call-template>
        <xsl:apply-templates select="node()[local-name()!='pb']"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <!-- AUTEUR AVEC PLUSIEURS URI (2026-10-08) : <author ref="URI1 URI2 URI3">. La generique
       met les trois URI dans un seul href (sur un span : rien n'est cliquable). On rend
       le nom puis un lien par URI, libelle selon l'hote (Wikidata, BnF, IdRef). -->
  <xsl:template match="tei:author[@ref]" priority="10">
    <span class="author">
      <xsl:apply-templates/>
      <xsl:text> </xsl:text>
      <span class="author-ids">
        <xsl:text>(</xsl:text>
        <xsl:for-each select="tokenize(normalize-space(@ref), ' ')">
          <xsl:if test="position() &gt; 1"><xsl:text>, </xsl:text></xsl:if>
          <a href="{.}">
            <xsl:choose>
              <xsl:when test="contains(., 'wikidata.org')">Wikidata</xsl:when>
              <xsl:when test="contains(., 'data.bnf.fr') or contains(., 'catalogue.bnf.fr')">BnF</xsl:when>
              <xsl:when test="contains(., 'idref.fr')">IdRef</xsl:when>
              <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
            </xsl:choose>
          </a>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
      </span>
    </span>
  </xsl:template>

  <!-- Documentation : valeurs d'attribut (<val>), que hteiml ne connait pas. -->
  <xsl:template match="tei:val">
    <code class="val"><xsl:apply-templates/></code>
  </xsl:template>

  <!-- Titres profonds (sections imbriquees de la documentation) : hteiml
       transmet aux titres un niveau egal a la profondeur de la section et
       produit <h7> au niveau 7, qui n'existe pas en HTML ; on plafonne a 6.
       En dessous, le titre est rendu exactement comme avant. -->
  <xsl:template match="tei:div/tei:head" priority="2">
    <xsl:param name="level" select="count(ancestor::tei:*) - 2"/>
    <xsl:choose>
      <xsl:when test="$level &gt; 6">
        <xsl:apply-imports><xsl:with-param name="level" select="6"/></xsl:apply-imports>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports><xsl:with-param name="level" select="$level"/></xsl:apply-imports>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

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
