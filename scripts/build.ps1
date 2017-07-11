set-psdebug -strict

. core.ps1
#. subversion.ps1
. sql-utils.ps1
. feature-control.ps1

$global:isInteractiveBuild=$true
$buildLogDir="build-logs"
$preLoadPatchBuilds="build/Init.sln","build/Tools.sln"
$postLoadPatchBuilds="build/CoreModule.sln","build/Business.sln", "build/SummitIntegration.sln"
$testBuilds=@("build/Testing.sln")
$webBuilds=@("build/Web.sln")
$realtime=@("GlobalModule/RealtimeService/RealtimeQualifications.csproj")
$sis=@("ImportExportModule/SummitIntegration.Service/SummitIntegration.Service.csproj")

#Returns the official version for the current branch at the current revision number.
function get-version{
	#param([string]$svnUrl="")
	#if (gcm svn.exe*) {
	#	$log = get-lastsvnentry $svnUrl
	#	$rev = $log.log.logentry.revision
	#	$info = [xml](exec-svn info $svnUrl --xml)
	#}
	$version = "0.0.0"
	$url = $info.info.entry.url
	$folder = $url.split("/")[-1]
	if ($url -match "\d+\.\d+\.\d+") { $version = $folder }
	$version += ".$rev"
	$version
}

#function init-fromsvn {
#	param(
#		$targetdir,
#		$svnrepo,
#		$svncmd = "export"
#	)
#	if (gcm svn.exe*) {
#		if(test-path $targetdir){
#			validate-command {
#				rm -r -fo $targetdir
#			} "Unable to delete $targetdir"
#		}
#		validate-command {
#			log ("retrieving $svnrepo to $targetdir")
#			exec-svn $svncmd -q --force $svnrepo $targetdir
#		} "unable to init $targetdir from svn"
#	}
#	else {
#		log ("No svn.exe found")
#	}
#}

#Sets all the assembly versions to the correct current number for this checkout.
function update-assemblyversions {
	param([string]$version = (get-version))
	foreach($file in "AssemblyVersion.cs","DataModule\Generated\AssemblyInfo.cs") {
		if (test-path($file)) {
			$updated = (get-content $file) -replace "\d+\.\d+\.\d+\.\d*",$version
			set-content -path $file $updated
		}
	}
}

## Accept the SysInternals Eula
function accept-sysinternalseula {
	param( $Program = "Junction" )
	$regpath = (join-path HKCU:\Software\Sysinternals $Program)
	if(test-path $regpath){return}
	log "Creating $regpath"
	$key = new-item -force -path $regpath
	log "Setting EulaAccepted to 1"
	$val = new-itemproperty -Path $regpath -Name "EulaAccepted" -Type DWord -Value 1
}

accept-sysinternalseula -Program "Junction"
accept-sysinternalseula -Program "Handle"

function junction {
	$junction_exe = "shared\junction.exe"
	if (test-path lib\junction.exe) {
		$junction_exe = "lib\junction.exe"
	}
		& $junction_exe $args
}

function find-junctions {
	param ([string]$root)

	junction -s $root |
	% {
		if ($_.Contains(": JUNCTION")){
			$_.Replace(": JUNCTION","").TrimStart(".")
		}
	}
}

function remove-junctions {
	param ([string]$root)
	find-junctions -root $root | %{ junction -d $_ }
}

function create-junction {
	param ([string]$original, [string]$target)
	if (test-path $original) {
		if (-not (test-path $target)){
			junction $target $original
		} else {
			[string]$ev = $(junction $target)
			if (! $ev.Contains("Substitute Name:")) {
				[string]$rename = $target + ".BACKUP"
				log-warning ("Renaming {0} to {1}. Delete {1} after recovering any unsaved data" -f $target,$rename)
				if (test-path $target) { mv $target $rename }
				if ($?) { junction $target $original }
			}else{log-warning ("{0} already targetted." -f $target)}
		}
	} else {
		log-warning "$original does not exist"
		return;
	}
}

function duplicate-shared-portal-folders {
	[string]$base_orig = "sites\portal"
	[string]$base_targ = "sites\employee-portal"
	$folders = "App_Code\Shared","JS", "Assets", "Services", "Controls"
	if (test-path sites\controls) {
		$folders = "App_Code\Shared","JS", "Assets", "Services"
	}
	foreach($dir in $folders) {
		$original = $base_orig + "\" + $dir
		$target = $base_targ + "\" + $dir
		if (test-path($original)) { create-junction -original $original -target $target }
	}

	if (!(test-path sites\employee-portal\App_Themes)) {
		$original = $base_orig + "\App_Themes"
		$target = $base_targ + "\App_Themes"
		if (test-path($original)) { create-junction -original $original -target $target }
	}
	if (test-path sites\personal) {
		$base_targ = "sites\personal"
		foreach($dir in "JS","Controls","Services","Assets") {
			$original = $base_orig + "\" + $dir
			$target = $base_targ + "\" + $dir
			if (test-path($original)) { create-junction -original $original -target $target }
		}
	}

	if (test-path sites\jWeb) {
		$base_targ = "sites\jWeb\Web\Apps\jWeb"
		foreach($dir in "App_Code\Shared","JS", "Assets") {
			$original = $base_orig + "\" + $dir
			$target = $base_targ + "\" + $dir
			if (test-path($original)) { create-junction -original $original -target $target }
		}
	}
}

function load-patches {
	$settings = (get-buildsettings).settings
	assert-notempty $settings.customer "Cannot find customer id. Cannot load custom patches"

	$defaultPath = 'data\patches'
	$customPath = 'data\CustomPatches\' + $settings.customer
	$OptionalPath = 'data\CustomPatches\' + $settings.customer + '\OptionalPatches'

	log "delete optional patches $OptionalPath from custompatches if exists"
	if(test-path $OptionalPath){
		del $OptionalPath -recurse
	}

	log "create an optional patches folder $OptionalPath under custom folder"
	mkdir $OptionalPath

	#export setting to optional configuration file
	$optional=[xml]"<Options><option /></Options>"

	#$url = ("http://source.jenkon.com/svn/custom/{0}/Config/OptionalPatch.xml" -f $settings.customer)
	#if(svn-exists $url){$optional=get-xmlfromsvn $url}

	foreach($option in $optional.Options.option){
		if($option){
			$from = "data\OptionalPatches\" + $option;
			if(-not (test-path $from -pathtype leaf)){
				$from = $from +"*.*";
			}
			else{
				$option = split-path $option;
			}

			$to = $OptionalPath +"\" + $option;
			if(-not (test-path $to)){
				Mkdir $to
				log "create folder #to";
			}

			log "Copy from $from to $to"
			Copy $from $to
		}
	}

	log "loading patches for $defaultPath and $customPath"
	if (test-path $customPath) {
		validate-command {shared\loadpatch $defaultPath $customPath} "Unable to load patches"
	} else {
		validate-command {shared\loadpatch $defaultPath} "Unable to load patches"
	}
}

function revert-database {
	dropandreplace-database
	load-patches
}

function generate-webservice {
	if(test-path internalshared\WebServiceGenerator.exe){
		validate-command {internalshared\WebServiceGenerator} "Unable to generate web services"
	} elseif(test-path shared\WebServiceGenerator.exe){
		validate-command {shared\WebServiceGenerator} "Unable to generate web services"
	}
	else {
		warn "WebServiceGenerator doesn't exist"
	}
}

function build-logger {
	param($str)
	$logFile = join-path $buildLogDir "build.log"
	add-content $logFile $str
}

function build {
	param(
		[string]$buildPath,
		[string]$buildAction = 'Rebuild',
		$buildLogger
	)
	$noConsoleLogSwitch = ""
	$noLogoSwitch = ""
	$logger = ""

	log "Building $buildPath $buildAction"
	if($isInteractiveBuild) {
		build-solution $buildPath $buildAction $global:configuration
		return
	}

	if (!($buildLogger)) { $buildLogger = "build-logger" }

	$result = msbuild $buildPath /t:$buildAction /p:PlatformTarget=x86 /p:Configuration=$global:configuration "/noconsolelogger" "/nologo" "/logger:ThoughtWorks.CruiseControl.MsBuild.dll"
	[xml]$buildResult = $result
	$success = $buildResult.msbuild.success -eq 'true'
	$buildNotes = "Build results for $buildPath $buildAction - "

	if ($success) {
		$buildNotes += "success `n"
		&$buildLogger $buildNotes
		return
	}

	$buildNotes += "failure `n"
	$buildResult.selectNodes("//error") | % {
		$node = $_;
		$parent = $node.get_ParentNode()
		$msg = "Project " + $parent.name + " failed at file: " + $node.file + "`n"
		$msg += "Line " + $node.line + " col: " + $node.column + "`n"
		$msg += $node.get_InnerText()
		$buildNotes += $msg
	}
	&$buildLogger $buildNotes
	throw $buildNotes
}

function fetch-earnings-module {
	param([string]$url = $(throw "Enter a URL to the repo folder"),
			[string]$mode = 'hg'
		)
	if ($mode -eq 'svn') {
		#$last = $url.split("/")[-1]
		#if(-not($last -eq "EarningsModule")){
		#	$last = "EarningsModule"
		#	$url = "{0}/{1}" -f $url,$last
		#}
		#if(test-path $last){
		#	mv $last "DELETE-$last";
		#	warn "$last exists! moving to DELETE-$last"
		#}
		#svn.exe co $url $last
	} elseif ($mode -eq 'hg') {
		hg.exe clone $url EarningsModule
		if (test-path EarningsModule\default-hgignore) {
			copy EarningsModule\default-hgignore EarningsModule\.hgignore
		}
	}
}


#Updates the repository, including any folders copied in from the earnings repository
#function update-svn {
#	$defaults = ".","SiteTests\employee-portal.tests"
#	$earnings = "EarningsModule"

	#$defaults|?{test-path $_}|%{log ("Updating: {0}" -f $_);svn.exe update $_}
	#$earnings|?{test-path $_}|%{log ("Updating: {0}" -f $_);svn.exe update $_}
#}

function build-solutions {
	build-init
	build-tools
	build-core
	build-business
	build-sis
	if (test-path EarningsModule) { build-earnings }
	build-customsolutions
	generate-webservice
	build-web
}

function build-solution {
	param(
		[string]$solution,
		[string]$type='Rebuild',
		[string]$config=$global:configuration
	)
	msbuild $solution /t:$type /p:Configuration=$config /p:PlatformTarget=x86
}

function build-solutionsafe {
	param(
		[string]$solution,
		[string]$type='Rebuild',
		[string]$config=$global:configuration
	)
	$msproj = generate-msbuild $solution
	exclude-project $msproj ".rptproj"
	msbuild $msproj /t:$type /p:Configuration=$config /p:PlatformTarget=x86
}

function build-solutiondevenv {
	param(
		[string]$solution,
		[string]$config=$global:configuration
	)
	$out=(devenv $solution /build $config)
	$out
}

function build-init { build-solution build\init.sln }
function build-tools { build-solution build\tools.sln }
function build-core { build-solution build\coremodule.sln }
function build-business { build-solution build\business.sln }
function build-sis { build-solution build\SummitIntegration.sln}
function build-testing { build-solution build\testing.sln }
function build-personal { build-solution build\personal.msbuild }
function build-portal { build-solution build\portal.msbuild }
function build-employeeportal { build-solution build\employee.msbuild }
function build-services { build-solution build\services.msbuild }


function build-web {
	if(test-path CustomDlls) {
		(ls sites)|%{cp CustomDlls\*.dll (join-path $_.FullName "bin")}
	}
	build-solution build\web.sln
}

function build-earnings { build-solution build\earnings.sln }

function load-appsettings {
	if (!(test-path "configuration\appsettings")) {
		return "App settings are no longer used in this version, use load-patches instead";
	}
	$settings = (get-buildsettings).settings
	assert-notempty $settings.customer "Cannot find customer id. Cannot load custom app settings"
	$paths = 'configuration\appsettings', ("configuration\customappsettings\" + $settings.customer)
	foreach($path in $paths) {
		log "loading AppSettings at $path"
		foreach($f in dir $path) {
			$n = $f.fullname
			shared\importappsettings -f $n
		}
	}
}

$script:RemotePath = '\\bubba\d$\j6\'
$script:RemoteTiersPath = join-path $script:RemotePath 'tiers-generation'

#Generate the .NetTiers source
function generate-nettiers {
	$username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
	Log "Generating NetTiers using user : $username "

	$settings = get-buildsettings
	$config = $settings.settings.configurations
	$sql = (get-sqlsettings).settings.sql
	$remoteWorkingDir = join-path $script:RemoteTiersPath $config.remoteTiersDirectory
	$generatePropertiesPath = join-path (pwd).Path "DataModule\generated-properties.csp"

	assert-notempty $settings.settings.customer "Cannot find customer in Build-Settings.xml"
	assert-notempty $config.remoteTiersDirectory "Cannot find setting remoteTiersDirectory in Build-Settings.xml"
	assert-notempty $sql.server "Cannot find setting sql.server in Sql-Settings.xml"
	assert-notempty $sql.database "Cannot find setting sql.database in Sql-Settings.xml"

	CombineDataFiles $settings.settings.customer $generatePropertiesPath

	validate-command {
		remove-dir($remoteWorkingDir)
		mkdir $remoteWorkingDir
		cp "$((get-command generate-tiers.ps1).definition)" $remotePath
		cp $generatePropertiesPath (join-path $remoteWorkingDir "datamodule-properties.csp")
	} "Unable to initialize remote directory"

	pushd "$(([System.IO.FileInfo](get-command generate-tiers.ps1).definition).directoryname)"
	& {
		trap{popd;throw $_}
		wscript -regserver
		cscript RemotePowershellClient.wsf /path:"d:\j6\" /script:"./generate-tiers.ps1" $config.remoteTiersDirectory $config.svnRepository $sql.server $sql.database $sql.uid $sql.pwd
		assert-equal $LastExitCode 0 'Error generating tiers see log @ \\bubba\d$\j6\tiers-generation\ '
	}
	popd
	remotecopy-nettiers $settings.settings.customer
}

function combinedatafiles {
	param([string]$customer, [string]$combinedPath)
	function appendelement {
		param([System.Xml.XmlElement]$destTable, [System.Xml.XmlElement]$element, [string]$type)
		$table = $xml.CreateElement($type)
		$destTable.AppendChild($table)

		$owner = $xml.CreateElement("owner")
		$owner.set_InnerText($element.owner)
		$table.AppendChild($owner)

		$name = $xml.CreateElement("name")
		$name.set_InnerText($element.name)
		$table.AppendChild($name)
	}

	function processdata {
		param($table, $callback)
		if ($table.Count -eq $null) { & $callback $table }
		else { for($i = 0; $i -lt $table.Count; $i++) { & $callback $table[$i] } }
	}

	function processproperty {
		param($property)
		if ($property.name -eq "SourceTables") {
			ProcessData $property.table {param($property) AppendElement $sourceTables $property "table"}
		} elseif ($property.name -eq "EnumTables") {
			ProcessData $property.table {param($property) AppendElement $enumTables $property "table"}
		} elseif ($property.name -eq "SourceViews") {
			ProcessData $property.view {param($property) AppendElement $sourceViews $property "view"}
		}
	}

	function trimemptyns {
		param($file, $tag)
		$pattern = "<$tag xmlns=`"`">"
		$replace = "<$tag>"
		$updated = (get-content $file) -replace $pattern, $replace
		set-content -path $file $updated
	}

	$defaultPath = (pwd).Path + "\DataModule\datamodule-properties.csp"
	$overridePath = (pwd).Path + "\DataModule\" + $customer + "\datamodule-properties.csp"

	cp $defaultPath $combinedPath
	$xml = [xml] (gc $combinedPath)

	$xmlProperty = $xml.codeSmith.propertySets.propertySet.property
	for($i = 0; $i -lt $xmlProperty.Length; $i++) {
		$node = $xmlProperty[$i]
		if ($node.name -eq "SourceTables") { $sourceTables = $node.tableList }
		elseif ($node.name -eq "EnumTables") { $enumTables = $node.tableList }
		elseif ($node.name -eq "SourceViews") { $sourceViews = $node.viewList }
	}

	if (test-path $overridePath) {
		$custxml = [xml] (gc $overridePath)
		if ($custXml.Overrides.property.Count -eq $null) { ProcessProperty $custxml.Overrides.property }
		else {
			for($i = 0; $i -lt $custxml.Overrides.property.Count; $i++) {
				ProcessProperty $custxml.Overrides.property[$i]
			}
		}

		$xml.save($combinedPath)

		TrimEmptyNS $combinedPath "table"
		TrimEmptyNS $combinedPath "view"
	}
}

function remotecopy-nettiers {
	param([string]$customer)
	$config = (get-buildsettings).settings.configurations
	$dirFrom = join-path (join-path $script:RemoteTiersPath $config.remoteTiersDirectory) "Datamodule\Generated"
	if (!(test-path $dirFrom)) { throw "$dirFrom does not exist. It is possible the project was not generated." }
	$dirTo = ".\DataModule\" + $customer + "\Generated"
	remove-dir $dirto
	log("copying $dirFrom to $dirTo")
	cp -recurse $dirFrom $dirTo
	cp AssemblyVersion.cs $dirTo
	compact /q /u /s:$dirTo
}

function build-nettiers {
	$settings = get-buildsettings
	assert-notempty $settings.settings.customer "Cannot find customer in Build-Settings.xml"
	$customer = $settings.settings.customer
	$customShare = "Shared/$customer"

	build "DataModule/$customer/Generated/Jenkon.J6.sln" "Rebuild"
	log "Copying Jenkon.J6 assemblies to Shared"
	cp "DataModule/$customer/Generated/Jenkon.J6.Components/bin/$global:configuration/Jenkon.J6.*" "Shared"
	if (!(test-path "Shared\Microsoft.Practices.*")) {
		log "Copying Microsoft.Practices assemblies to Shared"
		cp "DataModule/$customer/Generated/Jenkon.J6.Components/bin/$global:configuration/Microsoft.Practices.*" "Shared"
	}
	if (!(test-path $customShare)) { mkdir $customShare }
	log "Copying Jenkon.J6 assemblies to $customShare"
	cp "DataModule/$customer/Generated/Jenkon.J6.Components/bin/$global:configuration/Jenkon.J6.*" $customShare
	if (!(test-path "$customShare\Microsoft.Practices.*")) {
		log "Copying Microsoft.Practices assemblies to $customShare"
		cp "DataModule/$customer/Generated/Jenkon.J6.Components/bin/$global:configuration/Microsoft.Practices.*" "Shared"
	}
	cp "DataModule/$customer/Generated/Jenkon.J6.Components/bin/$global:configuration/Microsoft.Practices.*" $customShare
}

function set-customer {
	param ([string]$cust = $(throw "Enter a customer Id"))
	$sharedPath = "Shared"
	$custSharedPath = join-path $sharedPath $cust
	if (!(test-path $custSharedPath)) { throw "$custSharedPath does not exist" }

	cp "$custSharedPath/*" $sharedPath
	updatecustomer-buildsettings($cust)
	updatecustomer-portalthemes($cust)
}


function build-docs {
	$project = $pwd.path + "\j6.ndoc"
	$docs = $pwd.path + "\doc\api"
	if (!(test-path $docs)) { mkdir $docs }
	$pattern = "<property name=`"OutputDirectory`".+/>"
	$replace = "<property name=`"OutputDirectory`" value=`"$docs`" />"
	replace-in-file -file $project -pattern $pattern -replace $replace
	NDocConsole.exe "-project=$project"
}

function build-customsolutions {
	$path=("custommodules\{0}" -f (get-buildsettings).settings.customer)
	if(test-path $path){
		find-customsolutions $path|
		%{build-solutionsafe $_.FullName}
	}
}

function prepare-environment {
	build-init
	build-tools
	load-patches
	load-appsettings
	build-init
	update-assemblyversions (get-version)
	duplicate-shared-portal-folders
	build-solutions
}


function build-installers {

	#clean out any old installers
	rm -r -force -include *.msi,*.exe installers
	build-solutiondevenv (join-path "build" "installers.sln")

	# because we are using devenv instead of msbuild, we need
	# a way to determine if the build succeeded. So we check the
	# build directories to make sure the appropriate files are there
	# install directories should be in the form of install<type>
	(ls installers/install?*)|
	%{
		trap { log ("Error in $_") }
		Log "$_ $global:configuration"
		$pth=(join-path $_ $global:configuration)
		Log ("Verifying installer has been generated in {0}" -f $pth)
		assert-exists ($pth) "$pth does not exist"
		assert-exists (join-path $pth "*.msi") " No .msi file found for $_"
		assert-exists (join-path $pth "setup.exe") " No setup.exe file found for $_"
	}
}

function deploy-build {
	param(
		$theme="Default",
		$settings=((get-buildsettings).settings),
		$customer=($settings.customer),
		$basereleasedir = ($settings.configurations.releaseDirectory),
		$workingdir = ($settings.configurations.workingDirectory),
		$svnrepo = ("{0}/" -f [string]($settings.configurations.svnRepository).TrimEnd('/')),
		$version = (get-version $svnrepo)
	)

	$isDevelopmentBuild=$version.StartsWith("0.0.0");
	log "version info: $version developmentbuild $isDevelopmentBuild"

	$releaseFolder=("{0}\{1}-{2}" -f $basereleasedir,$version,$customer)
	log "Release Folder: $releaseFolder"

	if(-not(test-path $releaseFolder)){
		log-warning "$releaseFolder doesn't exist... creating"
		new-item -itemtype container -path $releaseFolder
	}

	pushd $workingdir

		log ("Current Dir: {0}" -f (pwd))
		if (test-path internalshared\releaseto.exe) {
			internalshared\releaseto $releaseFolder $isDevelopmentBuild
		} else {
			shared\releaseto $releaseFolder $isDevelopmentBuild
		}

		$reportFolder=join-path $releaseFolder "Reports"
		if(-not(test-path $reportFolder)){
			log "Create Reports folder in $releaseFolder"
			new-item -itemtype container -path $reportFolder
		}
		(ls -r -inc *.rdl ReportModule\Reports\Reports)|%{ cp $_.fullname $reportFolder }

		$customReports=join-path $releaseFolder "CustomReports"
		if(-not(test-path $customReports)){
			log "Create CustomReports folder in $releaseFolder"
			new-item -itemtype container -path $customReports
		}
		(ls -r -inc *.rdl CustomModules)|?{$_}|%{cp $_.fullname $customReports}

		$config=("{0}/Configuration/AppSettings" -f $svnrepo)
		log "exporting $config to $releaseFolder\AppSettings"
		exec-svn export --force $config $releaseFolder\AppSettings

		log "set theme: $theme"
		set-theme $theme
		set-employee-theme Employee
		export-customassets $releaseFolder

		# custom patches includes optional patches
		$custPatch = "data/CustomPatches/$customer"
		$relCustPatch = "$releaseFolder/CustomPatches"
		log "Copy $custPatch to $relCustPatch"
		cp -r $custPatch $relCustPatch

		log "Copy JOL files and folders"
		$jol=join-path $releaseFolder "JOL"
		mkdir $jol
		"Sites\Portal","Sites\employee-portal","Sites\services","Sites\Personal",
		"Configuration","Shared","log-settings.xml" | %{
			if(test-path $_) {
				$src=resolve-path $_
				$dst=(join-path $jol (split-path -leaf $src))
				log "copy $src to $dst"
				cp -r $src $dst
			}
		}

	popd #$workingdir
	cp sql-settings.xml $releaseFolder
	cp shared\log-settings.xml $releaseFolder
}

function update-webconfig {
	param(
		[string] $webconfig = "Sites\Employee-portal\web.config",
		[string] $server = "(local)",
		[string] $db = $(throw 'Enter the database name'),
		[string] $user,
		[string] $pass
	)

	if (Test-Path $webconfig)
	{
		if ($user) { $security = "uid=$user;pwd=$pass" }
		else { $security = "Integrated Security=" + ($user.trim().length -eq 0) }

		$connection = "Data Source=$server;Initial Catalog=$db;$security"
		$element = "<add name=`"J6ConnectionString`" connectionString=`"$connection`" providerName=`"System.Data.SqlClient`" />"
		$pattern = "<add name=`"J6ConnectionString.+/>"
		$old = gc $webconfig
		$new = $old -replace $pattern,$element
		set-content -path $webconfig $new
	}
}

function update-datamodule {
	param(
		[string] $file = "DataModule\datamodule-properties.csp",
		[string] $server = "(local)",
		[string] $db = $(throw 'Enter the database name'),
		[string] $user,
		[string] $pass
	)

	if ($user) { $security = "uid=$user;pwd=$pass" }
	else { $security = "Integrated Security=" + ($user.trim().length -eq 0) }
	$connection = "Data Source=$server;Initial Catalog=$db;$security"
	$element = "<connectionString>$connection</connectionString>"
	$pattern = "<connectionString>.+</connectionString>"
	$old = gc $file
	$new = $old -replace $pattern,$element
	set-content -path $file $new
}

function set-database {
	param(
		[string] $server = "(local)",
		[string] $db = $(throw 'Enter the database name'),
		[string] $user,
		[string] $pass
	)
	$build = get-buildsettings
	$build.settings.sql.server = $server
	$build.settings.sql.database = $db
	$build.settings.sql.uid = $user
	$build.settings.sql.pwd = $pass
	create-sqlsettings $server $db $user $pass
	#update-webconfig -server $server -db $db -user $user -pass $pass

	#$webconfig = "Site\Employee\web.config"
	#update-webconfig -webconfig $webconfig -server $server -db $db -user $user -pass $pass
	if (test-path DataModule) {
		update-datamodule -server $server -db $db -user $user -pass $pass
	}
	save-buildsettings $build
}

function get-database {
	$x = [xml](gc sql-settings.xml)
	$x.settings.sql
}

function set-loglevel{
	param([string]$level = $(throw "Must supply a log level (INFO, DEBUG, etc.)"))
	$fileName = "log-settings.xml"
	if (test-path shared\log-settings.xml) {
		$fileName = "shared\log-settings.xml"
	}
	$x = [xml](gc $fileName)
	$x.configuration.log4net.root.level.value = $level
	$x.Save($fileName)
}

function get-loglevel {
	$x = [xml](gc log-settings.xml)
	$x.configuration.log4net.root.level.value
}

function create-release-branch {
	param([string] $branch = $(throw "Enter a name for the branch"))
	$info = [xml](exec-svn info --xml)
	$url = $info.info.entry.url
	exec-svn copy "$url" "$url/branches/releases-j6/$branch"

	pushd EarningsModule
	& {
		trap {popd;throw $_}
		$info = [xml](svn.exe info --xml)
		$url = $info.info.entry.url
		svn.exe copy "$url" "$url/branches/releases/$branch"
	}
	popd
}

function new-branch {
	param([string] $branch = $(throw "Enter a name for the branch"))
	if (-not(test-path j6)) { $(throw "Must be at repo root") }
	hg branch $branch
	hg --cwd j6 branch $branch
	#dir CUST* | %{hg --cwd $_ branch $branch}
}

function set-theme {
	param([string]$theme = $(throw "Enter a theme name"))
	$pattern = "<pages theme=.+>"
	$element = "<pages theme=`"$theme`">"
	foreach($webconfig in $("sites\portal\web.config")) {
		replace-in-file -file $webconfig -pattern $pattern -replace $element
		$themePath = (join-path (split-path $webconfig) "App_Themes\$theme")
		$defPath = (join-path (split-path $themePath) "Default")
		if(-not(test-path $themePath)){
			cp -r $defPath $themePath
		}
	}
}

function set-employee-theme {
	param([string]$theme = $(throw "Enter a theme name"))
	$pattern = "<pages theme=.+>"
	$element = "<pages theme=`"$theme`">"
	foreach($webconfig in $("sites\employee-portal\web.config")) {
		replace-in-file -file $webconfig -pattern $pattern -replace $element
	}
}

function replace-in-file {
	param(
		[string]$file = $("Enter a file name"),
		[string] $pattern = $("Enter a pattern"),
		[string] $replace = $("Enter some replacement text")
	)
	$old = gc $file
	$new = $old -replace $pattern,$replace
	set-content -path $file $new
}

function reload-console { . .\dev.ps1 }

$j6modules = "Core","Genealogy","Earnings","Report","SalesOrder","Portal"

#Returns filename objects for all csproj files in the Module folders.
# see $j6modules for the list of folders traversed.
function get-project-files {
	$j6modules | foreach {
		$module = $_ + "Module"
		dir $module | ? {$_.Length -ne 0} | foreach {dir "$module\$_"} `
		| ? {$_.tostring().endswith(".csproj")} | % {$_.FullName}
	}
}

#Sets the OutputPath property for all configurations in the given project file.
function set-outputpath {
	param($file, [string]$output)
	$x = [xml](gc $file)
	$x.Project.PropertyGroup | ? {$_.OutputPath} | % {$_.OutputPath = $output}
	$x.Save($file)
}

#Ensure that every file in the bin folder of a website that also exists
#in shared has a refresh file.
function update-refreshes {
	foreach($f in (dir sites | % {dir ($_.fullname + "\bin")} | ? {$_.extension -eq ".dll"})) {
		$dll = $f.fullname
		log $dll
		#if (-not (test-path "$dll.refresh"))
		#{
			$name = $f.name
			"..\..\shared\$name" > "$dll.refresh"
		#}
	}
}

#deletes all DLLs out of the bin folders after first ensuring that
# there is a refresh file for each one.
function refresh-sites {
	update-refreshes
	foreach($site in (dir sites)) {
		$sitename = $site.fullname
		$bin = "$sitename\bin"
		del $bin\*.dll
		del $bin\*.pdb
	}
}

function build-projectswithlogger {
	param($projects, [bool]$clean)
	$projects|%{
		if($clean){build $_ 'Clean'}
		build $_ 'Build'
	}
}

function cleanbuild-j6 {
	$oldinteractive = $isInteractiveBuild
	Log "starting cleanbuild-j6"
	$settings = (get-buildsettings).settings
	$svnRepUrl = $settings.configurations.svnRepository

	$version = ""
	$void = remove-dir $buildLogDir
	$void = mkdir $buildLogDir
	$isInteractiveBuild = $false

	. validate-command {
			$version = get-version($svnRepUrl)
			if ($version -eq "") { throw "Unable to retrieve version information" }
		} "Unable to retrieve version information"

	Log("Version = $version")

	validate-command { duplicate-shared-portal-folders } "Unable to duplicate shared portals"
	validate-command { update-assemblyversions ($version) } "Unable to update assembly versions"

	prepare-features -working (pwd).path

	build-projectswithlogger $preLoadPatchBuilds $true

	validate-command { load-patches } "Unable to load patches"
	validate-command { load-appsettings } "Unable to load appsettings"
	if (test-path datamodule) {
		validate-command { generate-nettiers } "Unable to generate data module"
	}
	validate-command { update-assemblyversions ($version) } "Unable to update assembly versions"
	if (test-path datamodule) {
		validate-command { build-nettiers } "Unable to build nettiers"
	}

	build-projectswithlogger $postLoadPatchBuilds $true
	build-projectswithlogger $testBuilds $true

	validate-command { build-customsolutions } "Unable to build custom solutions"

	clean-webconfigs
	validate-command{ generate-webservice} "Unable to generate web service"

	build-projectswithlogger $webBuilds $true
	build-projectswithlogger $realtime $true
	build-projectswithlogger $sis $true

	Log ("rebuilt all projects")
	$isInteractiveBuild = $oldinteractive
}

function clean-webconfigs {
	# remove nunit assemblies
	(ls -r -include web.config)|
		?{(gc $_) -match "nunit"}|
		%{
			$x=[xml](gc $_)
			$x.configuration."system.web".compilation.assemblies.add|
				?{$_.assembly}|
				?{$_.assembly -match "nunit"}|
				%{
					$_.get_ParentNode().RemoveChild($_)
				}
			$x.Save($_.FullName)
		}
}

function export-customassets {
	param([string] $exportPath)
	$settings = (get-buildsettings).settings
	$customer = $settings.customer
	$svnRepository = $settings.configurations.svnRepository
	if(!($svnRepository.endsWith("/"))) { $svnRepository +="/"}
	log "exporting $svnRepository for customer $customer"
	$exports = @{
		"data/CustomPatches/{0}/Database.zip" = '';
		"CustomModules/{0}/Reports" = "$exportPath/CustomReports";
		"Configuration/CustomAppSettings/{0}" = "$exportPath/CustomAppSettings";
	}
	foreach ($key in $exports.keys) {
		$remote = $key -f $customer
		$remote = $svnRepository + $remote
		$local = $exports.item($key)
		log "exporting $remote to $local"
		exec-svn export $remote $local
	}
	export-customdlls ($exportPath + "/CustomDlls")
}

function export-customdlls {
	param([string] $exportPath, [string] $root = (get-root))
	if (-not (test-path $exportPath)) { mkdir $exportPath }
	$dlls = dir -r -include *.dll $root | ? { is-custom $_.name } | group -property Name
	foreach ($group in $dlls) {
		$d = $group.group | sort -property LastWriteTime -descending | select -first 1
		if ($d) { cp $d $exportPath }
	}
}

function create-patch {
	param(
		[string]$name = $(throw "enter a name for the patch"),
		[string]$category = $(throw "enter a category (e.g. Core, Genealogy, etc.)"),
		[string]$description = "[enter a description]"
	)
	if (-not ($name -match "^\d\d\d\d-\d\d-\d\d-")) {
		$name = (get-date -format "yyyy-MM-dd-") + $name
	}
	if (test-path data/patches) {
		$file = "data/patches/$category/patches/$name"
		if ($category -match "^(IH|CUST)[0-9]") {
			$file = "data/custompatches/$category/$name"
		}
	} else {
		$file = "$category/Patch/Install/$name"
	}
	if (!($file.tolower() -imatch ".(xml|sql)$")) {
		$file = $file + ".sql"
	}

	"--
-- $description
-- patch-date: $(get-isodate)

" > $file
	& $env:editor $file
	if (test-path .svn) { svn.exe add $file }
	else { hg.exe --cwd $category add ..\$file }
}

foreach($editor in "scite","vim","notepad","runemacs","notepadplus") {
	if (-not ($env:editor)) {
		if (gcm "$editor*") { $env:editor = $editor }
	}
}

function get-patch {
	param([string] $name, [string]$contents)
	if (test-path data) {
	    if ($contents) {
	        dir -r data -include $name |
	        ?{$_ -is [system.io.fileinfo] -and (gc $_.fullname) -match $contents }
	    } else {
	        dir -r data -include $name
	    }
	} else {
		if ($contents) {
			feature.exe list | % {dir "$_/patch" -r -include $name} | ? {$_ -is [system.io.fileinfo] -and (gc $_.fullname) -match $contents}
		} else {
			feature.exe list | % {dir "$_/patch" -r -include $name}
		}
	}
}

function edit-patch {
	param([string] $name, [string]$contents)
	get-patch $name $contents | % { & $env:editor $_.fullname }
}

function generate-md5 {
	param($cleartext)
	$bytes = (new-object System.Text.UTF8Encoding).GetBytes($cleartext)
	$hash = [System.Security.Cryptography.MD5]::Create().ComputeHash($bytes)
	[string]::Join("", ($hash | % {$_.ToString("x2")}))
}

set-alias -name md5 -value generate-md5

function clear-portalusers {
	en "delete from security.applicationuser"
	en "delete from security.portaluser"
}

function create-portalusers {
	en "INSERT INTO [Security].[PortalUser]
           ([Code]
           ,[Account]
           ,[AccountCode]
           ,[Password]
           ,[Hint]
           ,[Culture]
           ,[Active])
     select a.Code, a.Id, a.Code, '$(md5 test)', 'test', 'en-US', 1
     from genealogy.account a"

	en "INSERT INTO [Security].[ApplicationUser]
           ([PortalUser]
           ,[Application])
     select p.id, a.id
     from security.portaluser p, [application] a"
}

function fix-appthemes {
	rm -r -force sites\employee-portal\app_themes
	rm -r -force sites\portal\app_themes
	exec-svn update sites\portal
	exec-svn update sites\employee-portal
}

function get-columns {
	param([string]$table)
	er "select COLUMN_NAME as [NAME], ORDINAL_POSITION as [POS], COLUMN_DEFAULT as [DEFAULT], IS_NULLABLE as [NULL?],
                DATA_TYPE as [TYPE], CHARACTER_MAXIMUM_LENGTH as CHAR_LEN, CHARACTER_OCTET_LENGTH
                as OCT_LEN, NUMERIC_PRECISION as PREC, NUMERIC_SCALE as SCALE
        from information_schema.columns where upper(table_name) = upper('$table')" | ft -auto
}

function get-table {
	param([string] $table)
	er "select * from information_schema.tables where upper(table_name) like upper('$table')"
}

function generate-msbuild {
	param($solution)
	$env:msbuildemitsolution=1
	[void](msbuild $solution /t:ValidateSolutionConfiguration)
	rm env:\msbuildemitsolution
	$ret = "{0}.proj" -f $solution
	if(test-path $ret){return resolve-path $ret}
}

function exclude-project {
	param($msproj,$exclude)
	$msproj = resolve-path $msproj
	$proj = [xml](gc $msproj)
	$proj.Project.Target |
		?{$_.MSBuild -and 0 -lt ($_.MSBuild|?{$_.Projects -match $exclude}).Count} |
		%{
			$targetName=$_.Name
			$proj.Project.Target|?{$_.CallTarget}|%{
				$_.CallTarget.Targets = [string]::Join(';',($_.CallTarget.Targets.Split(';')|?{-not ($_ -eq $targetName)}));
			}
		}
	$proj.Save($msproj)
}






function init-j6 {
	param(
		$buildsettings = (get-buildsettings),
		$server = $buildsettings.settings.sql.server,
		$db = $buildsettings.settings.sql.database,
		$user = $buildsettings.settings.sql.uid,
		$pass = $buildsettings.settings.sql.pwd,
		$customer = $buildsettings.settings.customer,
		$tiers = $buildsettings.settings.configurations.remoteTiersDirectory,
		$remote = $buildsettings.settings.configurations.dbDirAsRemote,
		$local = $buildsettings.settings.configurations.dbDirAsLocal,
		$buildsettingsdir = $(find-file "./" "Build-Settings.xml")
	)

	$usage = @"

Notes:

  '<>' signifies no default value, and '<asdf>' signifies 'asdf' is the default
  for this parameter if it is not passed in or if it isn't set in the settings
  file.

  All of the options are optional and if not specified the existing values will
  be retained.


Parameters and common usages:

	-server <parrot> -db <> -user <sqluser> -pass <j0l4n0w!>
	-customer <> -tiers <> -local <e:\databases> -remote <\\parrot\databases>


"@

	if($args|?{$_ -match "-h"}){$usage;return}
	if(-not $server){$server="parrot"}
	if(-not $user){$user="sqluser"}
	if(-not $pass){$pass="j0l4n0w!"}
	if(-not $remote){$remote="\\parrot\databases"}
	if(-not $local){$local="e:\databases"}

	build-init
	build-tools
	if(-not (test-path $buildsettingsdir)){
		cp (join-path (pwd) "build-settings-template.xml") $buildsettingsdir
	}
	set-database -server $server -db $db -user $user -pass $pass
	$bs = [xml](gc $buildsettingsdir)
	$bs.settings.customer = $customer
	$bs.settings.configurations.remoteTiersDirectory = $tiers
	$bs.settings.configurations.dbDirAsRemote = $remote
	$bs.settings.configurations.dbDirAsLocal = $local
	$bs.Save($buildsettingsdir)
	duplicate-shared-portal-folders
}

$coverage_exclude = ".*ReportingServices.*;.*Core.Entities.*;.*\.Properties"

function build-ncover {
	param ($assembly)
	$assemblyInfo = (dir $assembly)
	$assemblyFile = $assemblyInfo.fullname
	$assemblyName = $assemblyInfo.name
	if (!(test-path Coverage)) {mkdir Coverage}
	if (!(test-path Coverage\UnitTest)) {mkdir Coverage\UnitTest}
	if (!(test-path Coverage\DataTest)) {mkdir Coverage\DataTest}
	$coverageFile = "Coverage\$assemblyName.coverage.xml"
	ncover.console.exe //x $coverageFile //et $coverage_exclude internalshared/xunit.console.exe $assemblyFile
}

function build-unittestcoverage {
	dir internalshared -r -include *.unittest*dll | % {build-ncover $_.fullname}
}

function build-datatestcoverage {
	dir internalshared -r -include *.datatest*dll | % {build-ncover $_.fullname}
}

function build-coveragereport {
	ncoverexplorer.console.exe Coverage\*unittest*.coverage.xml /s:Coverage\ncover-merged-unit.xml /r:FullCoverageReport /h:Coverage\UnitTest\index.html /p:"j6 Unit Tests"
	ncoverexplorer.console.exe Coverage\*datatest*.coverage.xml /s:Coverage\ncover-merged-data.xml /r:FullCoverageReport /h:Coverage\DataTest\index.html /p:"j6 Data Tests"
	ncoverexplorer.console.exe Coverage\*.coverage.xml /s:Coverage\ncover-merged.xml /r:FullCoverageReport /h:Coverage\index.html /p:"j6 Combined Tests"
}

function build-coverage {
	build-unittestcoverage
	build-datatestcoverage
	build-coveragereport
}

function get-projects([string]$startDir = (get-location).path) {
	dir $startDir -r -include *.csproj |?{ !($_.fullname -match "Attic")}
}

function get-features([string]$startDir = (get-location).path) {
	dir $startDir -r -include Feature.xml
}

function get-uppath($path, $levelsUp) {
	for($i = 0; $i -lt $levelsUp; $i++) {
		$path = split-path -parent -path $path
	}
	$path
}

function get-projectsxml([string]$startDir = (get-location).path) {
	get-projects $startDir | % {
		$xml = [xml](gc $_.fullname)
		$path = $_.fullname
		$o = new-object psobject
		add-member -in $o -name "xml" -memberType noteproperty -value $xml
		add-member -in $o -name "path" -memberType noteproperty -value $path
		if ($path -match "Feature\\(\w+)\\") {
				add-member -in $o -name "feature" -memberType noteproperty -value $matches[1]
				$featurePath = get-uppath $path 3
				add-member -in $o -name "featurepath" -memberType noteproperty -value $featurePath
		} else {
				add-member -in $o -name "feature" -memberType noteproperty -value $null
				add-member -in $o -name "featurepath" -memberType noteproperty -value $null
		}
		$matches = $null
		$o
	}
}

function get-featuresxml([string]$startDir = (get-location).path) {
	get-features $startDir | % {
		$xml = [xml](gc $_.fullname)
		$path = $_.fullname
		$o = new-object psobject
		add-member -in $o -name "xml" -memberType noteproperty -value $xml
		add-member -in $o -name "path" -memberType noteproperty -value $path
		add-member -in $o -name "projects" -memberType noteproperty -value (get-projectsxml "$path\..")
		add-member -in $o -name "name" -memberType noteproperty -value (get-featurefrompath $path)
		$o
	}
}

function get-assemblyname($project) {
	if ($project.xml.project.propertygroup) {
		$project.xml.project.propertygroup[0].assemblyname
	} else {
		$null
	}
}

function standardize-projects($featurePath = (get-location)) {
	$projects = get-projectsxml $featurePath
	if (!$projects) { return }
	$allProjects = get-projectsxml $featurePath\..
	foreach ($p in $projects) {
		$internal = is-internal $p
		if ($internal) {
			set-outputpath $p "..\..\Assembly"
			set-documentpath $p "..\..\Assembly"
		} else {
			set-outputpath $p "..\..\..\Assembly"
			set-documentpath $p "..\..\..\Assembly"
		}
		set-assemblyversionpath $p "..\..\AssemblyVersion.cs"
		set-interfeature-references $p $projects $allProjects
		write-project $p
		#TODO: Figure out how to avoid this next bit
		$text = gc $p.path
		($text -replace "xmlns=`"`"","") | out-file -filePath $p.path -encoding "UTF8"
	}
}

function write-project($project, $path = $project.path) {
	if ($project.xml.xml -eq $null) {
		$decl = $project.xml.createxmldeclaration("1.0", "utf-8", "yes");
		$project.xml.insertbefore($decl, $project.xml.project)
	}
	$project.xml.get_firstchild().set_encoding('utf-8')
	$project.xml.save($path)
}

function generate-referencesection($project, $allProjects) {
	$references = get-references($project)
	if ($references) {
		$referenceAssemblies = $references | % { get-referenceassembly $_ }
		$referenceProjects = $referenceAssemblies | % { find-project $allProjects $_ }
		if ($referenceProjects) {
			"ProjectSection(ProjectDependencies) = postProject`r`n"
			$referenceProjects | % { $guid = get-projectguid $_; "    $guid = $guid`r`n"}
			"EndProjectSection`r`n"
		}
	}
}

function generate-projectsection($guid, $project, $allProjects) {
	$name = get-assemblyname($project)
	$projectguid = get-projectguid($project)
	$path = $project.path
	$references = generate-referencesection $project $allProjects
	"Project(`"{$guid}`") = `"$name`", `"$path`", `"$projectguid`"
	$references
EndProject"
}

function generate-solution {
	$projects = get-projectsxml
	$projectsguid = [guid]::newguid().tostring()
	$foldersguid = [guid]::newguid().tostring()
	#$featureGuids = @{}
	#dir Feature | % { $featureGuids[$_.name] = [guid]::newguid().tostring() }
"Microsoft Visual Studio Solution File, Format Version 10.00
# Visual Studio 2008"
	#dir Feature | % { $name = "Feature_" + $_.name; $itemGuid = $featureGuids[$_.name]; `
	#	"Project(`"$foldersguid`") = `"$name`", `"$name`", `"{$itemGuid}`"
#EndProject
#"}
	$projects | % { generate-projectsection $projectsguid $_ $projects }
"Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|.NET = Debug|.NET
		Debug|Any CPU = Debug|Any CPU
		Debug|Mixed Platforms = Debug|Mixed Platforms
		DebugLocal|.NET = DebugLocal|.NET
		DebugLocal|Any CPU = DebugLocal|Any CPU
		DebugLocal|Mixed Platforms = DebugLocal|Mixed Platforms
		Production|.NET = Production|.NET
		Production|Any CPU = Production|Any CPU
		Production|Mixed Platforms = Production|Mixed Platforms
		Release|.NET = Release|.NET
		Release|Any CPU = Release|Any CPU
		Release|Mixed Platforms = Release|Mixed Platforms
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
	GlobalSection(NestedProjects) = preSolution
"
	#$projects | ? {$_.Feature} | % { $guid = get-projectguid $_; $feature = $featureGuids[$_.feature]; "    $guid = {$feature}"}
"	EndGlobalSection
EndGlobal"
}

function get-projectguid($project) {
	if ($project.xml.project.propertygroup) {
		$project.xml.project.propertygroup[0].projectguid
	} else {
		$null
	}
}

function get-references($project) {
	if ($project.xml.project.itemgroup) {
		$project.xml.project.itemgroup[0].reference
	} else {
		$null
	}
}
function change-customer {
	param($Customer)
	$build = get-buildsettings
	$build.settings.customer = $Customer
	save-buildsettings $build
	j6 console $Customer -2008
}

function get-referenceassembly($reference) {
	if ($reference.include) {
		$reference.include.split(",")[0]
	} else {
		$null
	}
}

function find-project($projects, $assemblyName, $guid) {
	$projects | ? { (( get-assemblyname $_) -eq $assemblyName) -or ((get-projectguid $_) -eq $guid) }
}

function set-credential{
	param([string] $credenttial)

	if(-not $credenttial){
		log-error "... credential not specified."
		return
	}

	$searchString = "http://";

	foreach($folder in dir(location)){
		$file = $folder.Name + "\.hg\hgrc"

		if( test-path $file) {
			$content = get-content($file)
			$startIndex = $content[1].indexOf($searchString) + $searchString.length
			$endIndex = $content[1].LastIndexOf("@")
			$substring = $content[1].subString($startIndex, $endIndex - $startIndex)
			log("previous content: " + $content[1])
			$content[1] = $content[1].replace($substring, $credenttial)
			log("content cheng to: " + $content[1])
			set-content -path $file $content
		}
	}
}

function set-sprintrepo{
	param([string] $newSprint)

	if(-not $newSprint){
		log-error "... new sprint name not provided."
		return
	}

	$searchString = "/hg/hgwebdir.cgi/feature/branches/";

	foreach($folder in dir(location)){
		$file = $folder.Name + "\.hg\hgrc"

		if( test-path $file) {
			$content = get-content($file)
			$startIndex = $content[1].indexOf($searchString) + $searchString.length
			$endIndex = $content[1].LastIndexOf("/")
			$substring = $content[1].subString($startIndex, $endIndex - $startIndex)
			log("previous content: " + $content[1])
			$content[1] = $content[1].replace($substring, $newSprint)
			log("content changed to: " + $content[1])
			set-content -path $file $content
		}
	}
}


function create-sprintscript($oldbranch, $newbranch) {
    "# don't forget to sudo -u apache bash"
	"mkdir $newbranch"
	"cd $newbranch"
	feature list | % {[system.io.directoryinfo] $_ } `
		| % { $n = $_.name;
				"hg clone ../$oldbranch/$n"
				"cat ../../../hgrc $n/.hg/hgrc > temp"
				"mv temp $n/.hg/hgrc" }
}

function read-hglogentry {
	begin {
		$entry = $null
		$diff = $false
		$description = $false
		$descbuf = ""
		$diffbuf = ""
	}
	process {
		if ($_ -match "^changeset:") {
			if ($entry) {
				$entry
			}
			$entry = new-object psobject
			$diff = $false
			$description = $false
			$descbuf = ""
			$diffbuf = ""
			$property = $false
		}
		if ($_ -match "^(\w+):\s*(.+)") {
			$property = $true
			if ($matches[1] -eq "date") {
				$entry = add-member -pass -in $entry -name $matches[1] -force -memberType noteproperty -value ([datetime]$matches[2])
			} else {
				$entry = add-member -pass -in $entry -name $matches[1] -force -memberType noteproperty -value $matches[2]
			}
		} elseif ($_ -match "^description:") {
			$property = $false
			$description = $true
			$entry = add-member -pass -in $entry -name description -memberType noteproperty -value ""
		} elseif ((!($diff)) -and ($_ -match "^diff -r")) {
			$property = $false
			$description = $false
			$diff = $true
			$entry = add-member -pass -in $entry -name diff -memberType noteproperty -value ""
		}
		if ($description) {
			$entry.description += ($_ + "`n")
		} elseif ($diff) {
			$entry.diff += ($_ + "`n")
		}
	}
	end {
		if ($entry) {
			$entry
		}
	}
}

function hg-info($command, $command_args, $working_dir = ".") {
	$url = (gc ($working_dir + "\.hg\hgrc")) | ? {$_ -match "http://.+"}
	$url = $url -replace "//(.+):(.+)@","//"
	$url = $url -replace ".+http","http"
	$repo_url = $url
	$command_args = $command_args | ? {$true}
	$feature_name = ([xml](gc ($working_dir + "\Feature.xml"))).Feature.Name
	$template = "changeset:   {rev}:{node}
rev:         {rev}
node:        {node}
tag:         {tip}
user:        {author}
date:        {date|isodate}
summary:     {desc}
files:       {files}
adds:        {file_adds}
deletes:     {file_dels}
mods:        {file_mods}
feature:     $feature_name
directory:   $directory
repo_url:    $repo_url
change_url:  $repo_url/rev/{node}
"
	hg --cwd $working_dir $command $command_args --template $template | read-hglogentry
}

function feature-listhg($command) {
	$command_args = $args | ? {$true}
	feature list | % { $directory = [system.io.directoryinfo]$_; hg-info $command $command_args $_}
}

function feature-log() {
	feature-listhg "log" $args
}

function get-fieldasdiv($entry, $field, $transform = $null) {
	$value = invoke-expression ('$entry.' + $field)
	if ($transform) { $value = & $transform $value }
	make-fielddiv $field $value
}

function make-fielddiv($field, $value) {
	"<div class='$field'>
				<span class = 'label'>$field</span>
				<span class = 'value'>$value</span>
			</div>
	"
}

function create-hgreport() {
	begin {
		$even = "even"
		"<html>
			<head>
			<style type='text/css'>
				<!--
					@media print {
					.log { border: 1px solid grey;
						width: 100%;
						padding-top: 0.5em;
						padding-bottom:0.2em;
					}
					}
					@media screen {
					.log { border: 1px solid grey;
						width: 60%;
						margin-left:10%;
						padding-left:0.5em;
						padding-top: 0.5em;
						padding-bottom:0.2em;
					}
					}
					.label { font-weight:bold;
							 width: 30%
							}
					.value { font-family:consolas,courier,monospaced;
						width:70%
					}
					div.summary {
						font-family:Verdana;
						font-size:90%;
						padding-bottom:0.4em;
						padding-left:1em;
					}
					div.files {
						font-size:70%;
						padding-left:0.2em;
					}
					td { padding-right:2em; white-space:nowrap; font-size:90%;}
					td.changeset { font-size:80%; }
					.feature { font-weight:bold; font-variant:small-caps;font-size:110%;}
					.odd { background-color:#F3F3F3; }
				-->
			</style>
			<head>
		<body>"
	}
	process {
		# $(get-fieldasdiv $_ 'directory' (gcm make-filehref))
		"<div class='log $($even)'>

			<table>
			<tbody>
			<tr>
				<td class='feature'>$($_.feature)</td>
				<td>$($_.user)</td>
				<td>$($_.date)</td>
				<td class='changeset'><a href='$($_.change_url)'>$($_.changeset)</a></td>
			</tr>
			</tbody>
			</table>
			<div class='summary'>$($_.summary)</div>
			<div class='files'>$($_.files)</div>
		</div>"
		if ($even -eq "even") {$even = "odd"} else {$even = "even" }
	}
	end {
		"</body>
		</html>"
	}
}

function get-incomingreport() {
	feature-listhg incoming | create-hgreport
}
function get-outgoingreport() {
	feature-listhg outgoing | create-hgreport
}


function make-diffhrefs($entry) {
	$names = $entry.files.split(' ')
	$refs = $names | % { "<a href='javascript:runprogram(`"hg.exe diff -r $($entry.rev) -r $($entry.rev - 1) -I $($entry.directory + '\' + $_)`")'>$_</a>" }
	$refs
}

function make-filehref([system.io.fileinfo]$fileinfo) {
	"<a href='file:///$($fileinfo.fullname)'>$($fileinfo.fullname)</a>"
}

function extract-diff($text) {
	begin {
		$in =$false
	}
	process {
		if ($in) { $_ + "`n"}
		elseif ($_ -match "^diff -r") { $in = $true }
	}
}

function format-filerev($entry, $file, $type) {
	"FORMAT: e: $entry f: $file t: $type"
		$dir = $entry.directory
		$diff = hg --cwd $dir log -p -I $file -r ($entry.rev) | extract-diff | % { $_ -replace "'","''"}

		"IF NOT EXISTS (SELECT * FROM Dev.RevisionFile WHERE Revision = (SELECT Id FROM Dev.Revision WHERE Code = '$($entry.node)')
							AND Name = '$file')
			INSERT Dev.RevisionFile (Revision, Name, ChangeType, Diff)
			SELECT r.Id, '$file', 'A', '$diff'
			FROM Dev.Revision WHERE Code = '$($entry.node)'
			"
}

function convert-entrytosql($entry) {
	switch -regex ($entry.user) {
		'csd' { $user = 'csd' }
		'bryn' { $user = 'brk' }
		'jim' { $user = 'jhb' }
		default {
			$user = $entry.user
		}
	}
	$branch = '<unknown>'
	if ($entry.repo_url -match "/branches/(\w+)/") {
		$branch = $matches[1]
	} elseif ($entry.repo_url -match "/releases/(\w+)/") {
		$branch = $matches[1]
	}
	$adds = $dels = $mods = $null
	if ($entry.adds) { $adds = $entry.adds.split(' ') | % { format-filerev $entry $_ 'A' } }
	if ($entry.dels) { $dels = $entry.dels.split(' ') | % { format-filerev $entry $_ 'D' } }
	if ($entry.mods) { $mods = $entry.mods.split(' ') | % { format-filerev $entry $_ 'M' } }
	"IF NOT EXISTS (SELECT * FROM Dev.Revision WHERE Code = '$($entry.node)')
	BEGIN
		INSERT Dev.Revision(Code, [User], Feature, Branch, ChangeUrl, RevisionDate, Entity)
		 SELECT '$($entry.node)', u.Id, '$($entry.feature)', '$branch', '$($entry.change_url)', '$($entry.date)', newid()
			FROM Security.[User] u WHERE u.Code = '$user'
		$adds
		$dels
		$mods
	END"
}


function search-files([string]$pattern,
	[system.io.directoryinfo]$directory = (pwd).path,
	$include = "*.*"
) {
	dir -r $directory -include $include | ? { $_ -is [system.io.fileinfo] -and ((gc $_.fullname) -match $pattern) }
}

function shelve-workspace {
	feature cleanjunctions
	feature clean
	dir -r . -include *.dll,*.pdb,*.obj | % {rm $_}
	feature do hg update null
}

function unshelve-workspace {
	dir | ? {$_ -is [system.io.directoryinfo]} | % { hg --cwd $_.fullname update }
}

function create-workspace(
	[string] $folder = $(read-host -prompt "folder to create"),
	[string] $repoPath = $(read-host -prompt "repo path (default: branches/sprint)"),
	[string] $driverFeature = $(if (!($driverFeature = read-host -prompt "driver feature (default: SPRINT)")) { "SPRINT" } else { $driverFeature }),
	[string] $server = $(read-host -prompt "database server (default: starling)"),
	[string] $dbname = $(read-host -prompt ("database name (default: " + ($env:username).ToUpper() + "-" + $driverFeature + "-DEV" + ")")),
	[string] $user = $(read-host -prompt "database user (default: sqluser)"),
	[string] $pass = $(read-host -prompt "database password (default: j0l4n0w!)"),
	[string] $repoBase = 'http://source.jenkon.com/hg/hgwebdir.cgi/feature',
	[switch] $engine,
	[string] $engineUrl = $(if ($engine) { read-host -prompt "url for engine code" } else {$null})
	)
{
	trap [Exception] {
      write-host "Error: $($_.Exception.Message)"
      break
   }
	if (!($repoPath)) { $repoPath = "branches/sprint"}
	if (!($driverFeature)) { $driverFeature = "SPRINT"}
	mkdir $folder
	cd $folder
	"hg clone $repoBase/$repoPath/$driverFeature"
	hg clone "$repoBase/$repoPath/$driverFeature"
	if ($engine) {
		"hg clone $engineUrl EngineCore"
		hg clone $engineUrl EngineCore
	}
	feature fetch
	"Copying log-settings.xml from Core/shared"
	cp Core/shared/log-settings.xml
	"Creating build-settings.xml"
	create-buildsettings
	if (!$dbname) {
		$dbname = ($env:username).ToUpper() + "-" + $driverFeature + "-DEV"
	}
	if (!$server) { $server = "starling" }
	if (!$user) { $user = "sqluser" }
	if (!$pass) { $pass = "j0l4n0w!" }
	set-database -db $dbname -server $server -user $user -pass $pass
	get-database
	recreate-database
	feature setup
	feature build
}

function recreate-database {
	$info =(get-database)
	$db = $info.database
	if (!($db -match "\-dev$")) { throw "$db is not a dev database" }
	$server = $info.server
	$user = $info.uid
	$pass = $info.pwd
	set-database -server $server -db master -user $user -pass $pass
	en "DROP DATABASE [$db]"
	en "CREATE DATABASE [$db]"
	set-database -server $server -db $db -user $user -pass $pass
	if (test-path core\boot\feature.exe) {
		core\boot\feature.exe install --patch --verbose
	} else {
		feature install --patch --verbose
	}
}


function jslint($file) {
	$lint = $env:buildscripts + "jslint.js"
	$cscript = $env:buildscripts + "jslint.bat"
	if ($file) {
		& $cscript $lint $file
	} else {
		feature list | % { dir $_ -r -include *.js } `
			| ? { !($_.fullname -match "(YUI|PrecompiledWeb)") } `
			| % { $name = $_.fullname; "Checking " + $_.fullname; $name = $_.fullname; & $cscript $lint $name }
	}
}

function netdiff {
	begin {
		$total = 0
	}
	process {
		if ($_ -and $_.startswith("+")) { $total++}
		elseif ($_ -and $_.startswith("-")) {$total--}
	}
	end {
		$total
	}
}

function summarize-code([switch] $summarize) {
	if (!$summarize) {
		$d = $env:buildscripts
		feature list | % { $fn = $_.split("\")[-1]; cloc "--read-lang-def=$d\cloc.def" "--ignored=$fn.ignored.txt" "--not-match-f=Transactional\.cs" "--report-file=$fn.cloc" "--exclude-dir=YUI,bin,Bin,Assembly,obj,PrecompiledWeb,Build,ClientBin,.hg,Lib,Attic,Web References,Service References" $fn}
	}
	$names = feature list | % { $_.split('\')[-1] + ".cloc"}
	$t = [string]::join(" ", $names)
	$cmd = "cloc --sum-reports --csv $t"
	$summary = invoke-expression $cmd
	out-file -filepath summary.csv -inputObject $summary -encoding ASCII
}

function show-issue([string]$issue) {
	start "http://redmine.jenkon.com/issues/show/$issue"
}

function incoming-from([string]$url) {
	f list --name | % {hg --cwd $_ in $url/$_}
}

function pull-from([string]$url) {
	f list --name | % {hg --cwd $_ pull -u $url/$_}
}

new-alias f core\boot\feature.exe

function get-customer([string]$driver = $(throw "enter a driver feature"),
			[string]$base = $(throw "enter a base (like releases://7.4.1 or branches://sprint")
		)
{
	hg clone $base/Core
	msbuild /t:Bootstrap Core/Feature.proj
	copy core\shared\log-settings.xml
	core\boot\feature.exe config sql server db user pass
	copy sql-settings.xml build-settings.xml
	set-database server db user pass
	msbuild /t:Bootstrap Core/Feature.proj
	hg clone "$base/$driver"
	core\boot\feature.exe fetch

}

function get-changesets() {
	$features = dir . | ? {test-path "$_\Feature.xml"} | % { $_.name}
	$features | % {
		$n = $_;
		$x = [xml](gc $n\Feature.xml);
		$fn = $x.feature.name
		$change = $x.feature.sourceidentifiers.sourceidentifier;
		[void]($change -match 'changeset:.+:([a-f0-9]+)');
		"$fn $($matches[1])"
	}
}

function set-changesets() {
	process {
		if ($_ -match "(\w+) ([a-f0-9]+)") {
			"$($matches[1])"
			hg --cwd $matches[1] update -r $matches[2]
		}
	}
}

function get-changesetssince() {
	process {
		if ($_ -match "(\w+) ([a-f0-9]+)") {
			"$($matches[1])"
			hg-info "log" "-r $($matches[2]):tip" $matches[1] `
				| select -skip 1 `
				| ? {$_}
		}
	}
}

function create-incomingreport($repodir, $reportname = "report.html") {
	f list --name | % {hg-info incoming "$repodir/$_" $_} | create-hgreport > $reportname
	"Wrote report to $reportname"
}

set-alias iisexpress "c:\program files (x86)\iis express\iisexpress"

function j([string]$command = "build") {
	$rest = [string]::join(" ", $args)
	msbuild /nologo /t:$command $rest j6.proj
}

function hgpb () {
	$branchname = hg branch
	hg pull -b $branchname -u
}

function hgib () {
	$branchname = hg branch
	hg incoming -b $branchname
}
