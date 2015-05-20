$customerNumber = ''
$taskNumber = ''
$args | foreach {
      if($customernumber -eq '') {
      	$customernumber = $_
      } else {
      	if($taskNumber -eq '') {
      		       $taskNumber = $_
      		       }
      }
}
$startTag = [string]$customerNumber + '_UAT'
$branchName = [string]$customerNumber + '_' + [string]$taskNumber
$comment = "Starting task " + [string]$taskNumber
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
& $msbuild /t:UpdateBuildToolsRepo /p:BuildToolsRepo="$scriptPath" $scriptPath\buildtools.proj
& hg pull
& hg up $startTag
& hg up
& hg branch $branchName
& hg ci -m "$comment"
