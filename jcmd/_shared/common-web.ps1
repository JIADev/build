function Send-MultiPartFormToApi {
    # Attribution: [@akauppi's post](https://stackoverflow.com/a/25083745/419956)
    # Remixed in: [@jeroen's post](https://stackoverflow.com/a/41343705/419956)
    [CmdletBinding(SupportsShouldProcess = $true)] 
    param (
        [Parameter(Position = 0)]
        [string]
        $Uri,

        [Parameter(Position = 1)]
        [HashTable]
        $FormEntries = @{},

        [Parameter(Position = 2, Mandatory = $false)]
        [System.Management.Automation.Credential()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(
            ParameterSetName = "FilePath",
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Alias("Path")]
        [string[]]
        $FilePath,

        [Parameter()]
        [string]
        $HttpMethod = "Post",

        [Parameter()]
        [string]
        $OutFile = $null
    );

    begin {
        $LF = "`n"
        $boundary = [System.Guid]::NewGuid().ToString()

        Write-Verbose "Setting up body with boundary $boundary"

        $bodyArray = @()

        foreach ($key in $FormEntries.Keys) {
            $bodyArray += "--$boundary"
            $bodyArray += "Content-Disposition: form-data; name=`"$key`""
            $bodyArray += ""
            $bodyArray += $FormEntries.Item($key)
        }

        Write-Verbose "------ Composed multipart form (excl files) -----"
        Write-Verbose ""
        foreach($x in $bodyArray) { Write-Verbose "> $x"; }
        Write-Verbose ""
        Write-Verbose "------ ------------------------------------ -----"

        $i = 0
    }

    process {
        $fileName = (Split-Path -Path $FilePath -Leaf)

        Write-Verbose "Processing $fileName"

        $fileBytes = [IO.File]::ReadAllBytes($FilePath)
        $fileKey = Split-Path $FilePath -Leaf
        $fileDataAsString = ([System.Text.Encoding]::GetEncoding("iso-8859-1")).GetString($fileBytes)

        $bodyArray += "--$boundary"
        $bodyArray += "Content-Disposition: form-data; name=`"$FileKey`"; filename=`"$fileName`""
        $bodyArray += "Content-Type: application/x-msdownload"
        $bodyArray += ""
        $bodyArray += $fileDataAsString

        $i += 1
    }

    end {
        Write-Verbose "Finalizing and invoking rest method after adding $i file(s)."

        if ($i -eq 0) { throw "No files were provided from pipeline." }

        $bodyArray += "--$boundary--"

        $bodyLines = $bodyArray -join "`r`n"

        # $bodyLines | Out-File data.txt # Uncomment for extra debugging...

        try {
            if (!$WhatIfPreference) {
                if ($null -ne $OutFile)
                {
                    Invoke-RestMethod `
                    -Uri $Uri `
                    -Method $HttpMethod `
                    -ContentType "multipart/form-data; boundary=`"$boundary`"" `
                    -Credential $Credential `
                    -Body $bodyLines `
                    -OutFile $OutFile
                }
                else
                {
                    Invoke-RestMethod `
                    -Uri $Uri `
                    -Method $HttpMethod `
                    -ContentType "multipart/form-data; boundary=`"$boundary`"" `
                    -Credential $Credential `
                    -Body $bodyLines
                }
            } else {
                Write-Host "WHAT IF: Would've posted to $Uri body of length " + $bodyLines.Length
            }
        } catch [Exception] {
            throw $_ # Terminate CmdLet on this situation.
        }

        Write-Verbose "Finished!"
    }
}