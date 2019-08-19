<?xml version="1.0" encoding="utf-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:edmx="http://docs.oasis-open.org/odata/ns/edmx" xmlns:edm="http://docs.oasis-open.org/odata/ns/edm" xmlns:json="http://json.org/">
  <!--
    This style sheet transforms OData 4.0 and 4.01 CSDL XML documents into JSON Schema Draft 07

    TODO:
    - Validation annotations -> pattern, minimum, maximum, exclusiveM??imum, see ODATA-856, inline and explace style
    - DefaultValue for Geo types: omit or convert to GeoJSON
    - align with JSON Schema Draft 07, especially wrt. $ref and $id
  -->

  <xsl:output method="text" indent="yes" encoding="UTF-8" omit-xml-declaration="yes" />
  <xsl:strip-space elements="*" />


  <xsl:variable name="edmUri" select="'https://oasis-tcs.github.io/odata-json-schema/tools/odata-meta-schema.json'" />
  <xsl:variable name="coreNamespace" select="'Org.OData.Core.V1'" />
  <xsl:variable name="coreAlias" select="//edmx:Include[@Namespace=$coreNamespace]/@Alias|//edm:Schema[@Namespace=$coreNamespace]/@Alias" />
  <xsl:variable name="coreDescription" select="concat('@',$coreNamespace,'.Description')" />
  <xsl:variable name="coreDescriptionAliased" select="concat('@',$coreAlias,'.Description')" />


  <xsl:key name="types" match="//edm:Property/@Type|//edm:NavigationProperty/@Type|//edm:ReturnType/@Type" use="." />


  <xsl:template match="edmx:Edmx">
    <xsl:text>{"$id":"</xsl:text>
    <xsl:choose>
      <xsl:when test="//edm:Schema[edm:EntityContainer]/@Namespace">
        <xsl:value-of select="//edm:Schema[edm:EntityContainer]/@Namespace" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="//edm:Schema/@Namespace" />
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>","$schema":"</xsl:text>
    <xsl:value-of select="$edmUri" />
    <xsl:text>#"</xsl:text>
    <xsl:apply-templates select="@*" mode="list2" />
    <xsl:apply-templates select="edmx:DataServices" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="edmx:Edmx/@Version">
    <xsl:text>"odata-version":"</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>"</xsl:text>
  </xsl:template>

  <xsl:template match="edmx:DataServices">
    <xsl:apply-templates select="edm:Schema/edm:EntityContainer" />
    <xsl:apply-templates select="edm:Schema/edm:EntityType|edm:Schema/edm:ComplexType|edm:Schema/edm:TypeDefinition|edm:Schema/edm:EnumType" mode="hash">
      <xsl:with-param name="name" select="'definitions'" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="edm:EnumType" mode="hashpair">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="../@Namespace" />
    <xsl:text>.</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>":{</xsl:text>
    <xsl:if test="@IsFlags='true'">
      <xsl:text>"anyOf":[{</xsl:text>
    </xsl:if>
    <xsl:text>"type":"string","enum":[</xsl:text>
    <xsl:apply-templates select="edm:Member" mode="list" />
    <xsl:text>]</xsl:text>
    <xsl:if test="@IsFlags='true'">
      <xsl:text>},{"type":"string","pattern":"^</xsl:text>
      <xsl:variable name="pattern">
        <xsl:apply-templates select="edm:Member" mode="pattern" />
        <xsl:text>|[1-9][0-9]*</xsl:text>
      </xsl:variable>
      <xsl:text>(</xsl:text>
      <xsl:value-of select="$pattern" />
      <xsl:text>)(,(</xsl:text>
      <xsl:value-of select="$pattern" />
      <xsl:text>))*</xsl:text>
      <xsl:text>$"}]</xsl:text>
    </xsl:if>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="edm:Member" mode="list">
    <xsl:if test="position() > 1">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:text>"</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>"</xsl:text>
  </xsl:template>

  <xsl:template match="edm:Member" mode="pattern">
    <xsl:if test="position() > 1">
      <xsl:text>|</xsl:text>
    </xsl:if>
    <xsl:value-of select="@Name" />
  </xsl:template>

  <xsl:template match="edm:TypeDefinition" mode="hashpair">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="../@Namespace" />
    <xsl:text>.</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>":{</xsl:text>
    <xsl:call-template name="type">
      <xsl:with-param name="type" select="@UnderlyingType" />
      <xsl:with-param name="nullableFacet" select="'false'" />
    </xsl:call-template>
    <xsl:apply-templates select="node()" mode="list2" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="edm:EntityType|edm:ComplexType" mode="hashpair">
    <xsl:text>"</xsl:text>
    <xsl:value-of select="../@Namespace" />
    <xsl:text>.</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>":{"type":"object"</xsl:text>
    <xsl:if test="@BaseType">
      <xsl:text>,"allOf":[{</xsl:text>
      <xsl:call-template name="schema-ref">
        <xsl:with-param name="qualifiedName" select="@BaseType" />
        <xsl:with-param name="element" select="'definitions'" />
      </xsl:call-template>
      <xsl:text>}]</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="edm:Property|edm:NavigationProperty" mode="hash">
      <xsl:with-param name="name" select="'properties'" />
    </xsl:apply-templates>
    <xsl:apply-templates select="edm:Annotation" mode="list2" />
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="edm:Property|edm:NavigationProperty" mode="hashvalue">
    <xsl:call-template name="type">
      <xsl:with-param name="type" select="@Type" />
      <xsl:with-param name="nullableFacet" select="@Nullable" />
      <xsl:with-param name="wrap" select="local-name()='NavigationProperty'" />
    </xsl:call-template>
    <xsl:apply-templates select="edm:Annotation" mode="list2" />
  </xsl:template>

  <xsl:template name="nullableFacetValue">
    <xsl:param name="type" />
    <xsl:param name="nullableFacet" />
    <xsl:choose>
      <xsl:when test="$nullableFacet">
        <xsl:value-of select="$nullableFacet" />
      </xsl:when>
      <xsl:when test="starts-with($type,'Collection(')">
        <xsl:value-of select="'false'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'true'" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="type">
    <xsl:param name="type" />
    <xsl:param name="nullableFacet" />
    <xsl:param name="wrap" select="false" />
    <xsl:variable name="nullable">
      <xsl:call-template name="nullableFacetValue">
        <xsl:with-param name="type" select="$type" />
        <xsl:with-param name="nullableFacet" select="$nullableFacet" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="singleType">
      <xsl:choose>
        <xsl:when test="starts-with($type,'Collection(')">
          <xsl:value-of select="substring-before(substring-after($type,'('),')')" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$type" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="qualifier">
      <xsl:call-template name="substring-before-last">
        <xsl:with-param name="input" select="$singleType" />
        <xsl:with-param name="marker" select="'.'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="collection" select="starts-with($type,'Collection(')" />
    <xsl:variable name="anyOf" select="not($nullable='false') or (not($collection) and ($wrap or @DefaultValue or @MaxLength))" />
    <xsl:if test="$collection">
      <xsl:text>"type":"array","items":{</xsl:text>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$singleType='Edm.Stream'">
        <xsl:call-template name="Edm.Stream" />
      </xsl:when>
      <xsl:when test="$singleType='Edm.String'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:apply-templates select="@MaxLength" />
      </xsl:when>
      <xsl:when test="$singleType='Edm.Binary'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"base64url"</xsl:text>
        <xsl:apply-templates select="@MaxLength">
          <xsl:with-param name="byteLength" select="'yes'" />
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Boolean'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'boolean'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Decimal'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'number,string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"decimal"</xsl:text>
        <xsl:choose>
          <xsl:when test="not(@Scale) or @Scale='0'">
            <xsl:text>,"multipleOf":1</xsl:text>
          </xsl:when>
          <!-- Note: Variable is invalid but used by Dynamics CRM -->
          <xsl:when test="@Scale!='Variable' and @Scale!='variable' and @Scale!='floating'">
            <xsl:text>,"multipleOf":1e-</xsl:text>
            <xsl:value-of select="@Scale" />
          </xsl:when>
        </xsl:choose>
        <xsl:if test="@Precision">
          <xsl:variable name="scale">
            <xsl:choose>
              <xsl:when test="not(@Scale)">
                <xsl:value-of select="0" />
              </xsl:when>
              <xsl:when test="@Scale='variable' or @Scale='floating'">
                <xsl:value-of select="0" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@Scale" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="limit">
            <xsl:call-template name="repeat">
              <xsl:with-param name="string" select="'9'" />
              <xsl:with-param name="count" select="@Precision - $scale" />
            </xsl:call-template>
            <xsl:if test="$scale > 0">
              <xsl:text>.</xsl:text>
              <xsl:call-template name="repeat">
                <xsl:with-param name="string" select="'9'" />
                <xsl:with-param name="count" select="$scale" />
              </xsl:call-template>
            </xsl:if>
          </xsl:variable>
          <xsl:text>,"minimum":-</xsl:text>
          <xsl:value-of select="$limit" />
          <xsl:text>,"maximum":</xsl:text>
          <xsl:value-of select="$limit" />
        </xsl:if>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Byte'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'integer'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"uint8"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.SByte'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'integer'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"int8"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Int16'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'integer'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"int16"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Int32'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'integer'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"int32"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Int64'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'integer,string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"int64"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Date'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"date"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Double'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'number,string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"double"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Single'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'number,string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:call-template name="single-format" />
      </xsl:when>
      <xsl:when test="$singleType='Edm.Guid'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"uuid"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.DateTimeOffset'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"date-time"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.TimeOfDay'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"partial-time"</xsl:text>
      </xsl:when>
      <xsl:when test="$singleType='Edm.Duration'">
        <xsl:call-template name="nullableType">
          <xsl:with-param name="type" select="'string'" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:text>,"format":"duration"</xsl:text>
      </xsl:when>
      <xsl:when test="$qualifier='Edm'">
        <xsl:call-template name="Edm.Geo">
          <xsl:with-param name="anyOf" select="$anyOf" />
          <xsl:with-param name="singleType" select="$singleType" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="otherType">
          <xsl:with-param name="anyOf" select="$anyOf" />
          <xsl:with-param name="qualifier" select="$qualifier" />
          <xsl:with-param name="singleType" select="$singleType" />
          <xsl:with-param name="nullable" select="$nullable" />
        </xsl:call-template>
        <xsl:apply-templates select="@MaxLength" />
      </xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates select="@DefaultValue">
      <xsl:with-param name="type" select="$singleType" />
    </xsl:apply-templates>
    <xsl:if test="$collection">
      <xsl:text>}</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="single-format">
    <xsl:text>,"format":"single"</xsl:text>
  </xsl:template>

  <xsl:template name="Edm.Stream">
    <xsl:text>"$ref":"</xsl:text>
    <xsl:value-of select="$edmUri" />
    <xsl:text>#/definitions/Edm.Stream"</xsl:text>
  </xsl:template>

  <xsl:template name="Edm.Geo">
    <xsl:param name="anyOf" />
    <xsl:param name="singleType" />
    <xsl:param name="nullable" />
    <xsl:if test="$anyOf">
      <xsl:text>"anyOf":[{</xsl:text>
    </xsl:if>
    <xsl:text>"$ref":"</xsl:text>
    <xsl:value-of select="$edmUri" />
    <xsl:text>#/definitions/</xsl:text>
    <xsl:value-of select="$singleType" />
    <xsl:text>"</xsl:text>
    <xsl:if test="not($nullable='false')">
      <xsl:text>},{"type":"null"</xsl:text>
    </xsl:if>
    <xsl:if test="$anyOf">
      <xsl:text>}]</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="otherType">
    <xsl:param name="anyOf" />
    <xsl:param name="qualifier" />
    <xsl:param name="singleType" />
    <xsl:param name="nullable" />
    <xsl:if test="$anyOf">
      <xsl:text>"anyOf":[{</xsl:text>
    </xsl:if>
    <xsl:call-template name="ref">
      <xsl:with-param name="qualifier" select="$qualifier" />
      <xsl:with-param name="name">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="input" select="$singleType" />
          <xsl:with-param name="marker" select="'.'" />
        </xsl:call-template>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:if test="not($nullable='false')">
      <xsl:text>},{"type":"null"</xsl:text>
    </xsl:if>
    <xsl:if test="$anyOf">
      <xsl:text>}]</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="ref">
    <xsl:param name="qualifier" />
    <xsl:param name="name" />
    <xsl:param name="element" select="'definitions'" />
    <xsl:variable name="internalNamespace" select="//edm:Schema[@Alias=$qualifier]/@Namespace" />
    <xsl:variable name="externalNamespace">
      <xsl:choose>
        <xsl:when test="//edmx:Include[@Alias=$qualifier]/@Namespace">
          <xsl:value-of select="//edmx:Include[@Alias=$qualifier]/@Namespace" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="//edmx:Include[@Namespace=$qualifier]/@Namespace" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:text>"$ref":"</xsl:text>
    <xsl:call-template name="json-url">
      <xsl:with-param name="url" select="//edmx:Include[@Namespace=$externalNamespace]/../@Uri" />
    </xsl:call-template>
    <xsl:text>#/</xsl:text>
    <xsl:value-of select="$element" />
    <xsl:if test="$element!='entityContainer'">
      <xsl:text>/</xsl:text>
      <xsl:choose>
        <xsl:when test="$internalNamespace">
          <xsl:value-of select="$internalNamespace" />
        </xsl:when>
        <xsl:when test="string-length($externalNamespace)>0">
          <xsl:value-of select="$externalNamespace" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$qualifier" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="$name" />
    </xsl:if>
    <xsl:text>"</xsl:text>
  </xsl:template>

  <xsl:template name="schema-ref">
    <xsl:param name="qualifiedName" />
    <xsl:param name="element" />
    <xsl:call-template name="ref">
      <xsl:with-param name="qualifier">
        <xsl:call-template name="substring-before-last">
          <xsl:with-param name="input" select="$qualifiedName" />
          <xsl:with-param name="marker" select="'.'" />
        </xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="name">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="input" select="$qualifiedName" />
          <xsl:with-param name="marker" select="'.'" />
        </xsl:call-template>
      </xsl:with-param>
      <xsl:with-param name="element" select="$element" />
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="repeat">
    <xsl:param name="string" />
    <xsl:param name="count" />
    <xsl:value-of select="$string" />
    <xsl:if test="$count &gt; 1">
      <xsl:call-template name="repeat">
        <xsl:with-param name="string" select="$string" />
        <xsl:with-param name="count" select="$count - 1" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="nullableType">
    <xsl:param name="type" />
    <xsl:param name="nullable" />
    <xsl:text>"type":</xsl:text>
    <xsl:if test="not($nullable='false') or contains($type,',')">
      <xsl:text>[</xsl:text>
    </xsl:if>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="replace-all">
      <xsl:with-param name="string" select="$type" />
      <xsl:with-param name="old" select="','" />
      <xsl:with-param name="new" select="'&quot;,&quot;'" />
    </xsl:call-template>
    <xsl:text>"</xsl:text>
    <xsl:if test="not($nullable='false')">
      <xsl:text>,"null"</xsl:text>
    </xsl:if>
    <xsl:if test="not($nullable='false') or contains($type,',')">
      <xsl:text>]</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="@MaxLength">
    <xsl:param name="byteLength" />
    <xsl:if test=".!='max'">
      <xsl:text>,"maxLength":</xsl:text>
      <xsl:if test="$byteLength">
        <xsl:value-of select="4*ceiling(. div 3)" />
        <xsl:text>,"byteLength":</xsl:text>
      </xsl:if>
      <xsl:value-of select="." />
    </xsl:if>
  </xsl:template>

  <xsl:template match="@DefaultValue">
    <xsl:param name="type" />
    <xsl:text>,"default":</xsl:text>
    <xsl:variable name="qualifier">
      <xsl:call-template name="substring-before-last">
        <xsl:with-param name="input" select="$type" />
        <xsl:with-param name="marker" select="'.'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="typeName">
      <xsl:call-template name="substring-after-last">
        <xsl:with-param name="input" select="$type" />
        <xsl:with-param name="marker" select="'.'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="underlyingType">
      <xsl:choose>
        <xsl:when test="//edm:Schema[@Namespace=$qualifier]/edm:TypeDefinition[@Name=$typeName]/@UnderlyingType">
          <xsl:value-of select="//edm:Schema[@Namespace=$qualifier]/edm:TypeDefinition[@Name=$typeName]/@UnderlyingType" />
        </xsl:when>
        <xsl:when test="//edm:Schema[@Alias=$qualifier]/edm:TypeDefinition[@Name=$typeName]/@UnderlyingType">
          <xsl:value-of select="//edm:Schema[@Alias=$qualifier]/edm:TypeDefinition[@Name=$typeName]/@UnderlyingType" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$type" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="underlyingQualifier">
      <xsl:call-template name="substring-before-last">
        <xsl:with-param name="input" select="$underlyingType" />
        <xsl:with-param name="marker" select="'.'" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test=".='-INF' or .='INF' or .='NaN'">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>"</xsl:text>
      </xsl:when>
      <xsl:when test="$underlyingType='Edm.Boolean' or $underlyingType='Edm.Decimal' or $underlyingType='Edm.Double' or $underlyingType='Edm.Single' or $underlyingType='Edm.Byte' or $underlyingType='Edm.SByte' or $underlyingType='Edm.Int16' or $underlyingType='Edm.Int32' or $underlyingType='Edm.Int64'">
        <xsl:value-of select="." />
      </xsl:when>
      <!-- FAKE: couldn't determine underlying primitive type, so guess from value -->
      <xsl:when test="$underlyingQualifier!='Edm' and (.='true' or .='false' or .='null' or number(.))">
        <xsl:value-of select="." />
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>"</xsl:text>
        <xsl:call-template name="escape">
          <xsl:with-param name="string" select="." />
        </xsl:call-template>
        <xsl:text>"</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="edm:EntityContainer">
    <xsl:text>,"anyOf":[</xsl:text>
    <xsl:apply-templates select="edm:EntitySet|edm:Singleton" mode="list" />
    <!--
      <xsl:apply-templates
      select="edm:EntitySet|edm:Singleton|//edm:NavigationProperty/@Type[generate-id()=generate-id(key('types',.)[1])]" mode="list"
      />
    -->
    <xsl:text>]</xsl:text>
  </xsl:template>

  <xsl:template match="edm:NavigationProperty/@Type">
    <xsl:choose>
      <xsl:when test="starts-with(.,'Collection(')">
        <xsl:variable name="type" select="substring-before(substring-after(.,'('),')')" />
        <xsl:text>{"description":"Collection of </xsl:text>
        <xsl:value-of select="$type" />
        <xsl:text>","type":"object","properties":{"@odata.context":{"type":"string","pattern":"\\$metadata#</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>([/(].*)?$"},"value":{"type":"array","items":{</xsl:text>
        <xsl:call-template name="type">
          <xsl:with-param name="type" select="$type" />
          <xsl:with-param name="nullableFacet" select="'false'" />
        </xsl:call-template>
        <xsl:text>}}}}</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>{"description":"Single instance of </xsl:text>
        <xsl:value-of select="." />
        <xsl:text>","type":"object","properties":{"@odata.context":{"type":"string","pattern":"\\$metadata#</xsl:text>
        <xsl:value-of select="." />
        <xsl:text>([/(].*)?$"}},"allOf":[{</xsl:text>
        <xsl:call-template name="type">
          <xsl:with-param name="type" select="." />
          <xsl:with-param name="nullableFacet" select="'false'" />
        </xsl:call-template>
        <xsl:text>}]}</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- TODO: edm:ReturnType, edm:Property -->
  <xsl:template match="@Type">
    <xsl:message>
      <xsl:value-of select="." />
    </xsl:message>
  </xsl:template>

  <xsl:template match="edm:EntitySet">
    <xsl:text>{"description":"</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>: single entity","type":"object","properties":{"@odata.context":{"type":"string","pattern":"\\$metadata#</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>([/(][^\\$]*)?/\\$entity$"}},"allOf":[{</xsl:text>
    <xsl:call-template name="type">
      <xsl:with-param name="type" select="@EntityType" />
      <xsl:with-param name="nullableFacet" select="'false'" />
    </xsl:call-template>
    <xsl:text>}]}</xsl:text>

    <xsl:text>,{"description":"</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>: collection of entities","type":"object","required":["value"],"properties":{"@odata.context":{"type":"string","pattern":"\\$metadata#</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>([/(][^\\$]*)?$"},"value":{"type":"array","items":{</xsl:text>
    <xsl:call-template name="type">
      <xsl:with-param name="type" select="@EntityType" />
      <xsl:with-param name="nullableFacet" select="'false'" />
    </xsl:call-template>
    <xsl:text>}}}}</xsl:text>
  </xsl:template>

  <xsl:template match="edm:Singleton">
    <xsl:text>{"description":"</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>: singleton","type":"object","properties":{"@odata.context":{"type":"string","pattern":"\\$metadata#</xsl:text>
    <xsl:value-of select="@Name" />
    <xsl:text>([/(].*)?$"}},"allOf":[{</xsl:text>
    <xsl:call-template name="type">
      <xsl:with-param name="type" select="@Type" />
      <xsl:with-param name="nullableFacet" select="'false'" />
    </xsl:call-template>
    <xsl:text>}]}</xsl:text>
  </xsl:template>

  <xsl:template match="edm:Annotation">
    <xsl:param name="target" />
    <xsl:param name="qualifier" />
    <xsl:variable name="name">
      <xsl:value-of select="$target" />
      <xsl:text>@</xsl:text>
      <xsl:value-of select="@Term" />
      <xsl:if test="@Qualifier or $qualifier">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="@Qualifier" />
        <xsl:value-of select="$qualifier" />
      </xsl:if>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="($name=$coreDescription or $name=$coreDescriptionAliased) and (@String or edm:String)">
        <xsl:text>"description":</xsl:text>
        <xsl:apply-templates select="@String|edm:String" />
      </xsl:when>
      <xsl:otherwise />
    </xsl:choose>
  </xsl:template>

  <!-- escaped string value -->
  <xsl:template match="@String|edm:String">
    <xsl:text>"</xsl:text>
    <xsl:call-template name="escape">
      <xsl:with-param name="string" select="." />
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>

  <xsl:template name="escape">
    <xsl:param name="string" />
    <xsl:choose>
      <xsl:when test="contains($string,'&quot;')">
        <xsl:call-template name="replace">
          <xsl:with-param name="string" select="$string" />
          <xsl:with-param name="old" select="'&quot;'" />
          <xsl:with-param name="new" select="'\&quot;'" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($string,'\')">
        <xsl:call-template name="replace">
          <xsl:with-param name="string" select="$string" />
          <xsl:with-param name="old" select="'\'" />
          <xsl:with-param name="new" select="'\\'" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($string,'&#x0A;')">
        <xsl:call-template name="replace">
          <xsl:with-param name="string" select="$string" />
          <xsl:with-param name="old" select="'&#x0A;'" />
          <xsl:with-param name="new" select="'\n'" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($string,'&#x0D;')">
        <xsl:call-template name="replace">
          <xsl:with-param name="string" select="$string" />
          <xsl:with-param name="old" select="'&#x0D;'" />
          <xsl:with-param name="new" select="'\r'" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="contains($string,'&#x09;')">
        <xsl:call-template name="replace">
          <xsl:with-param name="string" select="$string" />
          <xsl:with-param name="old" select="'&#x09;'" />
          <xsl:with-param name="new" select="'\t'" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="replace">
    <xsl:param name="string" />
    <xsl:param name="old" />
    <xsl:param name="new" />
    <xsl:call-template name="escape">
      <xsl:with-param name="string" select="substring-before($string,$old)" />
    </xsl:call-template>
    <xsl:value-of select="$new" />
    <xsl:call-template name="escape">
      <xsl:with-param name="string" select="substring-after($string,$old)" />
    </xsl:call-template>
  </xsl:template>


  <!-- name : object -->
  <xsl:template match="@*|*" mode="object">
    <xsl:param name="name" />
    <xsl:param name="after" select="'something'" />
    <xsl:if test="position()=1">
      <xsl:if test="$after">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>"</xsl:text>
      <xsl:value-of select="$name" />
      <xsl:text>":{</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." />
    <xsl:if test="position()!=last()">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:if test="position()=last()">
      <xsl:text>}</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- name : hash -->
  <xsl:template match="*" mode="hash">
    <xsl:param name="name" />
    <xsl:param name="key" select="'Name'" />
    <xsl:param name="after" select="'something'" />
    <xsl:param name="constantProperties" />
    <xsl:if test="position()=1">
      <xsl:if test="$after">
        <xsl:text>,</xsl:text>
      </xsl:if>
      <xsl:text>"</xsl:text>
      <xsl:value-of select="$name" />
      <xsl:text>":{</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="." mode="hashpair">
      <xsl:with-param name="name" select="$name" />
      <xsl:with-param name="key" select="$key" />
    </xsl:apply-templates>
    <xsl:if test="position()!=last()">
      <xsl:text>,</xsl:text>
    </xsl:if>
    <xsl:if test="position()=last()">
      <xsl:value-of select="$constantProperties" />
      <xsl:text>}</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*" mode="hashpair">
    <xsl:param name="name" />
    <xsl:param name="key" select="'Name'" />
    <xsl:text>"</xsl:text>
    <xsl:value-of select="@*[local-name()=$key]" />
    <xsl:text>":{</xsl:text>
    <xsl:apply-templates select="." mode="hashvalue">
      <xsl:with-param name="name" select="$name" />
      <xsl:with-param name="key" select="$key" />
    </xsl:apply-templates>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="*" mode="hashvalue">
    <xsl:param name="key" select="'Name'" />
    <xsl:apply-templates select="@*[local-name()!=$key]|node()" mode="list" />
  </xsl:template>

  <!-- comma-separated list -->
  <xsl:template match="@*|*" mode="list">
    <xsl:param name="target" />
    <xsl:param name="qualifier" />
    <xsl:param name="after" />
    <xsl:choose>
      <xsl:when test="position() > 1">
        <xsl:text>,</xsl:text>
      </xsl:when>
      <xsl:when test="$after">
        <xsl:text>,</xsl:text>
      </xsl:when>
    </xsl:choose>
    <xsl:apply-templates select=".">
      <xsl:with-param name="target" select="$target" />
      <xsl:with-param name="qualifier" select="$qualifier" />
    </xsl:apply-templates>
  </xsl:template>

  <!-- continuation of comma-separated list -->
  <xsl:template match="@*|*" mode="list2">
    <xsl:param name="target" />
    <xsl:param name="qualifier" />
    <xsl:variable name="content">
      <xsl:apply-templates select=".">
        <xsl:with-param name="target" select="$target" />
        <xsl:with-param name="qualifier" select="$qualifier" />
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:if test="string-length($content)>0">
      <xsl:text>,</xsl:text>
      <xsl:value-of select="$content" />
    </xsl:if>
  </xsl:template>

  <!-- leftover text -->
  <xsl:template match="text()">
    <xsl:message>
      <xsl:text>leftover text()</xsl:text>
    </xsl:message>
    <xsl:text>"TODO:text()":"</xsl:text>
    <xsl:value-of select="." />
    <xsl:text>"</xsl:text>
  </xsl:template>

  <!-- leftover attributes -->
  <xsl:template match="@*">
  </xsl:template>

  <!-- helper functions -->
  <xsl:template name="substring-before-last">
    <xsl:param name="input" />
    <xsl:param name="marker" />
    <xsl:if test="contains($input,$marker)">
      <xsl:value-of select="substring-before($input,$marker)" />
      <xsl:if test="contains(substring-after($input,$marker),$marker)">
        <xsl:value-of select="$marker" />
        <xsl:call-template name="substring-before-last">
          <xsl:with-param name="input" select="substring-after($input,$marker)" />
          <xsl:with-param name="marker" select="$marker" />
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template name="substring-after-last">
    <xsl:param name="input" />
    <xsl:param name="marker" />
    <xsl:choose>
      <xsl:when test="contains($input,$marker)">
        <xsl:call-template name="substring-after-last">
          <xsl:with-param name="input" select="substring-after($input,$marker)" />
          <xsl:with-param name="marker" select="$marker" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$input" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="replace-all">
    <xsl:param name="string" />
    <xsl:param name="old" />
    <xsl:param name="new" />
    <xsl:choose>
      <xsl:when test="contains($string,$old)">
        <xsl:value-of select="substring-before($string,$old)" />
        <xsl:value-of select="$new" />
        <xsl:call-template name="replace-all">
          <xsl:with-param name="string" select="substring-after($string,$old)" />
          <xsl:with-param name="old" select="$old" />
          <xsl:with-param name="new" select="$new" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$string" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="json-url">
    <xsl:param name="url" />
    <xsl:choose>
      <xsl:when test="substring($url,string-length($url)-3) = '.xml'">
        <xsl:choose>
          <xsl:when test="substring($url,0,34) = 'http://docs.oasis-open.org/odata/'">
            <xsl:text>https://tools.oasis-open.org/version-control/browse/wsvn/odata/trunk/spec/vocabularies/</xsl:text>
            <xsl:variable name="filename">
              <xsl:call-template name="substring-after-last">
                <xsl:with-param name="input" select="$url" />
                <xsl:with-param name="marker" select="'/'" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:value-of select="substring($filename,0,string-length($filename)-3)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="substring($url,0,string-length($url)-3)" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="'.json'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$url" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>