. "$PSScriptRoot\SourceControlTasks\SourceControlTasks.ps1"
function parseArgs([array]$params) {
    $config = [pscustomobject]@{
        customerNumber = [string]''
        taskNumber     = [string]''
        graftRevision  = [array]@()
        revertall      = [bool]$false
    }
    $params | foreach {
        if ('--revertall' -eq $_ ) {
            $config.revertall = $true
        }
        else {
            if ($config.customerNumber -eq '') {
                $config.customerNumber = [string]$_
            }
            else {
                if ($config.taskNumber -eq '') {
                    $config.taskNumber = [string]$_
                }
                else {
                    $config.graftRevision = $config.graftRevision + @( $_ )
                }
            } 
        }
    }
    return $config
}

function validateCustomer([string]$customerNumber) {
    if ($validCustomers -NotContains $customerNumber) {
        $errorMessage = $customerNumber + " is not a valid customer number"
        Write-Host $errorMessage
        Write-Host $usageMessage
        Exit
    }
}

function setupBranch([string]$customerNumber, [string]$taskNumber, [array]$graftRevision, [bool]$revertall) {
    $hasPendingChanges = hasPendingChanges
    if ($hasPendingChanges -eq $true) {
        Write-Host "Pending changes found.  Please shelve or commit your changes before running starttask"
        Exit
    }

    $startEnv = $tagOverrides[[string]$customerNumber]
    if ($startEnv -eq $null) {
        $startEnv = 'PRD'
    }
    $startTag = [string]$customerNumber + '_' + $startEnv
    $branchName = [string]$customerNumber + '_' + [string]$taskNumber

	#& h-g pull
	SourceControl_Pull
    if ($revertall -eq $true) {
        & $msbuild /t:RevertAll $scriptPath\buildtools.proj
    }
    Write-Host "Updating to $startTag"
    SourceControl_UpdateBranch $startTag

    $branchCreated = ensureBranchUp $branchName
    if ($branchCreated -ne 0) { 
        Write-Host "Cannot create or update to $branchName"
        Exit
    }
    ensureBranchIncludes $startTag
}


