set-psdebug -strict



function set-configuration {
	param([string]$config);
	$global:configuration=$config
}

function get-configuration {
	if(-not(gv -s global -i configuration)){$global:configuration="Debug"}
	return $global:configuration
}
$null=get-configuration


function get-isodate { get-date -format "yyyy-MM-dd HH:mm:ss"}
function get-datestamp { get-date -format "yyyyMMdd_HHmmss"}

function log-util {
	param(
		$msg="---mark---",
		$outmethod="write-host"
	)
	$logfile=$env:J6LOGFILE
	$dt=get-datestamp
	$line=("{0}:  {1}" -f $dt,$msg)
	& $outmethod $msg
	& {
		trap { break; }
		if($logfile){add-content -force $logfile $line}
	}
}

function log-debug {param($msg);log-util ("DEBUG: {0}" -f $msg) "write-debug"}
function log-message {param($msg);log-util (" INFO: {0}" -f $msg) "write-host"}
function log-warning {param($msg);log-util (" WARN: {0}" -f $msg) "write-warning"}
function log-error {param($msg);log-util ("ERROR: {0}" -f $msg) "write-error"}

set-alias -name debug -value log-debug -description "write message to console and possibly log file"
set-alias -name log -value log-message -description "write message to console and possibly log file"
set-alias -name warn -value log-warning -description "write message to console and possibly log file"
set-alias -name error -value log-error -description "write message to console and possibly log file"

# matches "IH_00000","IH12345","CUST11111_Misc","File.CUST_00000.dll", etc.
$customer_regex = "(^|[\\.])(?<customer>(IH|CUST)_?\d+)([\\._]|$)"

function is-custom { param([string]$name);$name -imatch $customer_regex}
function find-solutions{param([string]$root);(ls -r $root)|?{$_.Extension.ToLower() -eq ".sln"}}
function find-customsolutions{param([string]$root);(find-solutions $root)|?{is-custom $_.FullName}|?{$_.FullName -match (get-buildsettings).settings.customer}}


function find-file {
	param($dir, $filename)
	$path = join-path $dir $filename
	if (test-path $path) { return $path }
	elseif((test-path $dir) -and (get-item $dir).parent) {
		find-file (join-path $dir "..") $filename
	}
}

function remove-dir {
	param($path)
	if(test-path $path) {
		$path = resolve-path $path
		log ("removing $path")
		rm -r -force $path
	}
}

function copy-dir {
	param($srcDir, $destPath)
	if(test-path $srcDir) {
		$srcDir = resolve-path $srcDir
		log ("Copying $srcDir to $destPath")
		cp -recurse $srcDir $destPath
	}
}

# From: http://mow001.blogspot.com/2006/01/adding-simple-accesrule-to-file-acl-in.html
function change-filepermission {
	param(
		$file,$user,
		[System.Security.AccessControl.FileSystemRights]$Rights,
		[System.Security.AccessControl.AccessControlType]$access = "Allow"
	)
	$ar = new-object System.Security.AccessControl.FileSystemAccessRule($user,$Rights,$access)
	# check if given user is Valid, this will break function if not so.
	$Sid = $ar.IdentityReference.Translate([System.Security.Principal.securityidentifier])
	$acl = get-acl $file
	$acl.SetAccessRule($ar)
	set-acl $file $acl
}

function get-buildsettings {
	$path = find-file "./" "Build-Settings.xml"
log $path
	if(-not $path){
log "Setting not found"
		$templ = find-file "./" "Build-Settings-template.xml"
		if($templ){cp $templ $templ.Replace("-template","")}
		$path = find-file "./" "Build-Settings.xml"
	}
	assert-notempty $path "Unable to load build settings. You may not be in a j6 directory."
	return [xml](gc $path)
}

function get-builddirectory {
	param($config=(get-buildsettings))
	$buildDir=$config.settings.configurations.buildDirectory
	if(-not $buildDir){$buildDir=[string](pwd)}
	return $buildDir
}

function get-workingdirectory {
	param($config=(get-buildsettings))
	$workingDir=$config.settings.configurations.workingDirectory
	if(-not $workingDir){$workingDir="."}
	$workingDir=(split-path -leaf $workingDir)
	$workingDir=(join-path (get-builddirectory $config) $workingDir)
	return $workingDir
}

function get-releasedirectory {
	param($config=(get-buildsettings))
	$releaseDir=$config.settings.configurations.releaseDirectory
	if(-not $releaseDir){$releaseDir="release"}
	$releaseDir=(split-path -leaf $releaseDir)
	$releaseDir=(join-path (get-builddirectory $config) $releaseDir)
	return $releaseDir 
}

function updatecustomer-buildsettings {
	param([string]$cust)
	$xml = get-buildsettings
	$xml.settings.customer = $cust
	$path = find-file "./" "Build-Settings.xml"
	$xml.save($path)
}

function create-buildsettings {
	param (
	[string] $customer = "IH00000",
	[string] $branch = "/trunk-j6",
	[string] $server = "(local)",
	[string] $db = "j6-DEV",
	[string] $user,
	[string] $password,
	[string] $config = "Debug"
	)

	out-file build-settings.xml -inputobject "<?xml version='1.0'?>
<settings>
  <customer>$customer</customer>
  <configurations>
    <buildDirectory>$(pwd)</buildDirectory>
    <workingDirectory>build</workingDirectory>
    <svnRepository>http://source.jenkon.com/svn$branch</svnRepository>
    <!--
       remoteTiersDirectory is the directory used by remote tiers generation.
       It should be unique
    -->
    <remoteTiersDirectory>$env:username\$($branch.split('/')[-1])</remoteTiersDirectory>
    <configuration>$config</configuration>
    <dbDirAsLocal></dbDirAsLocal>
    <dbDirAsRemote></dbDirAsRemote>
    <releaseDirectory>release</releaseDirectory>
  </configurations>
  <sql>
    <server>$server</server>
    <database>$db</database>
    <uid>$user</uid>
    <pwd>$password</pwd>
  </sql>
</settings>
"
}

function save-buildsettings {
	param($xml)
	$path = resolve-path (find-file "./" "Build-Settings.xml")
	$xml.save($path)
}

function updatecustomer-portalthemes {
	param([string]$cust)
	$path = find-file "./Sites/Portal" "web.config"
	if(!$path) { throw "Unable to load portal web.config." }
	$pattern = "theme=`"IH\d+`""
	$replace = "theme=`"Default`""
	$updated = (gc $path) -replace $pattern, $replace
	set-content -path $path $updated
}

function validate-command {
	param($callback, [string]$errorMsg = "", [bool]$showInner = $false)
	trap {
		function display-innerexception {
			param($ex, $level = 0)
			# recurse only 5 levels
			if ($level -lt 5 -and $ex.InnerException) {
				log ("Inner exception: " + $ex.InnerException.Message)
				display-innerexception $ex.InnerException $level++
			}
		}
		log-error ("An error occured: " + $_.Exception.Message)
		if($showInner) { display-innerexception $_.Exception }
		if ($errorMsg -ne "") { log-error $errorMsg }
		throw $errorMsg
	}

	$errCnt = $error.count
	$global:LastExitCode = 0

	. $callback

	assert-equal $LastExitCode 0 $errorMsg
	assert-equal $errCnt $error.count $errorMsg
}

function assert {
	param($test, $msg)
	$testresult = &$test
	if( $testresult -ne $true) { throw $msg }
}

function assert-equal { param($var, $val, $msg); Assert {$var -eq $val} $msg }

function assert-notequal { param($var, $val, $msg); Assert {$var -ne $val} $msg }

function assert-notempty {
	param($var, $msg)
	if ($var -is [array]) { assert-notequal $var.length 0 $msg }
	else {
		assert-notequal $var $() $msg
		assert-notequal $var "" $msg
	}
}

function assert-exists {
	param($path, $msg =("{0} does not exist" -f $path))
	Assert { test-path $path } $msg
}

# not using Measure-Method because of error it
# produces when exiting
function profile-process {
	param($procName, $proc)
	$startTime = get-date
	& $proc
	$endTime = get-date
	$span = $endTime.subtract($startTime)
	Log ("Total $procName time: " + $span.minutes.toString() + " Minutes: " + $span.seconds.toString() + " Seconds")
}

function get-root { (dir (find-file . build-settings.xml)).Directory.FullName }

function create-ifelementmissing {
	param(
		$node=$(throw "specify xml node"),
		$elem=$("specify child element"),
		$def=""
	)
	if(-not($node.Item($elem))){
		$new=$node.get_OwnerDocument().CreateElement($elem)
		$new.PSBase.InnerText=$def
		$null=$node.PrependChild($new)
	}
}
