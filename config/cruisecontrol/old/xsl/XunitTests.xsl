<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/TR/html4/strict.dtd">	
	<xsl:output method="html"/>	
	<xsl:param name="applicationPath"/>

	<xsl:template match="/">
		<xsl:variable name="tests.root" select="cruisecontrol//test-results" />
		<xsl:variable name="xunittests.root" select="cruisecontrol//assembly" />
		<div id="report">
			<script>
				function toggleDiv( imgId, divId )
				{
					eDiv = document.getElementById( divId );
					eImg = document.getElementById( imgId );
					
					if ( eDiv.style.display == "none" )
					{
						eDiv.style.display = "block";
						eImg.src = "<xsl:value-of select="$applicationPath"/>/images/arrow_minus_small.gif";
					}
					else
					{
						eDiv.style.display = "none";
						eImg.src = "<xsl:value-of select="$applicationPath"/>/images/arrow_plus_small.gif";
					}
				}
			</script>
		
			<h1>XUnit Test Results</h1>
			<div id="summary">
				<h3>Summary</h3>
				<table>
					<tbody>
						<tr>
							<td>Assemblies tested:</td>
							<td><xsl:value-of select="count($xunittests.root)"/></td>
						</tr>
						<tr>
							<td>Tests executed:</td>
							<td><xsl:value-of select="count($xunittests.root//test)"/></td>
						</tr>
						<tr>
							<td>Passes:</td>
							<td><xsl:value-of select="count($xunittests.root//test[@result='Pass'])"/></td>
						</tr>
						<tr>
							<td>Fails:</td>
							<td><xsl:value-of select="count($xunittests.root//test[@result='Fail'])"/></td>
						</tr>
						<tr>
							<td>Skipped:</td>
							<td><xsl:value-of select="count($xunittests.root//test[@result='Skip'])"/></td>
						</tr>
					</tbody>
				</table>
			</div>
			
			<div id="details">
				<h3>Assembly Test Details:</h3>
				<xsl:apply-templates select="$xunittests.root" />
			</div>
		</div>
	</xsl:template>
	
	<xsl:template match="assembly">
		<xsl:variable name="test.suite.id" select="generate-id()" />
		<xsl:variable name="test.suite.name" select="./@name"/>
		<xsl:variable name="failure.count" select="count(.//class/test[@result='Fail'])" />
		<xsl:variable name="ignored.count" select="count(.//class/test[@result='Skip'])" />
				
		<table cellpadding="2" cellspacing="0" border="0" width="98%">
			<tr>
				<td class="yellow-sectionheader" colspan="3" valign="top">
					<xsl:choose>
						<xsl:when test="$failure.count > 0">
							<img src="{$applicationPath}/images/fxcop-critical-error.gif">
								<xsl:attribute name="title">Failed tests: <xsl:value-of select="$failure.count" /></xsl:attribute>
							</img>
						</xsl:when>
						<xsl:when test="$ignored.count > 0">
							<img src="{$applicationPath}/images/fxcop-error.gif">
								<xsl:attribute name="title">Ignored tests: <xsl:value-of select="$ignored.count" /></xsl:attribute>
							</img>
						</xsl:when>
						<xsl:otherwise>
							<img src="{$applicationPath}/images/check.jpg" width="16" height="16"/>
						</xsl:otherwise>
					</xsl:choose>
			
					<input type="image" src="{$applicationPath}/images/arrow_minus_small.gif">
						<xsl:attribute name="id">img<xsl:value-of select="$test.suite.id"/></xsl:attribute>
						<xsl:attribute name="onclick">javascript:toggleDiv('img<xsl:value-of select="$test.suite.id"/>', 'divDetails<xsl:value-of select="$test.suite.id"/>');</xsl:attribute>
					</input>&#160;<xsl:value-of select="$test.suite.name"/>
            </td>
			</tr>
		</table>
		<div>
			<xsl:attribute name="id">divDetails<xsl:value-of select="$test.suite.id"/></xsl:attribute>
			<blockquote>
				<table>
					<tr>
						<th>Test Fixture</th>
						<th>Status</th>
						<th>Progress</th>
						<th>Total Time (Seconds)</th>
					</tr>
					<!--all failing tests-->
					<!--all red-->
					<!--<xsl:apply-templates select=".//class[@failed > '0' and @passed = '0' and @skipped = '0'][test]">--> 
					<!--	<xsl:sort select="count(test)" order="ascending" data-type="text"/>-->
					<!--</xsl:apply-templates>-->
					
					
					<!--all failing tests with passed and skipped-->
					<!--red, yellow, green-->
					<!--<xsl:apply-templates select=".//class[@failed > '0' and @passed > '0' and @skipped > '0'][test]">--> 
					<!--	<xsl:sort select="count(test[@result='Fail']) div count(test)" order="ascending" data-type="text"/>-->
					<!--</xsl:apply-templates>-->
					
					<!--all failing tests with passed-->
					<!--red, green-->
					<!--<xsl:apply-templates select=".//class[@failed > '0' and @passed > '0' and @skipped = '0'][test]">--> 
					<!--	<xsl:sort select="count(test[@result='Fail']) div count(test)" order="ascending" data-type="text"/>-->
					<!--</xsl:apply-templates>-->
					
					<!--all failing tests with skipped-->
					<!--red, yellow-->
					<!--<xsl:apply-templates select=".//class[@failed > '0' and @passed = '0' and @skipped > '0'][test]">--> 
					<!--	<xsl:sort select="count(test[@result='Fail']) div count(test)" order="ascending" data-type="text"/>-->
					<!--</xsl:apply-templates>-->
					
					<!--all failing tests with skipped-->
					<!--red, yellow-->
					<xsl:apply-templates select=".//class[@failed > '0'][test]">
						<xsl:sort select="count(test[@result='Fail']) div count(test)" order="descending" data-type="text"/>
						<xsl:sort select="count(test) + 1000" order="descending" data-type="text"/>
					</xsl:apply-templates>
					
					<!--all skipped tests-->
					<!--all yellow-->
					<xsl:apply-templates select=".//class[@failed = '0' and @passed = '0' and @skipped > '0'][test]"> 
						<xsl:sort select="count(test)" order="ascending" data-type="text"/>
					</xsl:apply-templates>
										
					<xsl:apply-templates select=".//class[@failed = '0' and @passed = '0' and @skipped = '0'][test]"> <!--no failing, no passed, no skipped-->
					</xsl:apply-templates>
					
					<!--passing tests with skipped-->
					<!--green, yellow-->
					<xsl:apply-templates select=".//class[@failed = '0' and @passed > '0' and @skipped > '0'][test]"> 
						<xsl:sort select="count(test[@result='Skip']) div count(test)" order="descending" data-type="text"/>
					</xsl:apply-templates>
					
					<!--passing tests with no skipped-->
					<!--all green-->
					<xsl:apply-templates select=".//class[@failed = '0' and @passed > '0' and @skipped = '0'][test]"> 
					</xsl:apply-templates>
				
				</table>
			</blockquote>
		</div>
	</xsl:template>

	<xsl:template match="class" mode="success">
		<xsl:if test="count(test[@result='Fail']) + count(test[@result='Skip']) = 0">
			<xsl:apply-templates select="."/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="class">
		<xsl:variable name="passedtests.list" select="test[@result='Pass']"/>
		<xsl:variable name="ignoredtests.list" select="test[@result='Skip']"/>
		<xsl:variable name="failedtests.list" select="test[@result='Fail']"/>
		<xsl:variable name="tests.count" select="count(test)"/>
		<xsl:variable name="passedtests.count" select="count($passedtests.list)"/>
		<xsl:variable name="ignoredtests.count" select="count($ignoredtests.list)"/>
		<xsl:variable name="failedtests.count" select="count($failedtests.list)"/>
		<xsl:variable name="totaltime" select="@time"/>

		<xsl:variable name="testName" select="@name"/>
		<tr >
			<td valign="top"  width = "55%">
				<input type="image" src="{$applicationPath}/images/arrow_plus_small.gif">
					<xsl:attribute name="id">imgTestCase_<xsl:value-of select="@name"/></xsl:attribute>
					<xsl:attribute name="onClick">javascript:toggleDiv('imgTestCase_<xsl:value-of select="$testName"/>', 'divTest_<xsl:value-of select="$testName"/>');</xsl:attribute>
				</input>
				<a>
					<xsl:attribute name="name"><xsl:value-of select="@name"/></xsl:attribute>
					<xsl:value-of select="@name"/>
				</a>
			</td>
			<td width="300px">
				<table border="0" cellspacing="1" width="100%">
					<tr>
						<xsl:if test="$passedtests.count > 0">
							<xsl:variable name="passedtests.countpercent" select="($passedtests.count * 100) div $tests.count"/>
							<td bgcolor="green">
								<xsl:attribute name="width"><xsl:value-of select="$passedtests.countpercent"/>%</xsl:attribute>
						&#160;
					</td>
						</xsl:if>
						<xsl:if test="$ignoredtests.count > 0">
							<xsl:variable name="ignoredtests.countpercent" select="($ignoredtests.count * 100) div $tests.count"/>
							<td bgcolor="yellow">
								<xsl:attribute name="width"><xsl:value-of select="$ignoredtests.countpercent"/>%</xsl:attribute>
						&#160;
					</td>
						</xsl:if>
						<xsl:if test="$failedtests.count > 0">
							<xsl:variable name="failedtests.countpercent" select="($failedtests.count * 100) div $tests.count"/>
							<td bgcolor="red">
								<xsl:attribute name="width"><xsl:value-of select="$failedtests.countpercent"/>%</xsl:attribute>
						&#160;
					</td>
						</xsl:if>
					</tr>
				</table>
				<!--xsl:if test="$failedtests.count > 0 or $ignoredtests.count > 0"-->
				<!--<div style="display:none">
					<xsl:attribute name="id">divTest_<xsl:value-of select="$testName"/></xsl:attribute>
					<table border="0" cell-padding="6" cell-spacing="0" width="100%">
						<xsl:apply-templates select="$failedtests.list"/>
						<xsl:apply-templates select="$ignoredtests.list"/>
						<xsl:apply-templates select="$passedtests.list"/>
					</table>
				</div>-->
				<!--/xsl:if-->
			</td>
			<td valign="top">
				(<xsl:value-of select="$passedtests.count"/>/<xsl:value-of select="$tests.count"/>)
			</td>
			<td valign="top">
				<xsl:value-of select="$totaltime"/>
			</td>
		</tr>
		<tr>
			<td colspan = "4">
				<div style="display:none">
					<xsl:attribute name="id">divTest_<xsl:value-of select="$testName"/></xsl:attribute>
					<table border="0" cell-padding="6" cell-spacing="0" width="100%">
						<xsl:apply-templates select="$failedtests.list"/>
						<xsl:apply-templates select="$ignoredtests.list"/>
						<xsl:apply-templates select="$passedtests.list"/>
					</table>
				</div>
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="test[@result='Pass']">
		<tr>
			<xsl:if test="position() mod 2 = 0">
				<xsl:attribute name="class">section-oddrow</xsl:attribute>
			</xsl:if>
			<td width = "30px"/>
			<td>
				<img src="{$applicationPath}/images/check.jpg" width="16" height="16"/>
			</td>
			<td>
				<xsl:call-template name="getTestName">
					<xsl:with-param name="name" select="@name"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:value-of select="substring-after(failure/message, '-')"/>
			</td>
		</tr>
	</xsl:template>
	<xsl:template match="test[@result='Fail']">
		<tr>
			<xsl:if test="position() mod 2 = 0">
				<xsl:attribute name="class">section-oddrow</xsl:attribute>
			</xsl:if>
			<td width = "30px"/>
			<td>
				<img src="{$applicationPath}/images/fxcop-critical-error.gif"/>
			</td>
			<td>
				<xsl:call-template name="getTestName">
					<xsl:with-param name="name" select="@name"/>
				</xsl:call-template>
			</td>
			<td bgcolor="gainsboro">
				<!--<xsl:value-of select="substring-after(failure/message, '-')"/><br/>-->
				<br/><b><xsl:value-of select="failure/message"/></b><br/><br/>
				<!--<pre>-->
					<xsl:value-of select="failure/stack-trace"/>
				<!--</pre>-->
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="test[@result='Skip']">
		<tr>
			<xsl:if test="position() mod 2 = 0">
				<xsl:attribute name="class">section-oddrow</xsl:attribute>
			</xsl:if>
			<td width = "30px"/>
			<td>
				<img src="{$applicationPath}/images/fxcop-error.gif"/>
			</td>
			<td>
				<xsl:call-template name="getTestName">
					<xsl:with-param name="name" select="@name"/>
				</xsl:call-template>
			</td>
			<td>
				<xsl:value-of select="substring-after(reason/message, '-')"/>
			</td>
		</tr>
	</xsl:template>

	<xsl:template name="getTestName">
		<xsl:param name="name"/>
		<xsl:choose>
			<xsl:when test="contains($name, '.')">
				<xsl:call-template name="getTestName">
					<xsl:with-param name="name" select="substring-after($name, '.')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$name"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>