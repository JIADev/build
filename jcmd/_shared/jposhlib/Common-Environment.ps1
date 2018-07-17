#
# Common_SQL.ps1
#


function Expand-EnvironmentVariables($unexpanded) {
    $previous = ''
    $expanded = $unexpanded
    while($previous -ne $expanded) {
        $previous = $expanded       
        $expanded = [System.Environment]::ExpandEnvironmentVariables($previous)
    }
    return $expanded 
}

function Set-ExpandableEnvironmentVariable([string] $key, [string] $value, [bool] $userOnly = $false)
{
	if ($userOnly)
	{
		Set-ItemProperty HKCU:\Environment $key $value -Type ExpandString
	} else
	{
		Set-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment' $key $value -Type ExpandString
	}
}

function Test-PathContainsFolder([string] $path, [string] $folder)
{
	$parts = $path.ToLower().Split(';');
	return $parts.Contains($folder.ToLower());
}


function Set-PermanentPath([string] $newPath)
{
	set-item -force -path "env:Path" -value $newPath;
	#[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine");
	
	Set-ExpandableEnvironmentVariable "Path" $newPath

	Send-EnvironmentChangeMessage
}

function Add-PermanentPathFolder([string] $newPath)
{
	$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine");
	if (!(Test-PathContainsFolder $machinePath $newPath))
	{
		$machinePath = $machinePath, $newPath -join ";"
		$machinePath = $machinePath -replace ";;",";"
		#[Environment]::SetEnvironmentVariable("Path", $machinePath, "Machine");
		Set-ExpandableEnvironmentVariable "Path" $machinePath
	}
	$currentPath = $env:Path
	if (!(Test-PathContainsFolder $currentPath $newPath))
	{
		$currentPath = $currentPath, $newPath -join ";"
		$currentPath = $currentPath -replace ";;",";"
		#set-item -force -path "env:Path" -value $currentPath;	
		$env:Path = $currentPath
	}
	
	Send-EnvironmentChangeMessage
}

function Send-EnvironmentChangeMessage {
    # Broadcast the Environment variable changes, so that other processes pick changes to Environment variables without having to reboot or logoff/logon. 
    if (-not ('Microsoft.PowerShell.Commands.PowerShellGet.Win32.NativeMethods' -as [type])) {
        Add-Type -Namespace Microsoft.PowerShell.Commands.PowerShellGet.Win32 `
                -Name NativeMethods `
                -MemberDefinition @'
                    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                    public static extern IntPtr SendMessageTimeout(
                        IntPtr hWnd,
                        uint Msg,
                        UIntPtr wParam,
                        string lParam,
                        uint fuFlags,
                        uint uTimeout,
                        out UIntPtr lpdwResult);
'@
    }

    $HWND_BROADCAST = [System.IntPtr]0xffff;
    $WM_SETTINGCHANGE = 0x1a;
    $result = [System.UIntPtr]::zero

    # https://msdn.microsoft.com/en-us/library/windows/desktop/ms644952(v=vs.85).aspx
    $returnValue = [Microsoft.PowerShell.Commands.PowerShellGet.Win32.NativeMethods]::SendMessageTimeout($HWND_BROADCAST, 
                                                                                                        $WM_SETTINGCHANGE,
                                                                                                        [System.UIntPtr]::Zero, 
                                                                                                        'Environment',
                                                                                                        2, 
                                                                                                        5000,
                                                                                                        [ref]$result);
    # A non-zero result from SendMessageTimeout indicates success.
    if($returnValue) {
        Write-Host 'Successfully broadcasted the Environment variable changes.'
    } else {
        Write-Host 'Error in broadcasting the Environment variable changes.'
    }
}