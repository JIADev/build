
function get-optionalarg {
	param(
	 $scriptargs,
	 [int]$count,
	 $default
	)
	if($scriptargs.Count -le $count){return $default}
	else{return $scriptargs[$count]}
}

function update-datamodule {
	param (
		[string] $file = 'DataModule\datamodule-properties.csp',
		[string] $server = "(local)",
		[string] $db = $(throw 'Enter the database name'),
		[string] $user,
		[string] $pass
	)
	$currentDir=[string](pwd)
	log("updating data module for  $currentDir $file")

	if($user){$security="uid=$user;pwd=$pass"}
	else{$security="Integrated Security="+($user.trim().length -eq 0)}

	$connection="Data Source=$server;Initial Catalog=$db;$security"
	$element="<connectionString>$connection</connectionString>"
	$pattern="<connectionString>.+</connectionString>"
	$old=gc $file
	$new=$old -replace $pattern,$element
	set-content -path $file $new
}

function log {
	param($msg = "---MARK---")
	$dt = get-date
	$logFile = join-path (join-path $baseDir $workingDir) ("{0:yyyy-MM-dd}-log.txt" -f $dt)
	$msg = "$dt -- $msg"
	add-content $logFile $msg
}

function validate-command {
	param(
		$callback,
		$errorMsg
	)
	trap {
		log ("An error occured: {0}" -f $_.Exception.Message)
		log ("Stack Trace: {0}" -f $StackTrace)
		if ($errorMsg){log $errorMsg}
		exit 1
	}
	$errCnt=$error.count
	$LastExitCode=0
	. $callback
	$newerrCount=$error.count
	$displayErrCnt=$newerrCount.toString()

	if($LastExitCode -ne 0 -or $errCnt -ne $newerrCount) {
		if($errorMsg){log $errorMsg}
		exit 1
	}
}

function initialize {cd $baseDir}

function create-datamodule {
	log "Exporting from $svnRepUrl"
	validate-command {
		svn.exe export $svnRepUrl "$workingDir\DataModule" --username build --password build
	}  "Unable to svn export $svnRepUrl"
	log "Done Exporting"

	log "Copying Project Files"
	validate-command {
		$local:csp = join-path $workingDir "*.csp"
		$local:cs = join-path $workingDir "*.cs"
		$local:dest = join-path $workingDir "DataModule"
		
		$local:cs,$local:csp | ?{test-path $_} | %{ 
			log "copying $_"
			cp -path (resolve-path $_) -destination (resolve-path $local:dest)
		}

	} "Unable to copy Project file to data module directory"
	log "Done Copying Project Files"
}

function generate {
	cd $workingDir
	validate-command {
		update-datamodule -server $dbServer -db $dbName -user $dbUsername -pass $dbPassword
	} "Unable to update data module"
	cd DataModule
	$currentDir=[string](pwd)
	log "Generating tiers $currentDir"
	$csex="C:\Program Files (x86)\CodeSmith\v4.0\cs.exe"
	if(-not(test-path $csex)){$csex="C:\Program Files\CodeSmith\v4.0\cs.exe"}
	validate-command {
		. $csex /v datamodule-properties.csp > generation.log 2>&1
	} "Unable to generate net-tiers"
	log "compressing tiers"
	compact /c /s:Generated
	log "completed generating tiers"
}

if($Args.Count -lt 4) {
	write-host("Usage generate-tiers path svnRepository dbServer dbName [dbUsername] [dbPassword]")
	exit 1
}

$baseDir="d:\j6\tiers-generation\"
$username=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$workingDir=$Args[0]
$svnRepUrl=$Args[1]
$rev=""
if($svnRepUrl.Contains("@")){
	$rev=$svnRepUrl.SubString($svnRepUrl.IndexOf("@"))
	$svnRepUrl=$svnRepUrl.SubString(0,$svnRepUrl.IndexOf("@"))
}
if(-not ($svnRepUrl.endswith("/"))){$svnRepUrl+="/"}
$svnRepUrl+=("DataModule{0}" -f $rev)

log "Start generate Tiers for $username"

$dbServer = $Args[2]
$dbName = $Args[3]

$dbUsername =  get-optionalarg $Args 4 ""
$dbPassword =  get-optionalarg $Args 5 ""

log "---Args: $workingDir : $svnRepUrl $dbServer : $dbName : $dbUsername : $dbPassword"

initialize
create-datamodule
generate

log "Completed"
