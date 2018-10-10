class J6SQLConnection {
    [xml]$SqlSettings

    [xml] GetSqlSettings() {
        $path = Join-Path (Get-Location) "Sql-Settings.xml"
        if (!(Test-Path $path)) {
            throw "Unable to load sql settings. You may not be in a j6 directory."
        }
        return [xml](Get-Content $path)
    }

    [void] ImportSQLPS() {
        if (!(get-module sqlps))
        {
            push-location
            import-module sqlps 3>&1 | out-null
            pop-location
        }
    }

    [psobject] Execute([string] $fileName, [string]$sql, [int] $timeout, [switch] $quiet) {

        $params = @{}

        $hasUidPw = Get-Member -inputobject $this.sqlSettings -name "uid" -Membertype Properties
        if ($hasUidPw) {
            $params.Username = $this.sqlSettings.settings.sql.uid
            $params.Password = $this.sqlSettings.settings.sql.pwd
        }

        if ($fileName) {
            $params.InputFile = $fileName
        }
        else {
            $params.Query = $sql
        }

        if (!$quiet) {
            $params.OutputSqlErrors = $true
            $params.Verbose = $true
        }

        $params.Database = $this.sqlSettings.settings.sql.database
        $params.ServerInstance = $this.sqlSettings.settings.sql.server
        $params.ConnectionTimeout = 60
        $params.QueryTimeout = $timeout
        $params.AbortOnError = $true

        $result = $null
        Push-Location
        try {
            $result = Invoke-Sqlcmd @params
            $success = $?
            if (!$success)
            {
                write-host "Unexpected Error. No further error details are available." -ForegroundColor Red
                if ($result)
                {
                    write-host "Result:" -ForegroundColor Red
                    write-host $result -ForegroundColor Red
                }
            }
        }
        catch {
            write-host "Caught an exception:" -ForegroundColor Red
            write-host "Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
            write-host "Exception message: $($_.Exception.Message)" -ForegroundColor Red
            write-host "Error: " $_.Exception -ForegroundColor Red

            Exit 1
        }
        finally {
            Pop-Location
        }

        return $result
    }

    [psobject] ExecuteSQL([string]$sql) {
        $result = $this.ExecuteSQL($sql, 600, $false)
        return $result
    }

    [psobject] ExecuteSQL([string]$sql, [switch] $quiet) {
        $result = $this.ExecuteSQL($sql, 600, $quiet)
        return $result
    }

    [psobject] ExecuteSQL([string]$sql, [int] $timeout = 600, [switch] $quiet = $false) {
        $result = $this.Execute($null, $sql, $timeout, $quiet)
        return $result
    }

    [psobject] ExecuteFile([string]$fileName) {
        $result = $this.ExecuteFile($fileName, 600, $false)
        return $result
    }

    [psobject] ExecuteFile([string]$fileName, [switch] $quiet) {
        $result = $this.ExecuteFile($fileName, 600, $quiet)
        return $result
    }

    [psobject] ExecuteFile([string]$fileName, [int] $timeout = 600, [switch] $quiet = $false) {
        $result = $this.Execute($fileName, $null, $timeout, $quiet)
        return $result
    }

    J6SQLConnection	(
    ) {
        $this.ImportSQLPS()

        $this.sqlSettings = $this.GetSqlSettings()
    }

    J6SQLConnection	(
        $settings
    ) {
        $this.ImportSQLPS()

        if (!$settings) {$settings = $this.GetSqlSettings()}
        $this.sqlSettings = $settings
    }


}
