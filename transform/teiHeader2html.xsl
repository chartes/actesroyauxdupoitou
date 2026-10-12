<?xml version="1.0" encoding="UTF-8"?>
<!-- 2026-10-12. Page de titre de royaux_poitou,
     route /api/dts/cover?id=royaux_poitou. Base : modele Dubourg (transform/teiHeader2html.xsl).
     Ecarts au modele marques [actesroyauxdupoitou]. -->
<xsl:transform   version="1.1"   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:rng="http://relaxng.org/ns/structure/1.0"
  xmlns:eg="http://www.tei-c.org/ns/Examples"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:html="http://www.w3.org/1999/xhtml"
  xmlns:epub="http://www.idpf.org/2007/ops"
  exclude-result-prefixes="eg html rng tei epub"

  xmlns:exslt="http://exslt.org/common"
  extension-element-prefixes="exslt">

  <xsl:output encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="yes"/>

  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml" lang="fr">
      <div id="aside">to delete</div>
      <div id="center">
        <div id="main">
          <div id="article"><xsl:apply-templates select="//tei:fileDesc/tei:titleStmt"/></div>
        </div>
      </div>
    </html>
  </xsl:template>

  <xsl:template match="tei:titleStmt">
    <div class="titlestmt">
      <!-- [actesroyauxdupoitou] titre : le TEI ne porte qu'un titre (celui du Recueil imprime de Paul Guerin,
           titleStmt/title). Le site Corpus l'intitule « Actes royaux du Poitou (1302-1464) » : ce libelle n'existe
           dans aucun teiHeader, il n'est donc PAS ecrit ici. -->
      <h1 class="head">
        <xsl:value-of select="normalize-space((tei:title[not(@type)], tei:title)[1])"/>
      </h1>

      <!-- Édité par : [actesroyauxdupoitou] ecart : l'editeur de l'edition imprimee (Paul Guerin, « (éd.) »
           dans sourceDesc) est porte par titleStmt/author, et non par principal/editor. Le modele ne
           le lisait pas ; le garde.xsl du corpus le lit par repli. -->
      <xsl:if test="tei:principal or tei:editor or tei:author">
        <p class="editors">
          <span class="editors-label">Édité par </span>
          <xsl:for-each select="(tei:principal, tei:editor, tei:author)[1]">
            <span class="editor">
              <xsl:value-of select="normalize-space(.)"/>
            </span>
          </xsl:for-each>
        </p>
      </xsl:if>

      <!-- Édition électronique : [actesroyauxdupoitou] ecart : quatre respStmt, chacun un <name> + un <resp>
           (2011 encodage Vincent Jolivet, Joana Casenave, Laura Gilli ; 2013-2015 Mathilde Henriquet).
           On affiche les noms de tous les respStmt, sans le detail du role. -->
      <xsl:if test="tei:respStmt/(tei:persName | tei:name)">
        <p class="editors">
          <span class="editors-label">Édition électronique par </span>
          <xsl:for-each select="tei:respStmt/(tei:persName | tei:name)">
            <span class="editor">
              <xsl:value-of select="normalize-space(.)"/>
            </span>
            <xsl:choose>
              <xsl:when test="position() = last() - 1"> et </xsl:when>
              <xsl:when test="position() &lt; last()">, </xsl:when>
            </xsl:choose>
          </xsl:for-each>
        </p>
      </xsl:if>

      <!-- [actesroyauxdupoitou] date : publicationStmt/date[1] = « 2011-2015 » (from/to) : date de l'edition
           electronique, pas celle du Recueil (1881-1919, sourceDesc). Le modele lit la date du premier element,
           ce qui donne bien 2011-2015 ici. -->
      <span class="date">
        <xsl:value-of select="normalize-space(../tei:publicationStmt/tei:date[1])"/>
      </span>
    </div>
  </xsl:template>

</xsl:transform>
