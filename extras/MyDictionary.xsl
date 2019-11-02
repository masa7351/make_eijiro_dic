<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:d="http://www.apple.com/DTDs/DictionaryService-1.0.rng"
				version="1.0">
<xsl:output method="xml" encoding="UTF-8" indent="no"
	doctype-public="-//W3C//DTD XHTML 1.1//EN"
	doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd" />

<!--
	$yomigana=1 の場合だけ漢字の「読みがな」(<span class='ruby'>) を表示
-->

<xsl:template match="*[@class='ruby']">
	<xsl:if test="$yomigana = '1'">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" />
		</xsl:copy>
	</xsl:if>
</xsl:template>

<!--
	Default rule for all other tags
-->
<xsl:template match="@*|node()">
	<xsl:copy>
		<xsl:apply-templates select="@*|node()" />
	</xsl:copy>
</xsl:template>

</xsl:stylesheet>
