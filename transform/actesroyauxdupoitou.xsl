<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">
  
  <xsl:import href="../../renderers/hteiml/xsl/tei2html.xsl"/>
  <xsl:output indent="no"/>

  <xsl:template match="*[local-name() = 'wrapper']" priority="20">
    <xsl:apply-templates/>
    <xsl:if test="not(.//tei:text) and (.//tei:note[not(@place = 'margin')] or .//tei:app)">
      <xsl:call-template name="footnotes">
        <xsl:with-param name="cont" select="."/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tei:milestone[@unit = 'page'][@type = 'depart']">
    <a id="{concat(@unit, @n)}" href="#{concat(@unit, @n)}" class="pb">
      <xsl:text>{p. </xsl:text>
      <xsl:value-of select="@n"/>
      <xsl:text>}</xsl:text>
    </a>
  </xsl:template>
  
  <xsl:template match="tei:text[parent::tei:group or parent::*[local-name() = 'wrapper']]//tei:lb" priority="10">
    <span class="lb alinea"/>
  </xsl:template>
  
  <xsl:template match="text()[not(normalize-space())][contains(., '&#10;')]
    [preceding-sibling::node()][following-sibling::node()]
    [not(../tei:w) or not(following-sibling::*[1][self::tei:w or self::tei:pc])]
    [not(parent::tei:choice or parent::tei:app or parent::tei:subst or parent::tei:table or parent::tei:row
    or parent::tei:list or parent::tei:listBibl)]">
    <xsl:text> </xsl:text>
  </xsl:template>
  
  <xsl:template match="tei:ref[@type = 'renvoi'][starts-with(@target, '#')]" priority="10">
    <a class="renvoi" href="{if (contains(@target, '_')) then substring-before(substring(@target, 2), '_') else substring(@target, 2)}?refId={substring(@target, 2)}{if (normalize-space(@n)) then concat('#pb', normalize-space(@n)) else ''}">
      <xsl:apply-templates/>
    </a>
  </xsl:template>
  <xsl:template match="*[local-name() = 'x']" priority="20">
    <span class="x"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- 2026-11-06 (réunion avec Philippe) : notes numérotées par texte, à la position, sans compter les note type="a"
       (le tome 1 est numéroté de 1 à n dans le TEI, @n) ; note type="a" (« Mot omis », « Sic. », tome 6) en apparat
       critique : leur lettre, par texte, est dans le TEI (@n). -->
  <xsl:template name="note-n">
    <xsl:choose>
      <xsl:when test="@n"><xsl:value-of select="@n"/></xsl:when>
      <xsl:otherwise>
        <xsl:number count="tei:note[not(@type = 'a')]" level="any"
          from="tei:text | tei:front/tei:div[@type = 'introduction']"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="tei:text[not(tei:group)]/tei:body">
    <xsl:apply-imports/>
    <xsl:variable name="apparat" select="..//tei:note[@type = 'a']"/>
    <xsl:if test="$apparat">
      <p class="apparatus">
        <xsl:for-each select="$apparat">
          <xsl:call-template name="note-inline"/>
        </xsl:for-each>
      </p>
    </xsl:if>
  </xsl:template>
  <!-- modèle « note » de hteiml, sans les note type="a" : elles sont dans l'apparat, pas dans le pied de notes -->
  <xsl:template name="note">
    <xsl:if test="not(@type = 'a')">
      <aside class="{normalize-space(concat(@type, ' note'))}">
        <xsl:attribute name="id"><xsl:call-template name="id"/></xsl:attribute>
        <xsl:call-template name="noteback"/>
        <xsl:apply-templates/>
      </aside>
    </xsl:if>
  </xsl:template>
  
 <!--<xsl:template name="footnotes"/>-->
  <!-- 2026-11-05 (Maxime : « a b c d = notes, on met pas d'apparat critique sur actes royaux ») : les notes de leçon
       (note type="a", 32 : « Mot omis », « Sic. ») sont des notes comme les autres, dans la même suite au pied de l'acte,
       appelées par leur lettre. Numéros des autres notes : @n de l'édition imprimée (20, 21…), sinon 1 à n par acte. -->
  <!--<xsl:template name="actes-note-n">
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
  </xsl:template>-->
  <!--<xsl:template name="actes-notes-pied">
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
  </xsl:template>-->
  <!--<xsl:template match="tei:note[@type = 'footnote' or @type = 'a' or not(@type)]" priority="10">
    <xsl:variable name="n"><xsl:call-template name="actes-note-n"/></xsl:variable>
    <a class="noteref" id="fn-{generate-id()}-ref" href="#fn-{generate-id()}"
       title="{normalize-space(concat($n, ' ', .))}"><sup><xsl:value-of select="$n"/></sup></a>
  </xsl:template>-->
  <!--<xsl:template match="tei:group/tei:text | tei:front/tei:div[@type = 'introduction'] | tei:div[parent::*[local-name() = 'wrapper']] | tei:text[parent::*[local-name() = 'wrapper']]" priority="10">
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
  </xsl:template>-->
  <!-- 2026-11-02 (demande de Maxime) : la page d'un tome n'affiche plus rien d'elle-même, ni notice du volume
       (div type="volume") : seul le sommaire de dots-vue.
       2026-11-04 (Maxime) : le titre du tome revient en tête de la page, au-dessus du sommaire, avec le même
       libellé que le sommaire (citeData de la citeStructure « tome » : « Tome I (1302-1333) »). -->
  <!--<xsl:template name="arp-page-tome">
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
  </xsl:template>-->
  

  <!-- ==== 3. PROPRE AU PROJET ==== -->
  <!-- 2026-11-05 (Maxime) : parties du discours diplomatique (seg@function, 1 604) plus affichées ; hteiml rend
       le seg sans balise (texte suivi). -->
  <!-- 2026-11-05 : renvois des notes au recueil (1 044), encodés sans adresse d'application :
       <ref type="renvoi" target="#tome6_0780" n="136">. L'xml:id de l'acte est son refId (citeStructure use="@xml:id"),
       n la page imprimée, dont hteiml fait l'ancre #pbN : l'adresse dots-vue se compose sans chercher la cible. -->
  
  <!--<xsl:template match="tei:div/tei:head" priority="2">
    <xsl:param name="level" select="count(ancestor::tei:*) - 2"/>
    <xsl:choose>
      <xsl:when test="$level &gt; 6">
        <xsl:apply-imports><xsl:with-param name="level" select="6"/></xsl:apply-imports>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-imports><xsl:with-param name="level" select="$level"/></xsl:apply-imports>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>-->
  <!-- 2026-11-02 : dans les actes, <lb/> marque un alinéa de l'éditeur à l'intérieur d'un seul <p> (738 : début d'un
       vidimus, « Item » d'une énumération, reprise après l'acte cité). hteiml en fait un <br>, sur lequel le navigateur
       ignore toute marge : un span en bloc (CSS) coupe la ligne et met le blanc d'un paragraphe. -->
  

  <!-- 2026-11-05 (Maxime : « l'ancien site va être désactivé ») : anciens sites (*.enc.sorbonne.fr) fermés, plus aucun
       lien vers eux ; le texte reste. Les réécritures vers dots-vue de cette feuille (priorité plus forte) passent avant. -->
  <xsl:template match="tei:ref[matches(@target, '^https?://([a-z0-9-]+\.)*enc\.sorbonne\.fr')]
                       | tei:ptr[matches(@target, '^https?://([a-z0-9-]+\.)*enc\.sorbonne\.fr')]" mode="#all" version="3.0" priority="1">
    <xsl:choose>
      <xsl:when test="normalize-space(.) != '' or *"><xsl:apply-templates mode="#current"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="@target"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  <xsl:template match="tei:idno[matches(normalize-space(.), '^https?://([a-z0-9-]+\.)*enc\.sorbonne\.fr')]" mode="#all" version="3.0" priority="1">
    <span class="idno"><xsl:value-of select="normalize-space(.)"/></span>
  </xsl:template>

</xsl:transform>
