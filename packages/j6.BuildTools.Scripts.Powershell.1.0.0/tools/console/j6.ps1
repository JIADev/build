set-psdebug -strict

##
## Begin Execution
##

## set Window Title
(get-host).UI.RawUI.WindowTitle = "J6 $Args"


$env:BuildScripts = (split-path $MyInvocation.MyCommand.Definition)

"BuildScripts: $($env:BuildScripts)"

$env:Path += (";{0};{1}" -f $env:BuildScripts,(join-path $env:BuildScripts "scripts"))

## register the jenkon PSSnapIn if it hasn't been registered.
if(-not(get-pssnapin -Registered | ?{ $_.Name -match "Jenkon"})){
	$script:InstallUtil = (join-path (join-path $env:SystemRoot "Microsoft.NET\Framework\v2.0.50727") "InstallUtil.exe")
	$script:SnapIns = (join-path $env:BuildScripts "SnapIns.dll")
	if((test-path $script:InstallUtil) -and (test-path $script:SnapIns)){
		& "$script:InstallUtil" $script:SnapIns
	}
}

## load the jenkon PSSnapIn
$script:loaded = [string]::Join(",",(get-pssnapin|%{$_.Name}))
get-pssnapin -Registered |
	?{-not($script:loaded -match $_.Name)} |
	add-pssnapin



## load env variables for visual studio
## LOAD VS variables

function load-vcvars {
	param(
		$vsver = "11.0",
		$vscpu = "",
		$vsfolder = "Microsoft Visual Studio {0}\VC",
		$vsparent = "Program Files{0}",
		$vsdrive = "C:\",
		$vsargs = "x86"
	)
	$vsfolder = ($vsfolder -f $vsver)
	$vsparent = ($vsparent -f $vscpu)
	$vs = join-path (join-path $vsdrive $vsparent) $vsfolder
	$vc = join-path $vs "\vcvarsall.bat"
	if(test-path $vc) {
		#Set environment variables for Visual Studio Command Prompt
		pushd $vs
		cmd /c "vcvarsall.bat&set" |
			foreach {
			  if ($_ -match "=") {
				$v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
			  }
			}
		popd
		write-host ("`nVisual Studio {0} Command Prompt variables set." -f $vsver) -ForegroundColor Cyan
	}
	if($vsver = "14.0")
	{
		$env:Path += (";{0}{1}\MSBuild\{2}\bin;{0}{1}\{3}" -f $vsdrive, $vsparent, $vsver, $vsfolder)
	}
}
function load-visualstudio {
	param($vsver = "11.0")
	[System.IO.DriveInfo]::GetDrives() | ?{ $_.DriveType -eq "Fixed" } | %{
		$drive = $_.Name
		""," (x86)" | %{ load-vcvars -vsver $vsver -vscpu $_ -vsdrive $drive }
	}
}
function load-vs2015 { load-visualstudio -vsver "14.0" }
function load-vs2012 { load-visualstudio -vsver "11.0" }
function load-vs2010 { load-visualstudio -vsver "10.0" }
function load-vs2008 { load-visualstudio -vsver "9.0" }
function load-vs2005 { load-visualstudio -vsver "8" }


if ($args -contains "-2005") { load-vs2005 }
elseif ($args -contains "-2008") { load-vs2008 }
elseif ($args -contains "-2010") { load-vs2010 }
elseif ($args -contains "-2015") { load-vs2015 }
else { load-vs2012 }


## function in jenkon PSSnapIn for cleaning up $env:Path
# clean-path





##
## helper functions
##

. core.ps1
#if (gcm svn.exe*) {
 #. subversion.ps1
#}

###
### SWITCH COMMAND functions
###

function build-debug {
	param($config)
	. bootstrap.ps1
	build-j6debug
}

function featurebuild-debug {
	param($config)
	. featurebuild.ps1
	buildfeature
}

function run-tests {
	param($config)
	. runtests.ps1
	run-tests
	if (gcm ndepend.console.*) {
		build-ndepend
	}
}

function run-feature-tests {
	param($config)
	. runtests.ps1
	run-feature-tests
	#if (gcm ndepend.console.*) {
	#	build-ndepend
	#}
}

function run-autodeploy {
	param($config)
	. deployments.ps1
	deploy-all $script:customer
}

function featurerun-autodeploy {
	param($config)
	. featurebuild.ps1
	deployfeature
}

function featurerelase-release {
	param($config,
		  $buildBitType = "-32bit"
		  )
	. featurebuild.ps1

	buildfeature

	releasefeature
}

function build-coverage
{
	param($config)
	. build.ps1
	pushd (get-releasedirectory)
	build-coverage
	popd
}

function build-release {
	param($config)

	$global:configuration="Release"

	log "RELEASE BUILD STARTING"
	. build-release.ps1
	build-j6release -config $config
	log "RELEASE BUILD COMPLETE"

	log "DEPLOY PROCESS STARTING"
	. build.ps1
	deploy-build "Default" -settings $config.settings
	log "DEPLOY PROCESS COMPLETE"
}

function build-deployrelease {
	param($config)

	$global:configuration="Release"

	log "DEPLOY PROCESS STARTING"
	. build.ps1
	deploy-build "Default" -settings $config.settings
	log "DEPLOY PROCESS COMPLETE"
}



###
### SWITCH COMMAND workhorse (common functions between options)
###

function build-configuration {
	param(
		$config = $(get-debugconfig $script:customer),
		$buildcommand = "build-debug",
		$clean = $config.settings.configurations.clean
	)

	$buildroot=get-builddirectory -config $config

	log "begin build"

	if($clean) {
		if(test-path $buildroot) {
			warn "removing $buildroot"
			rm -r -fo $buildroot
		}
	}
	if(-not(test-path $buildroot)) {
		log "creating $buildroot"
		mkdir $buildroot
	}


	#
	# Build-Settings.xml and Sql-Settings.xml
	#
	$ss = (join-path $buildroot "Build-Settings.xml"),(join-path $buildroot "Sql-Settings.xml")

	if($clean -or ("run-autodeploy","run-tests" -match $buildcommand))
	{$ss|?{test-path $_}|%{
		warn "removing $_"
		rm -fo $_
	}}

	$ss|?{-not(test-path $_)}|%{
		log "creating $_"
		$config.Save($_)
	}

	#
	# Go to build root and initiate command
	#
	pushd $buildroot
	log ("Current Directory: {0} " -f (pwd))
	& {
		trap{
			error $_.Exception.Message
			popd
			throw $_
		}
		& $buildcommand $config $buildBitType
		if(-not $?){throw ("{0} failed with error {1}" -f $buildcommand,$error)}
	}
	popd
}








$script:command = "console"
$script:customer = "IH00000"
if (gcm get-hostconfig*) {
	$hostconfig = (get-hostconfig).config
}
$buildBitType = "-32bit"

if($Args.Length -gt 0){$script:command = $Args[0]}
if($Args.Length -gt 1){$script:customer = $Args[1]}
if($args -contains "-64bit") {$buildBitType = "-64bit"}

if(-not $env:J6LOGFILE){
	$env:J6LOGFILE=[string](join-path (pwd) ("{0}-{1}-build-log.txt" -f $script:command,$script:customer))
	debug ("Logfile: {0}" -f $env:J6LOGFILE)
}

debug ("Beginning {0} for {1}" -f $script:command,$script:customer)

## process args
switch($script:command){

	{$_ -eq "build"}
	{
		build-configuration `
			-buildcommand "build-debug" `
		   -config (get-debugconfig $script:customer)
		exit 0
	}

	{$_ -eq "featurebuild"}
	{
		build-configuration `
			-buildcommand "featurebuild-debug" `
		     -clean $false -config (get-debugconfig $script:customer)
	}



	{$_ -eq "tests"}
	{
		build-configuration `
			-buildcommand "run-tests" `
		   -clean $false -config (get-debugconfig $script:customer)
		exit 0
	}

	{$_ -eq "featuretests"}
	{
		build-configuration `
			-buildcommand "run-feature-tests" `
		   -clean $false -config (get-debugconfig $script:customer)
	}

	{$_ -eq "coverage"}
	{
		build-configuration `
			-buildcommand "build-coverage" `
		   -clean $false -config (get-debugconfig $script:customer)
		exit 0
	}

	{$_ -eq "deploy"}
	{
		build-configuration `
			-buildcommand "run-autodeploy" `
		   -clean $false -config (get-debugconfig $script:customer)
		exit 0
	}

	{$_ -eq "featuredeploy"}
	{
		build-configuration `
			-buildcommand "featurerun-autodeploy" `
		   -clean $false -config (get-releaseconfig $script:customer)
	}

	{$_ -eq "featurerelease"}
	{
		build-configuration `
			-buildcommand "featurerelase-release" `
		     -clean $false -config (get-releaseconfig $script:customer) -buildBitType $buildBitType
	}


	{$_ -eq "release"}
	{
		build-configuration `
			-buildcommand "build-release" `
		   -clean $true -config (get-releaseconfig $script:customer)
		exit 0
	}



	{$_ -eq "deployrelease"}
	{
		build-configuration `
			-buildcommand "build-deployrelease" `
		   -clean $false -config (get-releaseconfig $script:customer)
		exit 0
	}



	{$_ -eq "console"}
	{
		powershell -NoLogo -NoExit -NoProfile -Command '

		set-consoleicon ([string](join-path (split-path (gcm j6.ps1).Definition) "Jenkon.ico"))

		. core.ps1
		. build.ps1
		. sql-utils.ps1

		$sql_settings = $null
		& {
			$sql_settings =  get-sqlsettings
			$sql_settings.settings.sql | fl
		}
		log "J6 Console"
		'
	}



	{$_ -eq "command"}
	{
        $cmd = '

			. core.ps1
			. build.ps1
			. sql-utils.ps1

			$sql_settings = $null
			& {
				$sql_settings =  get-sqlsettings
				$sql_settings.settings.sql | fl
			}
		' + $args[1]
		powershell -NoLogo -NoProfile -Command $cmd
	}

	{$_ -eq "ndepend"}
	{
		build-ndepend
	}



	default
	{
		log ("unknown command '{0}'" -f $script:command)
	}
}
