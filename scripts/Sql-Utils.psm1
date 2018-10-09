set-psdebug -strict

# Requires: core.ps1
$script:_serverInstance = $null;

function get-sqlserverinstance {
	param($sqlsettings = (get-sqlsettings).settings.sql)
	assert-notempty $sqlsettings "Usage: get-sqlserverinstance sqlSettings"
	assert-notempty $sqlsettings.server "Sql setting server required"
	assert-notempty $sqlsettings.uid "Sql setting uid required"
	assert-notempty $sqlsettings.pwd "Sql setting pwd required"

	if (-not($script:_serverInstance)) {
		[void]([System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo"))
		[void]([System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended"))
		[void]([System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo"))

		$conn = new-object Microsoft.SqlServer.Management.Common.ServerConnection($sqlsettings.server, $sqlsettings.uid, $sqlsettings.pwd)
		assert-notempty $conn "Unable to create connection to server"

		$server = new-object Microsoft.SqlServer.Management.Smo.Server($conn)
		assert-notempty $server "Unable to connect to server"
		$script:_serverInstance = $server
	}
	return  [Microsoft.SqlServer.Management.Smo.Server]$script:_serverInstance
}

function add-usertodb {
	param($sqlSettings)
	assert-notempty $sqlSettings "Usage: Add-UserToDB sqlSettings"
	assert-notempty $sqlsettings.database "sqlsettings.database is required"
	assert-notempty $sqlsettings.uid "sqlsettings.uid is required"
	$dbName = $sqlSettings.database

	$server = get-sqlserverinstance($sqlsettings)
	$u = new-object Microsoft.SqlServer.Management.Smo.User($server.databases[$dbName], $sqlsettings.uid);
	$u.Login = $sqlsettings.uid;
	validate-command { $u.Create() } "Unable to add user" $true
}

function get-connection {
	param(
		$sqlsettings = (get-sqlsettings).settings.sql,
		$database="master"
	)
	$connStr = ''
	$cred="integrated security=true"
	if($sqlsettings.uid){$cred=("uid={0};pwd={1}" -f $sqlsettings.uid,$sqlsettings.pwd)}
	$connStr=("server={0};database=master;{1};connect timeout=600" -f $sqlsettings.server,$cred)
	$connection=new-object system.data.SqlClient.SqlConnection($connStr)
	$connection.open()
	return $connection
}

function database-exists {
	param($sqlsettings)
	$dbName = $sqlsettings.database
	log("checking if database $dbName exists")
	$connection=Get-Connection($sqlSettings)
	$command=new-object System.Data.SqlClient.SqlCommand
	$command.connection=$connection
	$command.commandText="SELECT count(*) FROM sys.databases WHERE name = N'$dbName'"
	$count=$command.ExecuteScalar()
	$connection.close();
	return ($count -eq 1)
}


function detach-database {
	param($sqlsettings)
	assert-notempty $sqlsettings "Usage: Detach-Database sqlSettings"
	assert-notempty $sqlsettings.database "sqlsettings.database is required"

	$dbName=$sqlsettings.database
	$server=get-sqlserverinstance($sqlsettings)
	if(database-exists $sqlsettings){
		$server.DetachDatabase($dbName,$false)
		Log "Detaching $dbName"
	}
}


function attach-database {
	param(
		$dbFiles,
		$sqlsettings
	)
	trap {
		if(!(database-exists($sqlsettings))){
			throw "Unable to attach to database and db doesn't exist: " +  $_.Exception
			break;
		} else {
			log("database exists... continuing")
			continue;
		}
	}
	& {
		$usage = "Usage: Attach-Database dbFiles sqlsettings"
		assert-notempty $dbFiles "$usage -> dbFiles not set"
		assert-notempty $sqlsettings "$usage -> sqlsettings not set"
		assert-notempty $sqlsettings.database "No database name in sql settings"

		$dbname = $sqlsettings.database
		$sourcePath = "data/dev"

		$files = new-object System.Collections.Specialized.StringCollection
		$dbFiles | %{ [void]($files.Add($_)) }

		$server = get-sqlserverinstance($sqlsettings)
		validate-command { $server.AttachDatabase($dbname, $files,  "dbo")}  "Unable to attach database $dbname" $true
	}
}

function restore-database {
	param (
		$sqlsettings = (get-sqlsettings).settings.sql,
		[string]$folder = (get-datadirectory $sqlsettings),
		[string]$backup =  (get-buildbackup),
		[switch]$force
	)
	$error.clear()
	$server = get-sqlserverinstance($sqlsettings)
	$restore = new-object Microsoft.SqlServer.Management.Smo.Restore
	$restore.ReplaceDatabase = $true
	$restore.Database = $sqlsettings.database
	$database = $sqlsettings.database
	$folder = (new-object System.IO.DirectoryInfo $folder).fullname
	#$restore.DatabaseFiles.Add((join-path $folder "$database.mdf"))
	#$restore.DatabaseFiles.Add((join-path $folder ($database + "_log.ldf")))
	$restore.RelocateFiles.Add((new-object Microsoft.SqlServer.Management.Smo.RelocateFile -argumentList "Engaje","$folder\$database.mdf"))
	$restore.RelocateFiles.Add((new-object Microsoft.SqlServer.Management.Smo.RelocateFile -argumentList "Engaje_log","$folder\$database.ldf"))
	$restore.Devices.AddDevice($backup,  [Microsoft.SqlServer.Management.Smo.DeviceType]::File)
	if ( `
		-not ($database.tolower() -match "-dev") `
		-and ($backup.tolower() -match "-dev.bak") `
		-and !($force) `
	) {
		throw "Cannot restore a -DEV backup file to a non -DEV database. Use -force to override"
	}
	Log ("Restoring {0} to database {1} ({2})" -f $restore.Devices,$restore.Database,$restore.DatabaseFiles)
	$restore.Script($server)
	$restore.SqlRestore($server)
	if($error.Count -gt 0){throw "restore DB failed"}
}

function prepare-databasefiles {
	param([string]$destPath, [string]$sourcePath)
	Log ("Checking in '{0}' for backups" -f $destPath)
	if (get-command 7z*) {
		ls $sourcePath\*.zip | foreach {
			Log ($_.FullName)
			[void](& "7z" x ($_.fullname) "-o$destPath" -y)
		}
	}
	return (ls $destPath\*.bak | foreach {$_.fullname})
}

function dropandreplace-database {
	param(
		$settings=(get-buildsettings).settings,
		$sqlsettings=(get-sqlsettings).settings.sql
	)
	Log ("settings: $sqlsettings : $workingDir")
	detach-database $sqlsettings
	Log ("detached " + $sqlsettings.database)
	Log ($MyInvocation.ScriptName)
	$scriptsdir=(split-path (gcm sql-utils.ps1).Definition)
	Log ("$scriptsdir")
	$dsrc=(join-path (split-path $scriptsdir) data)
	$dbDirAsLocal=$settings.configurations.dbDirAsLocal
	$dbDirAsRemote=$settings.configurations.dbDirAsRemote
	$dbFileName = $settings.configurations.dbFileName
	if (!$dbFileName) { $dbFileName = 'j6-dev.bak'}
	$fileName = "$dbDirAsLocal\$dbFileName"
	prepare-databasefiles $dbDirAsRemote $dsrc
	restore-database $sqlsettings $dbDirAsLocal $fileName
	Log ("attached" + $sqlsettings.database)
	add-usertodb $sqlsettings
}

function get-databaseinstance {
	param(
		[string]$db=$(throw "provide a db name"),
		$sqlsettings=(get-sqlsettings).settings.sql
	)
	$server=get-sqlserverinstance($sqlsettings)
	$db=$sqlsettings.database.tolower()
	$server.databases|?{ $_.name.tolower() -match $db}
}

function get-datadirectory {
	param($sqlsettings=(get-sqlsettings).settings.sql)
	$database=get-databaseinstance $sqlsettings.server $sqlsettings
	(dir $database.filegroups[0].files[0].filename).directory.fullname
}

function get-buildbackup {
	$script = (gcm sql-utils.ps1).definition
	$directory = (dir $script).directory.fullname
	(dir "$directory/../data/*.bak").fullname
}

function create-sqlsettings {
	param(
		[string] $server = "(local)",
		[string] $db = $(throw 'Enter the database name'),
		[string] $user,
		[string] $pass
	)
	out-file -filePath "sql-settings.xml" -inputObject "<?xml version='1.0'?>
<settings>
  <sql>
    <server>$server</server>
    <database>$db</database>
    <uid>$user</uid>
    <pwd>$pass</pwd>
  </sql>
</settings>"
}

function get-sqlsettings {
	$path = find-file "./" "Sql-Settings.xml"
	assert-notempty $path "Unable to load sql settings. You may not be in a j6 directory."
	return [xml](gc $path)
}



function execute-reader {
    param(
        [string] $sql = $(throw "Enter an SQL string"),
        $connection = (get-connection),
        $database = (get-sqlsettings).settings.sql.database,
        $timeout = 30
        )
	$rows = $null
	$command = $null
	& {
	    & {
			$command = $connection.createcommand()
		    if ($database) {
		        $command.commandtext = "use [$database]"
		        [void]$command.executenonquery()
		    }
		    $command.commandtimeout = $timeout
		    $command.commandtext = $sql
		    $rows = $command.executereader()
		    $names = @()
		    foreach ($i in 0..($rows.fieldcount - 1)) {
		        $names += $rows.getname($i)
		    }
		    while($rows.read()) {
		        $o = new-object psobject
		        foreach($name in $names) {
		            add-member -in $o -name $name -memberType noteproperty -value $rows.getvalue($rows.getordinal($name))
		        }
		        $o
		    }
		}
		trap {
			write-host "Query failed: $_"
			continue
		}
	}
    if ($rows) {[void]$rows.close()}
    if ($command) {[void]$command.Dispose()}
    if ($connection) {[void]$connection.close()}
}

set-alias er execute-reader

function execute-nonquery {
    param(
        [string] $sql = $(throw "Enter an SQL string"),
        $connection = (get-connection),
        $database = (get-sqlsettings).settings.sql.database,
        $timeout = 30
        )
	$command = $null
	& {
		& {
		    $command = $connection.createcommand()
		    $command.commandtimeout = $timeout
		    if ($database) {
		        $command.commandtext = "use [$database]"
		        [void]$command.executenonquery()
		    }
		    $command.commandtext = $sql
		    $command.executenonquery()
		}
		trap {
			write-host "Query failed: $_"
			continue
		}
	}
    if ($command) {[void]$command.Dispose()}
    if ($connection) {[void]$connection.close()}
}

set-alias en execute-nonquery

function get-theme {
	param($site = $(throw "specify site name"))
	$ret = (er ("select theme from personal.personalsite where code='{0}'" -f $site))
	return $ret.theme
}

function set-theme {
	param(
		$site = $(throw "specify site name"),
		$theme = "DevTest"
	)
	$null = en ("update personal.personalsite set theme='{0}' where code = '{1}'" -f $theme, $site)
	get-theme $site
}

function get-sites { return (er "select p.code as site, p.activitycenter, p.theme, p.corporate ,r.name as resourceset from personal.personalsite p join resourceset r on p.resourceset = r.id") }




function get-appsettingid { param($key="AppCustomer"); return (er "select id from appsetting where name = '$key'").id }
function get-appsetting { 
	param($key="AppCustomer");
	$id = get-appsettingid $key; 
	if($id -gt 0) {
		$res = (er @"
			IF EXISTS (SELECT * FROM appsettingvalue WHERE appsetting = $id AND useroverride = 1)
				SELECT value FROM appsettingvalue WHERE appsetting = $id AND useroverride = 1
			ELSE IF EXISTS (SELECT * FROM appsettingvalue WHERE appsetting = $id AND isoverride = 1)
				SELECT value FROM appsettingvalue WHERE appsetting = $id AND isoverride = 1
			ELSE
				SELECT value FROM appsettingvalue WHERE appsetting = $id AND isoverride = 0
"@
);
		return $res.value
	}
	throw "key $key not found"
}

function set-appsetting {
	param($key="AppCustomer",$value=(throw "provide value"));
	$id = get-appsettingid $key; 
	if($id -gt 0) {
		$res = (en @"
			IF EXISTS (SELECT * FROM AppSettingValue WHERE appsetting = $id AND useroverride = 1)
				UPDATE appsettingvalue SET value = '$value' WHERE appsetting = $id AND useroverride = 1
			ELSE
				INSERT INTO appsettingvalue (AppSetting,Value,UserOverride) VALUES ($id,'$value',1)
"@
);
		return 
	}
	throw "key $key not found"
}

function get-appsettings { 
	return (er @"
		SELECT
			a.Id,a.Name,
			d.Value AS DefaultValue,
			o.Value AS OverrideValue,
			u.Value AS UserOverrideValue,
			a.Type,a.Comment
		FROM 
			AppSetting a INNER JOIN
			--defaults
			(
				SELECT * 
				FROM AppSettingValue av 
				WHERE isoverride = 0 and useroverride = 0
			) d ON d.appSetting = a.id LEFT OUTER JOIN
			--overrides
			(
				SELECT * 
				FROM AppSettingValue av 
				WHERE isoverride = 1 and useroverride = 0
			) o ON o.appSetting = a.Id LEFT OUTER JOIN
			-- user overrides
			(
				SELECT * 
				FROM AppSettingValue av 
				WHERE isoverride = 0 and useroverride = 1
			) u ON u.appSetting = a.id
"@
)
}

function show-summitsettings {
	$hstn = get-appsetting "UniObjHostName"
	$acct = get-appsetting "UniObjAccountPath"
	$user = get-appsetting "UniObjUserName"
	$pass = get-appsetting "UniObjPassword"
	$sb1 = get-appsetting "SbParam1"
	$sb2 = get-appsetting "SbParam2"
	$sb3 = get-appsetting "SbParam3"
	$sb15 = get-appsetting "SbParam15"
	$sb16 = get-appsetting "SbParam16"
	@"

 Summit Settings:
 --
     Host: $hstn
     Path: $acct
     User: $user
     Pass: $pass

 SbParam1: $sb1
 SbParam2: $sb2
 SbParam3: $sb3
SbParam15: $sb15
SbParam16: $sb16

"@
}

function create-codetablesql($schema, $table) {
	"IF OBJECT_ID('$schema.$table') IS NULL
	BEGIN
	CREATE TABLE [$schema].[$table] (
		Id INT IDENTITY NOT NULL CONSTRAINT PK_$table PRIMARY KEY,
		Code NVARCHAR(50) NOT NULL,
		Description NVARCHAR(200) NULL
	)
	CREATE UNIQUE NONCLUSTERED INDEX IX_$($table)_Code ON [$schema].[$table](Code ASC)
	END
	GO
	"
}

