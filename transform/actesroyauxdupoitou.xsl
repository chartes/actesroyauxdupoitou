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
  <!-- Pied de notes de hteiml (notes par page), avec en tête le bloc d'apparat des note type="a" : hteiml n'y met que
       les tei:app. Même rendu que l'apparat des Édits. -->
  <xsl:template name="footnotes">
    <xsl:param name="cont" select="*"/>
    <xsl:param name="pb" select="$cont//tei:pb[@n][not(@ed)]"/>
    <xsl:variable name="apparat" select="$cont//tei:note[@type = 'a']"/>
    <xsl:variable name="notes">
      <xsl:if test="$apparat">
        <p class="apparatus">
          <xsl:for-each select="$apparat">
            <span class="note">
              <xsl:attribute name="id"><xsl:call-template name="id"/></xsl:attribute>
              <xsl:call-template name="noteback">
                <xsl:with-param name="class"/>
              </xsl:call-template>
              <xsl:text>&#160;</xsl:text>
              <xsl:apply-templates/>
            </span>
          </xsl:for-each>
        </p>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$pb">
          <xsl:variable name="avant" select="key('note-pb', '')[not(@type = 'a')]"/>
          <xsl:if test="$avant">
            <div class="page">
              <xsl:for-each select="$avant"><xsl:call-template name="note"/></xsl:for-each>
            </div>
          </xsl:if>
          <xsl:for-each select="$pb">
            <xsl:variable name="page" select="key('note-pb', generate-id())[not(@type = 'a')]"/>
            <xsl:if test="$page">
              <div class="page">
                <div class="b note-page"><xsl:call-template name="a"/></div>
                <xsl:for-each select="$page"><xsl:call-template name="note"/></xsl:for-each>
              </div>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="$cont//tei:note[not(@type = 'a')]"><xsl:call-template name="note"/></xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$notes != ''">
      <section class="footnotes"><xsl:copy-of select="$notes"/></section>
    </xsl:if>
  </xsl:template>
  
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
