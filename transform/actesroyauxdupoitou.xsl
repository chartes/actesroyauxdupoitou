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
  <xsl:import href="../../renderers/hteiml/xsl/tei2html.xsl"/>
  <xsl:output indent="no"/>
  <xsl:template match="*[local-name() = 'x']" priority="20">
    <span class="x"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="*[local-name() = 'x']" mode="a" priority="20">
    <span class="x"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template name="footnotes"/>
  <xsl:template name="actes-note-n">
    <xsl:choose>
      <xsl:when test="normalize-space(@n) != ''"><xsl:value-of select="@n"/></xsl:when>
      <xsl:otherwise>
        <xsl:number count="tei:note[@type = 'footnote' or @type = 'a' or not(@type)]" level="any"
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
  <xsl:template match="*[local-name() = 'wrapper'][.//tei:note[@type = 'footnote' or @type = 'a' or not(@type)][not(ancestor::tei:text)][not(ancestor::tei:div[parent::*[local-name() = 'wrapper']])][not(ancestor::tei:div[@type = 'introduction'][parent::tei:front])]]" priority="11">
    <xsl:apply-templates/>
    <xsl:variable name="notes" select=".//tei:note[@type = 'footnote' or @type = 'a' or not(@type)][not(ancestor::tei:text)][not(ancestor::tei:div[parent::*[local-name() = 'wrapper']])][not(ancestor::tei:div[@type = 'introduction'][parent::tei:front])]"/>
    <xsl:call-template name="actes-notes-pied">
      <xsl:with-param name="notes" select="$notes"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/actesroyauxdupoitou/']" priority="14">
    <a class="idno d5-local" href="/actesroyauxdupoitou"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:title[../tei:idno[@type = 'URI'][normalize-space(.) = 'http://elec.enc.sorbonne.fr' or normalize-space(.) = 'http://elec.enc.sorbonne.fr/']]" priority="14">
    <a class="title d5-local" href="/"><xsl:apply-templates/></a>
  </xsl:template>
  <xsl:template match="tei:licence/@target">
    <a class="licence" href="{.}">
      <xsl:choose>
        <xsl:when test="contains(., 'by-nc-nd/2.0/fr')">Licence Creative Commons BY-NC-ND 2.0 France</xsl:when>
        <xsl:otherwise>Licence</xsl:otherwise>
      </xsl:choose>
    </a>
  </xsl:template>
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
  <xsl:template match="tei:val">
    <code class="val"><xsl:apply-templates/></code>
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
  <xsl:template match="tei:milestone[@unit = 'page'][@type = 'depart']">
    <span class="pb depart" title="Page de l'édition imprimée où commence l'acte">
      <xsl:text>{p. </xsl:text>
      <xsl:value-of select="@n"/>
      <xsl:text>}</xsl:text>
    </span>
  </xsl:template>
</xsl:transform>
