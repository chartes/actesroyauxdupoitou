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

  <!-- ==== 2. BLOCS HTEIML GÉNÉRIQUES : enveloppe dts:wrapper, notes, apparat critique, bibliographie (listBibl) ==== -->
  <xsl:template name="footnotes"/>
  <xsl:template name="actes-note-n">
    <xsl:choose>
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
  <xsl:template match="tei:note[@type = 'footnote' or not(@type)]" priority="10">
    <xsl:variable name="n"><xsl:call-template name="actes-note-n"/></xsl:variable>
    <a class="noteref" id="fn-{generate-id()}-ref" href="#fn-{generate-id()}"
       title="{normalize-space(concat($n, ' ', .))}"><sup><xsl:value-of select="$n"/></sup></a>
  </xsl:template>
  <!-- 2026-10-30 : notes de leçon (note type="a", 32 : « Mot omis », « Sic. ») en apparat, appelées par une lettre,
       à part des notes historiques numérotées (comme dans les cartulaires et la CJC). -->
  <xsl:template name="actes-app-l">
    <xsl:number count="tei:note[@type = 'a']" level="any" from="tei:text | tei:front/tei:div[@type = 'introduction']" format="a"/>
  </xsl:template>
  <xsl:template match="tei:note[@type = 'a']" priority="10">
    <xsl:variable name="l"><xsl:call-template name="actes-app-l"/></xsl:variable>
    <a class="noteref app" id="app-{generate-id()}-ref" href="#app-{generate-id()}"
       title="{normalize-space(concat($l, '. ', .))}"><sup><xsl:value-of select="$l"/></sup></a>
  </xsl:template>
  <xsl:template name="actes-apparat-pied">
    <xsl:param name="apps"/>
    <section class="footnotes apparatus">
      <xsl:for-each select="$apps">
        <aside class="note app" id="app-{generate-id()}">
          <a class="noteback" href="#app-{generate-id()}-ref"><xsl:call-template name="actes-app-l"/><xsl:text>.</xsl:text></a>
          <xsl:text> </xsl:text>
          <xsl:apply-templates/>
        </aside>
      </xsl:for-each>
    </section>
  </xsl:template>
  <xsl:template match="tei:group/tei:text | tei:front/tei:div[@type = 'introduction'] | tei:div[parent::*[local-name() = 'wrapper']] | tei:text[parent::*[local-name() = 'wrapper']]" priority="10">
    <xsl:apply-imports/>
    <xsl:variable name="notes" select=".//tei:note[@type = 'footnote' or not(@type)]"/>
    <xsl:if test="$notes">
      <xsl:call-template name="actes-notes-pied">
        <xsl:with-param name="notes" select="$notes"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test=".//tei:note[@type = 'a']">
      <xsl:call-template name="actes-apparat-pied">
        <xsl:with-param name="apps" select=".//tei:note[@type = 'a']"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>
  <xsl:template match="tei:text[tei:group][parent::*[local-name() = 'wrapper']]" priority="25">
    <article class="text tome" id="{@xml:id}">
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
      <xsl:if test="../tei:body//tei:seg[@function]">
        <label class="arp-parties-choix"><input type="checkbox" class="arp-parties-cb"/> Montrer les parties de l’acte</label>
      </xsl:if>
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
  <!-- 2026-10-30 : parties du discours diplomatique (seg@function, 1 604). Infobulle toujours ; la case « Montrer les
       parties de l'acte », dans l'en-tête de l'acte, les signale dans le texte (CSS : :has). -->
  <xsl:template match="tei:seg[@function]" priority="20">
    <xsl:variable name="f" select="string(@function)"/>
    <xsl:variable name="nom">
      <xsl:choose>
        <xsl:when test="$f = 'intitulatio'">Suscription</xsl:when>
        <xsl:when test="$f = 'address'">Adresse</xsl:when>
        <xsl:when test="$f = 'salutatio'">Salut</xsl:when>
        <xsl:when test="$f = 'preamble'">Préambule</xsl:when>
        <xsl:when test="$f = 'notification'">Notification</xsl:when>
        <xsl:when test="$f = 'narratio'">Exposé</xsl:when>
        <xsl:when test="$f = 'dispositio'">Dispositif</xsl:when>
        <xsl:when test="$f = 'verb'">Verbe dispositif</xsl:when>
        <xsl:when test="$f = 'beneficiary'">Bénéficiaire</xsl:when>
        <xsl:when test="$f = 'donatio'">Donation</xsl:when>
        <xsl:when test="$f = 'clauses'">Clauses</xsl:when>
        <xsl:when test="$f = 'corroboration'">Corroboration</xsl:when>
        <xsl:when test="$f = 'dating'">Date</xsl:when>
        <xsl:when test="$f = 'esn'">Mentions hors teneur</xsl:when>
        <xsl:otherwise><xsl:value-of select="$f"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <span class="arp-partie arp-{$f}" data-partie="{$nom}" title="{$nom}"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="*[local-name() = 'x']" priority="20">
    <span class="x"><xsl:apply-templates/></span>
  </xsl:template>
  <xsl:template match="tei:licence/@target">
    <a class="licence" href="{.}">
      <xsl:choose>
        <xsl:when test="contains(., 'by-nc-nd/2.0/fr')">Licence Creative Commons BY-NC-ND 2.0 France</xsl:when>
        <xsl:otherwise>Licence</xsl:otherwise>
      </xsl:choose>
    </a>
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

  <!-- ==== 4. MÉCANISMES COMMUNS : tableau filtrable (tf-*), liens vers l'ancien site (D5), liens internes entre fragments ==== -->
  <xsl:template match="tei:idno[not(@type = 'URI' and ../tei:title)][normalize-space(.) = 'http://elec.enc.sorbonne.fr/actesroyauxdupoitou/']" priority="14">
    <a class="idno d5-local" href="/actesroyauxdupoitou"><xsl:apply-templates/></a>
  </xsl:template>
</xsl:transform>
