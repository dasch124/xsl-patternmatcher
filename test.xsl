<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:p="https://id.acdh.oeaw.ac.at/patternmatcher"
    exclude-result-prefixes="#all"
    version="2.0">
    
    <xsl:import href="pattern-matcher.xsl"/>
    
    <xsl:param name="myPatterns">
        <p:pattern match="(\d{{2,2}})\.(\d{{1,2}})\.(\d{{4,4}})" name="DD.MM.YYYY">
            <p:group n="1">
                <p:transform function="pad-integer-to-length">
                    <p:arg>2</p:arg>
                </p:transform>
            </p:group>
            <p:group n="2">
                <p:transform function="pad-integer-to-length">
                    <p:arg>2</p:arg>
                </p:transform>
            </p:group>
            <p:out><date xmlns="http://www.tei-c.org/ns/1.0" when="group:3-group:2-group:1">$match</date></p:out>
        </p:pattern>
        <p:pattern match="ist" name="ist">
            <p:match>
                <p:transform function="upper-case"/>
            </p:match>
            <p:out>$match</p:out>
        </p:pattern>
    </xsl:param>
    
    <xsl:template match="/">
        <xsl:apply-templates>
            <xsl:with-param name="patternmatcher.patterns" select="$myPatterns" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    
</xsl:stylesheet>