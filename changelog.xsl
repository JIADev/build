<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" id="changelogStyle">
<xsl:output method="html" />
<xsl:template match="/">
  <html>
  <body>
  <h2>ChangeLog</h2>
  <table border="1">
    <tr bgcolor="#9acd32">
	  <th>Branch</th>
      <th>Author</th>
	  <th>Date</th>
	  <th>Message</th>
    </tr>
    <xsl:for-each select="log/logentry">
    <xsl:sort select="date" order="descending"/>
	<tr>
      <td><xsl:value-of select="branch"/></td>
      <td><xsl:value-of select="author"/></td>
	  <td><xsl:value-of select="date"/></td>
      <td><xsl:value-of select="msg"/></td>
    </tr>
    </xsl:for-each>
  </table>
  <h2>Files Affected</h2>
  <table border="1">
    <tr bgcolor="#9acd32">
	  <th>Operation</th>
	  <th>Path</th>
	  <th>Author(s)</th>
    </tr>
    <xsl:for-each select="log/modifiedfiles/file">
	<xsl:sort select="@date" order="descending" />
	<tr>
      <td><xsl:value-of select="@actions"/></td>
	  <td><xsl:value-of select="@path"/></td>
      <td><xsl:value-of select="@authors"/></td>
    </tr>
    </xsl:for-each>
  </table>
  </body>
  </html>
</xsl:template>

</xsl:stylesheet>