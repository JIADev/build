$sourcerepo = ''
$customernumber = ''
$changeset = ''
$tags = ''
$args | foreach {
      if($sourcerepo -eq ''){
        $sourcerepo = $_
      } else {
      	if($customernumber -eq ''){
	  $customernumber = $_
      	} else {
      	  if($changeset -eq ''){
	  	$changeset = $_
	} else {
    	  $tags = $tags + $_ + ';'
    	}
    }
  }
}

if($tags -eq '') {
	Write-Host "Usage: labelbuild.ps1 <active/prod> <customer_number> <changeset_or_label_id> <environment_list_separated_by_semicolon>"
	Write-Host "Example: labelbuild.ps1 active 2094 9f7d3d7bb19c INT UAT"
	Exit
}
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$msbuild = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
$parameters = '/p:Preview=false;InitSourceRepo="' + [string]$sourcerepo + '";CustomerNumber="' + [string]$customernumber + '";Changeset="' + [string]$changeset + '";Tags="' + [string]$tags + '"'
& $msbuild /t:LabelBuild $parameters $scriptPath\buildtools.proj
