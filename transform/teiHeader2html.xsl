<?xml version="1.0" encoding="UTF-8"?>
<!-- Page de titre des Actes royaux du Poitou (route /api/dts/cover) : modèle commun page-de-titre.xsl.
     Écart : premier type d’éditeur seulement ; tous les respStmt ; date entière (« 2011-2015 »). -->
<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <xsl:import href="page-de-titre.xsl"/>

  <xsl:variable name="th-editeurs" select="($th-ts/tei:principal, $th-ts/tei:editor, $th-ts/tei:author)[1]"/>
  <xsl:variable name="th-edition-electronique" select="$th-ts/tei:respStmt/(tei:persName | tei:name)"/>
  <xsl:variable name="th-date" select="normalize-space((//tei:fileDesc/tei:publicationStmt/tei:date)[1])"/>
</xsl:transform>
