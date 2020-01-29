<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:p="https://id.acdh.oeaw.ac.at/patternmatcher"
    exclude-result-prefixes="#all"
    version="2.0">
    
    
    <xsl:function name="p:find-regex-group-references" as="xs:integer*">
        <xsl:param name="pattern" as="element(p:pattern)"/>
        <xsl:variable name="regex-groups" as="xs:integer*">
            <xsl:apply-templates select="$pattern" mode="find-regex-group-reference"/>
        </xsl:variable>
        <xsl:sequence select="distinct-values($regex-groups)"/>
    </xsl:function>
    
    
    
    <xsl:template match="node() | @*" mode="find-regex-group-reference">
        <xsl:apply-templates select="node() | @*" mode="find-regex-group-reference"/>
    </xsl:template>
    
    <xsl:template match="@*[matches(.,'group:\d+')]|text()[matches(.,'group:\d+')]" mode="find-regex-group-reference">
        <xsl:analyze-string select="." regex="group:(\d+)">
            <xsl:matching-substring>
                <xsl:sequence select="xs:integer(regex-group(1))"/>
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <xsl:function name="p:pad-integer-to-length">
        <xsl:param name="value"/>
        <xsl:param name="args" as="element(p:arg)*"/>
        <xsl:value-of select="format-number($value, string-join(for $i in 1 to $args return '0'))"/>
    </xsl:function>
    
    <xsl:template name="transform-value">
        <xsl:param name="value"/>
        <xsl:param name="transforms" as="element(p:transform)*"/>
        <xsl:variable name="pattern-name" select="$transforms/ancestor::p:pattern/@name"/>
        <xsl:choose>
            <xsl:when test="count($transforms) eq 0">
                <xsl:value-of select="$value"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="t" select="$transforms[1]"/>
                <xsl:variable name="function" select="$t/@function"/>
                <xsl:variable name="args" select="$t/p:arg"/>
                <xsl:call-template name="transform-value">
                    <xsl:with-param name="value">
                        <xsl:choose>
                            <xsl:when test="$function = 'pad-integer-to-length'">
                                <xsl:value-of select="p:pad-integer-to-length($value, $args)"/>
                            </xsl:when>
                            <xsl:when test="$function = 'upper-case'">
                                <xsl:value-of select="upper-case($value)"/>
                            </xsl:when>
                            <xsl:when test="$function = 'lower-case'">
                                <xsl:value-of select="lower-case($value)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>unknown function '<xsl:value-of select="$function"/>' in pattern '<xsl:value-of select="$pattern-name"/>' </xsl:message>
                                <xsl:value-of select="$value"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:with-param>
                    <xsl:with-param name="transforms" select="subsequence($transforms,2)"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    
    <xsl:template match="node() | @*" mode="populate-pattern">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="p:pattern/text()" mode="populate-pattern"/>
    <xsl:template match="p:pattern" mode="populate-pattern">
        <xsl:apply-templates select="p:out/node()" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="text()[matches(.,'\$match')]" mode="populate-pattern">
        <xsl:param name="match" tunnel="yes"/>
        <xsl:param name="pattern" tunnel="yes"/>
        <xsl:variable name="value-out">
            <xsl:call-template name="transform-value">
                <xsl:with-param name="value" select="$match"/>
                <xsl:with-param name="transforms" select="$pattern/p:match/p:transform"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:value-of select="replace(., '\$match', $value-out)"/>
    </xsl:template>
    
    
    <xsl:template match="@*[matches(.,'group:\d+')]" mode="populate-pattern">
        <xsl:param name="pattern" as="element(p:pattern)*" tunnel="yes"/>
        <xsl:param name="regex-group-values" as="element(p:regex-group)*" tunnel="yes"/>
        <xsl:attribute name="{name(.)}">
            <xsl:analyze-string select="." regex="group:(\d+)">
                <xsl:matching-substring>
                    <xsl:variable name="group-num" select="regex-group(1)"/>
                    <xsl:variable name="group-config" select="$pattern/p:group[@n = $group-num]" as="element()?"/>
                    <xsl:variable name="group-value-in" select="$regex-group-values[@n = $group-num]/node()"/>
                    <xsl:variable name="group-value-out">
                        <xsl:call-template name="transform-value">
                            <xsl:with-param name="value" select="$group-value-in"/>
                            <xsl:with-param name="transforms" select="$group-config/p:transform" as="item()*"/>
                        </xsl:call-template>
                    </xsl:variable>
                    <xsl:sequence select="$group-value-out"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:value-of select="."/>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="text()[matches(.,'group:\d+')]" mode="populate-pattern">
        <xsl:param name="pattern" as="element(p:pattern)*" tunnel="yes"/>
        <xsl:param name="regex-group-values" as="element(p:regex-group)*" tunnel="yes"/>
        <xsl:analyze-string select="." regex="group:(\d+)">
            <xsl:matching-substring>
                <xsl:variable name="group-num" select="regex-group(1)"/>
                <xsl:variable name="group-config" select="$pattern/p:group[@n = $group-num]" as="element()?"/>
                <xsl:variable name="group-value-in" select="$regex-group-values[@n = $group-num]/node()"/>
                <xsl:variable name="group-value-out">
                    <xsl:call-template name="transform-value">
                        <xsl:with-param name="value" select="$group-value-in"/>
                        <xsl:with-param name="transforms" select="$group-config/p:transform" as="item()*"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:sequence select="$group-value-out"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
                <xsl:value-of select="."/>
            </xsl:non-matching-substring>
        </xsl:analyze-string>
    </xsl:template>
    
    <xsl:function name="p:find-matching-pattern" as="element(p:pattern)*">
        <xsl:param name="substring" as="xs:string"/>
        <xsl:param name="patterns"/>
        <xsl:for-each select="$patterns/p:pattern[matches($substring,@match)]">
            <xsl:sort select="string-length(@match)" order="descending"/>
            <xsl:sequence select="."/>
        </xsl:for-each>
    </xsl:function>
    
    <xsl:template match="node() except text() | @*" mode="#default">
        <xsl:copy>
            <xsl:apply-templates select="node() | @*" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="text()" mode="#default">
        <xsl:param name="patternmatcher.patterns" tunnel="yes"/>
        <xsl:variable name="collapsed-patterns" select="concat('(',string-join($patternmatcher.patterns//p:pattern/@match,'|'),')')"/>
        <xsl:choose>
            <xsl:when test="matches(., $collapsed-patterns)">
                <xsl:analyze-string select="." regex="{$collapsed-patterns}">
                    <xsl:matching-substring>
                        <xsl:variable name="matching-substring" select="."/>
                        <xsl:variable name="matching-patterns" select="p:find-matching-pattern($matching-substring, $patternmatcher.patterns)" as="element(p:pattern)+"/>
                        <xsl:call-template name="apply-pattern">
                            <xsl:with-param name="node" select="."/>
                            <xsl:with-param name="pattern" select="$matching-patterns[1]"/>
                        </xsl:call-template>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:value-of select="."/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="apply-pattern">
        <xsl:param name="node"/>
        <xsl:param name="pattern" as="element(p:pattern)"/>
        <xsl:variable name="regex-groups-in-pattern" select="p:find-regex-group-references($pattern)" as="xs:integer*"/>
        <xsl:analyze-string select="$node" regex="{$pattern/@match}">
            <xsl:matching-substring>
                <xsl:variable name="match" select="."/>
                <xsl:variable name="regex-group-values" as="element(p:regex-group)*">
                    <xsl:for-each select="$regex-groups-in-pattern">
                        <p:regex-group n="{.}"><xsl:value-of select="regex-group(.)"/></p:regex-group>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:apply-templates select="$pattern" mode="populate-pattern">
                    <xsl:with-param name="pattern" select="$pattern" tunnel="yes"/>
                    <xsl:with-param name="match" select="$match" tunnel="yes"/>
                    <xsl:with-param name="regex-group-values" select="$regex-group-values" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:matching-substring>
            <xsl:non-matching-substring/>
        </xsl:analyze-string>
    </xsl:template>
</xsl:stylesheet>