<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="1.1"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="tei">

  <xsl:import href="../hteiml/xsl/tei2html.xsl"/>

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

  <!-- numero d'une note : @n si present, sinon auto par division-feuille -->
  <xsl:template name="actes-note-n">
    <xsl:choose>
      <xsl:when test="normalize-space(@n) != ''"><xsl:value-of select="@n"/></xsl:when>
      <xsl:otherwise>
        <xsl:number count="tei:note[@type = 'footnote' or not(@type)]" level="any"
          from="tei:text | tei:front/tei:div[@type = 'introduction']"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- appel de note (inline) -->
  <xsl:template match="tei:note[@type = 'footnote' or not(@type)]" priority="10">
    <a class="noteref" id="fn-{generate-id()}-ref" href="#fn-{generate-id()}"
       style="text-decoration:none;color:#a73136;font-weight:bold"><sup><xsl:call-template name="actes-note-n"/></sup></a>
  </xsl:template>

  <!-- deport des corps en pied de chaque acte / division d'introduction -->
  <xsl:template match="tei:group/tei:text | tei:front/tei:div[@type = 'introduction'] | tei:text[parent::*[local-name() = 'wrapper']] | tei:div[parent::*[local-name() = 'wrapper']]" priority="10">
    <xsl:apply-imports/>
    <xsl:variable name="notes" select=".//tei:note[@type = 'footnote' or not(@type)]"/>
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

</xsl:transform>
