function Write-ColorOutput
{
    [CmdletBinding()]
    Param(
         [Parameter(Mandatory=$true)][Object] $Object,
         [Parameter(Mandatory=$false)][ConsoleColor] $ForegroundColor,
         [Parameter(Mandatory=$false)][ConsoleColor] $BackgroundColor
    )

    # Save previous colors
    $previousForegroundColor = $host.UI.RawUI.ForegroundColor
    $previousBackgroundColor = $host.UI.RawUI.BackgroundColor

    # Set BackgroundColor if available
    if($BackgroundColor -ne $null)
    {
       $host.UI.RawUI.BackgroundColor = $BackgroundColor
    }

    # Set $ForegroundColor if available
    if($ForegroundColor -ne $null)
    {
        $host.UI.RawUI.ForegroundColor = $ForegroundColor
    }

    # Always write (if we want just a NewLine)
    if($null -eq $Object)
    {
        $Object = ""
    }

    Write-Output $Object

    # Restore previous colors
    $host.UI.RawUI.ForegroundColor = $previousForegroundColor
    $host.UI.RawUI.BackgroundColor = $previousBackgroundColor
}