set-psdebug -strict

. Sql-Utils.ps1
function deployfeature
{
	$buildroot = [string](pwd)	
	$releaseDirectory = $config.settings.configurations.releaseDirectory
	$customer = $config.settings.customer

"deployfeature build -$buildroot"
"deployfeature dir - $releaseDirectory"
		
	if(Test-Path $releaseDirectory)
	{
		Remove-Item $releaseDirectory -recurse -force -ErrorAction Continue
	}
	new-item $releaseDirectory -type directory -force
	
	Copy-Item log-settings.xml $releaseDirectory -force
	cd $releaseDirectory

	$BuildSettingsPath = join-path $releaseDirectory "Build-Settings.xml"
	$config.Save($BuildSettingsPath)
	create-sqlsettings $config.settings.sql.server $config.settings.sql.database $config.settings.sql.uid $config.settings.sql.pwd
	
	cd $buildroot

	feature package $releaseDirectory
	cd $releaseDirectory 
	
	feature install --site --shared --verbose
	feature install --patch --verbose
 
	run-autodeploy -clean $false -config $config
}

function releasefeature
{
	$buildroot = [string](pwd)	
	$releaseDirectory = $config.settings.configurations.releaseDirectory
	# make sure customer name == driver feature name
	$customer = $config.settings.customer
		
	if(Test-Path $releaseDirectory)
	{
		Remove-Item $releaseDirectory -recurse -force -ErrorAction Continue
	}
	new-item $releaseDirectory -type directory -force
	
	Copy-Item log-settings.xml $releaseDirectory -force
	cd $releaseDirectory

	$BuildSettingsPath = join-path $releaseDirectory "Build-Settings.xml"
	$config.Save($BuildSettingsPath)
	create-sqlsettings $config.settings.sql.server $config.settings.sql.database $config.settings.sql.uid $config.settings.sql.pwd
	
	cd $buildroot

	# code veil is not working well with cruise control.

	feature protect $releaseDirectory $buildBitType
	feature package $releaseDirectory, $customer 
	pushd $releaseDirectory
	minify-css
	minify-js
	popd
}

function buildfeature {
	$buildroot = [string](pwd)
	$MercurialRepository = $config.settings.configurations.svnRepository
	$customer = $config.settings.customer

"MercurialRepository"
$MercurialRepository 
"buildfeature build - $buildroot"
	
	##Clean features and remove any junctions
	feature cleanjunctions
	get-childitem $args -ea SilentlyContinue | where { $_.PSIsContainer } | ForEach-Object {if($_.Name.Contains("TestResult") -or $_.Name.Contains("log-settings.xml") -or $_.Name.Contains("RELEASE-")){}else{Remove-Item $_.Name -recurse -force -ErrorAction SilentlyContinue }}
	
	Remove-Item Build-Settings.xml
	Remove-Item Sql-Settings.xml
	#$config = $(get-debugconfig $customer)
	$BuildSettingsPath = join-path $buildroot "Build-Settings.xml"
	$config.Save($BuildSettingsPath)
	create-sqlsettings $config.settings.sql.server $config.settings.sql.database $config.settings.sql.uid $config.settings.sql.pwd
	
	
	hg clone $MercurialRepository
	
	#Fetch features
	feature fetch

	#set version number
	feature setversion
	
	#Setup features
	feature setup
	
	#Revert database - Todo, does not copy the bak file so need to do it manually.
	#dropandreplace-database
		
	#Run Patches
	feature install --patch --verbose
	
	#Build Features
	feature build
}

function minify-css {
	$jar = $env:buildscripts + "\yuicompressor.jar"
	feature list | % { dir $_ -r -include *.css } `
		| ? { !($_.fullname -match "(YUI|PrecompiledWeb)") } `
		| % { "Compressing " + $_.fullname; java -jar $jar $_.fullname -o $_.fullname }
}

function minify-js {
	$jar = $env:buildscripts + "\yuicompressor.jar"
	feature list | % { dir $_ -r -include *.js } `
		| ? { !($_.fullname -match "(YUI|PrecompiledWeb)") } `
		| % { "Compressing " + $_.fullname; java -jar $jar --charset utf8 $_.fullname -o $_.fullname }
}
