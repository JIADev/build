class J6SQLConnection: System.IDisposable
{
	[System.Data.SqlClient.SqlConnection]$SqlConnection
	[xml]$SqlSettings


	[void] Dispose()
    {
        Write-Verbose -Message "Disposed called"
        $this.Disposing = $true
        $this.Dispose($true)
        [System.GC]::SuppressFinalize($this)
    }

    [void] Dispose([bool]$disposing)
    {
        if($disposing)
        {
            # free managed resources here
            $this.sqlConnection.close();
        }
    }

	[xml] GetSqlSettings() {
		$path = Join-Path (Get-Location) "Sql-Settings.xml"
		if (!(Test-Path $path))
		{
			throw "Unable to load sql settings. You may not be in a j6 directory."
		}
		return [xml](Get-Content $path)
	}


	[System.Data.SqlClient.SqlConnection] GetConnection()
	{
		$cred="integrated security=true"
		if($this.sqlSettings.uid){$cred=("uid={0};pwd={1}" -f $this.sqlSettings.settings.sql.uid,$this.sqlSettings.settings.sql.pwd)}
		$connStr=("server={0};database={1};{2};connect timeout=600" -f $this.sqlSettings.settings.sql.server,$this.sqlSettings.settings.sql.database,$cred)
		$cn=new-object System.Data.SqlClient.SqlConnection($connStr)
		$cn.open()
		return $cn
	}

	[void] CreateSqlSettings(
		[string] $server = "(local)",
		[string] $db = $(throw 'Enter the database name'),
		[string] $user,
		[string] $pass
	)
	{
		$contents = 
	"<?xml version='1.0'?>
		<settings>
			<sql>
			<server>$server</server>
			<database>$db</database>
			<uid>$user</uid>
			<pwd>$pass</pwd>
			</sql>
		</settings>"
		out-file -filePath "sql-settings.xml" -inputObject $contents
	}

	[psobject] ExecuteReader(
			[string] $sql,
			[int] $timeout
	)
	{
		$database = $this.SqlSettings.settings.sql.database
		$results = New-Object System.Collections.ArrayList
		$rows = $null
		$command = $null
		& {
			& {
				$command = $this.sqlConnection.createcommand()
				if ($database) {
					$command.commandtext = "use [$database]"
					[void]$command.executenonquery()
				}
				$command.commandtimeout = $timeout
				$command.commandtext = $sql
				$rows = $command.ExecuteReader()
				$names = @()
				foreach ($i in 0..($rows.fieldcount - 1)) {
					$name = $rows.getname($i)
					$names += $name
				}
				while($rows.read()) {
					$o = new-object psobject
					foreach($name in $names) {
						add-member -in $o -name $name -memberType noteproperty -value $rows.getvalue($rows.getordinal($name))
					}
					$results.Add($o);
				}
			}
			trap {
				write-host "Query failed: $_"
				continue
			}
		}
		if ($rows) {[void]$rows.close()}
		if ($command) {[void]$command.Dispose()}
		return $results;
	}

	[void] ExecuteNonquery(
			[string] $sql,
			[int] $timeout
	)
	{
		$database = $this.sqlSettings.settings.sql.database
		$command = $null
		& {
			& {
				$command = $this.sqlConnection.createcommand()
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
	}

	J6SQLConnection	(
	)
	{
		$this.sqlSettings = $this.GetSqlSettings()
		$this.sqlConnection = $this.GetConnection()
	}

	J6SQLConnection	(
		$settings
	)
	{
		if (!$settings) {$settings = $this.GetSqlSettings()}
		$this.sqlSettings = $settings
		$this.sqlConnection = $this.GetConnection()
	}

	J6SQLConnection	(
		$settings,
		$connection
	)
	{
		if (!$settings) {$settings = $this.GetSqlSettings()}
		if (!$connection) {$connection = $this.GetConnection()}
		$this.sqlSettings = $settings
		$this.sqlConnection = $connection
	}

}
