<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">
  <!-- Actes royaux du Poitou : surcharge de hteiml, reconstruite le 13/10/2026 en partant
       du rendu hteiml nu.

       Le site historique (corpus.enc.sorbonne.fr/actesroyauxdupoitou) était servi par Diple,
       dont hteiml descend : son HTML (article.text, header.front, ul.listWit, span.pb) est
       déjà celui de hteiml. La feuille ne corrige donc que ce que hteiml rend mal ou ne
       connaît pas, et reprend tous les modèles de la version précédente :
       - notes de bas de page numérotées par acte (ou par introduction) et rendues au pied
         de chaque acte, non en fin de fragment ;
       - page d'un tome : titre et volumes, sans la liste des actes (portée par le sommaire) ;
       - en-tête d'un acte, avec « D'après a. » (témoin édité) ;
       - niveau des titres d'après la profondeur (h1 à h6) ;
       - blancs entre deux éléments gardés (Vue retire les blancs à saut de ligne) ;
       - auteurs et leurs identifiants (Wikidata, BnF, IdRef), valeurs de la documentation,
         page de l'édition imprimée où commence l'acte, liens vers l'ancien site. -->
  <!-- ==== 0. DÉCLARATIONS : imports, sortie, paramètres, variables, clés, fonctions ==== -->
  <xsl:import href="../../renderers/hteiml/xsl/tei2html.xsl"/>
  <xsl:output indent="no"/>

  <!-- ==== 1. HISTORIQUE : surcharge reprise de la feuille de l'ÉLEC (rendu du texte de l'édition) ==== -->
  <!-- (aucun) -->

  <!-- ==== 2. BLOCS HTEIML GÉNÉRIQUES : enveloppe dts:wrapper, notes ==== -->
  <xsl:template name="footnotes"/>
  <!-- 2026-11-05 (Maxime : « a b c d = notes, on met pas d'apparat critique sur actes royaux ») : les notes de leçon
       (note type="a", 32 : « Mot omis », « Sic. ») sont des notes comme les autres, dans la même suite au pied de l'acte,
       appelées par leur lettre. Numéros des autres notes : @n de l'édition imprimée (20, 21…), sinon 1 à n par acte. -->
  <xsl:template name="actes-note-n">
    <xsl:choose>
      <xsl:when test="@type = 'a'">
        <xsl:number count="tei:note[@type = 'a']" level="any" from="tei:text | tei:front/tei:div[@type = 'introduction']" format="a"/>
      </xsl:when>
      <xsl:when test="normalize-space(@n) != ''"><xsl:value-of select="@n"/></xsl:when>
      <xsl:otherwise>
        <xsl:number count="tei:note[@type = 'footnote' or not(@type)]" level="any"
          from="tei:text | tei:front/tei:div[@type = 'introduction']"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
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
  <xsl:template match="tei:note[@type = 'footnote' or @type = 'a' or not(@type)]" priority="10">
    <xsl:variable name="n"><xsl:call-template name="actes-note-n"/></xsl:variable>
    <a class="noteref" id="fn-{generate-id()}-ref" href="#fn-{generate-id()}"
       title="{normalize-space(concat($n, ' ', .))}"><sup><xsl:value-of select="$n"/></sup></a>
  </xsl:template>
  <xsl:template match="tei:group/tei:text | tei:front/tei:div[@type = 'introduction'] | tei:div[parent::*[local-name() = 'wrapper']] | tei:text[parent::*[local-name() = 'wrapper']]" priority="10">
    <xsl:apply-imports/>
    <xsl:variable name="notes" select=".//tei:note[@type = 'footnote' or @type = 'a' or not(@type)]"/>
    <xsl:if test="$notes">
      <xsl:call-template name="actes-notes-pied">
        <xsl:with-param name="notes" select="$notes"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template match="tei:text[tei:group][parent::*[local-name() = 'wrapper']]" priority="25">
    <article class="text tome" id="{@xml:id}">
      <xsl:call-template name="arp-page-tome"/>
    </article>
  </xsl:template>
  <!-- 2026-11-02 (demande de Maxime) : la page d'un tome n'affiche plus rien d'elle-même, ni notice du volume
       (div type="volume") : seul le sommaire de dots-vue.
       2026-11-04 (Maxime) : le titre du tome revient en tête de la page, au-dessus du sommaire, avec le même
       libellé que le sommaire (citeData de la citeStructure « tome » : « Tome I (1302-1333) »). -->
  <xsl:template name="arp-page-tome">
    <h1 class="head">
      <xsl:value-of select="concat('Tome ', @n, ' (', (tei:front/tei:div[@type = 'volume']//tei:date[@from])[1], ')')"/>
    </h1>
  </xsl:template>
  <xsl:template match="*[local-name() = 'wrapper']" priority="10">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="*[local-name() = 'wrapper']/tei:text/tei:front" priority="10">
    <header class="front">
      <xsl:call-template name="atts"/>
      <xsl:apply-templates/>
      <xsl:apply-templates select=".//tei:witness[@ana='edited']" mode="according"/>
    </header>
  </xsl:template>
  <xsl:template match="text()[not(normalize-space())][contains(., '&#10;')]
      [preceding-sibling::node()][following-sibling::node()]
      [not(../tei:w) or not(following-sibling::*[1][self::tei:w or self::tei:pc])]
      [not(parent::tei:choice or parent::tei:app or parent::tei:subst or parent::tei:table or parent::tei:row
           or parent::tei:list or parent::tei:listBibl)]">
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- ==== 3. PROPRE AU PROJET ==== -->
  <!-- 2026-11-05 (Maxime) : parties du discours diplomatique (seg@function, 1 604) plus affichées ; hteiml rend
       le seg sans balise (texte suivi). -->
  <!-- 2026-11-05 : renvois des notes au recueil (1 044), encodés sans adresse d'application :
       <ref type="renvoi" target="#tome6_0780" n="136">. L'xml:id de l'acte est son refId (citeStructure use="@xml:id"),
       n la page imprimée, dont hteiml fait l'ancre #pbN : l'adresse dots-vue se compose sans chercher la cible. -->
  <xsl:template match="tei:ref[@type = 'renvoi'][starts-with(@target, '#')]" priority="10">
    <a class="renvoi" href="?refId={substring(@target, 2)}{if (normalize-space(@n)) then concat('#pb', normalize-space(@n)) else ''}">
      <xsl:apply-templates/>
    </a>
  </xsl:template>
  <xsl:template match="*[local-name() = 'x']" priority="20">
    <span class="x"><xsl:apply-templates/></span>
  </xsl:template>
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
  <!-- 2026-11-02 : dans les actes, <lb/> marque un alinéa de l'éditeur à l'intérieur d'un seul <p> (738 : début d'un
       vidimus, « Item » d'une énumération, reprise après l'acte cité). hteiml en fait un <br>, sur lequel le navigateur
       ignore toute marge : un span en bloc (CSS) coupe la ligne et met le blanc d'un paragraphe. -->
  <xsl:template match="tei:text[parent::tei:group or parent::*[local-name() = 'wrapper']]//tei:lb" priority="10">
    <span class="lb alinea"/>
  </xsl:template>
  <xsl:template match="tei:milestone[@unit = 'page'][@type = 'depart']">
    <span class="pb depart" title="Page de l'édition imprimée où commence l'acte">
      <xsl:text>{p. </xsl:text>
      <xsl:value-of select="@n"/>
      <xsl:text>}</xsl:text>
    </span>
  </xsl:template>

</xsl:transform>
