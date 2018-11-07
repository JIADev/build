<#
.SYNOPSIS
  Completely initializes and builds the j6 engine core with protect steps.
.DESCRIPTION
  Completely initializes and builds the j6 engine core with protect steps.

  1. Checkout base j6 version
  2. Checkout enginecore branch into .\EngineCore
  3. Optionally set feature.xml and assemblyinfo.cs versions
	4. Update nuget package.config for engine (.\.nuget\jenkon\packages.config)
  5. Build j6
  6. Feature build engine core: (Feature.exe build EngineCore)
  7. Create EngineCore Nuget packages
  8. Protect Nuget Packages

.PARAMETER ignoreVS
  Allows this script to run when Visual Studio is open.

  Note: This should only be used when there are OTHER projects open in VS.
.PARAMETER workFolder
  Folder (usually under c:\dev) that should be used for building
.PARAMETER j6Branch
  Branch name of base j6 code that engine will use for dependencies (genealogy, 
  salesorder...)
  
  This should probably be your main working branch for your project.
.PARAMETER startingEngineBranch
  Branch name from the EngineCore repository that will be used as a basis for 
  your build. If you are changing the version, a new branch will be created 
  FROM this branch with your new version number
.PARAMETER customerDriver
  Name of the customer driver folder used to build j6 (ex: CUST2097PL)
.PARAMETER DatabaseName
  Name of DB to use for build (should probably be a new DB name)
  This DB wont be used for testing or actually running j6 - just for building.
.PARAMETER redisId
  The ID number of the redis db to use for building.
.PARAMETER newVersion
  If your intent is to create a new version of the engine core code, then
  specify the version here (ex: 7.8.1.0).

  The actual nuget and branch names will also include your customer driver name.
  Example Branch: 7.8.1.0_CUST2097PL
  Example Nuget Name: j6.EngineCore.Logic.CUST2097PL.7.8.1.0.nupkg
.PARAMETER skipBuild
  If you are using a workfolder that already has been built, you can skip 
  the lengthy j6 build step with this parameter.

.EXAMPLE
  PS C:\> jcmd BuildEngineCore
.NOTES
  Created by Richard Carruthers on 11/01/2018
#>
param(
  [switch]$ignoreVS = $false,
  [string]$workFolder = "c:\dev\EngineBuild_2",
  [string]$j6Branch = "7.8.0",
  [string]$startingEngineBranch = "7.7.0.5_NP1.1",
  [string]$customerDriver = "CUST1002",
  [string]$databaseName = "CUST1002_EngineCore",
  [string]$redisId = 10,
  [string]$newVersion = $null,
  [switch]$skipBuild = $false
)
. "$PSScriptRoot\_shared\common.ps1"
. "$PSScriptRoot\_shared\common-web.ps1"
. "$PSScriptRoot\_shared\jposhlib\Common-Process.ps1"
. "$PSScriptRoot\_shared\jposhlib\Common-J6.ps1"

function ValidateEnv()
{
  if ($ignoreVS -eq $false)
  {
    $vsProcesses = Get-Process | Where-Object {($_.Name -eq "devenv") -and ($_.mainWindowTItle.StartsWith('all - Microsoft')) }
    if ($vsProcesses)
    {
      Throw "Please close all Visual Studio instances for j6 (All.sln) before running this script!"
    }
  }
}

function UpdateEngineCoreNugetReference([string] $driver, [string] $version)
{
  $content = 
@'
  "<?xml version="1.0" encoding="utf-8"?>
  <packages>
    <package id="[1]" version="[2]" targetFramework="net462" />
    <package id="[3]" version="[4]" targetFramework="net462" />
  </packages>"
'@

  $content = $content -replace "[1]", "j6.EngineCore.Logic.$driver"
  $content = $content -replace "[2]", "$version"
  $content = $content -replace "[3]", "j6.EngineCore.Realtime.$driver"
  $content = $content -replace "[4]", "$version"

  $file = Join-Path $workFolder ".nuget\jenkon\packages.config"
  $content | Set-Content $file -Encoding UTF8
}


function ProtectNugets()
{
  try
  {
      $infile = "C:\temp\a.nupkg"
      $outfile = "C:\temp\b.nupkg"
      #$uri = "http://fileprocessor.jenkon.local/api/process"
      $uri = "http://jia-jenkins1.jenkon.com/protect/api/process"
      Get-ChildItem $infile | Send-MultiPartFormToApi -Uri $uri -OutFile $outfile -HttpMethod "Post"
  }
  catch
  {
      Write-Host $_.Exception.Message -ForegroundColor Red
      Exit 1
  }
}

function CheckNewVersionDefault()
{
  if ($null -eq $newVersion -or $newVersion.Length -eq 0) #read it from main assemblyinfo.cs
  {
    $assemblyInfoFile = Join-Path $workFolder "j6\Core\private\AssemblyVersion.cs"
    $version = GetAssemblyInfoVersion $assemblyInfoFile

    write-host "Using version $version from file $assemblyInfoFile" -ForegroundColor Yellow

    return $version
  }

  return $newVersion
}

function NugetPack([string] $version)
{
  if (!(Test-Path $outputFolder))
  {
    New-Item -ItemType Directory -Force -Path $outputFolder
  }

  ".\.nuget\nuget.exe PACK `"$engineCoreFolder\Private\Project\j6.EngineCore.Logic\j6.EngineCore.Logic.csproj`" -Version `"$version`" -OutputDirectory `"$outputFolder`" -Properties `"branch=$customerDriver`""


  & ".\.nuget\nuget.exe" PACK "$engineCoreFolder\Private\Project\j6.EngineCore.Logic\j6.EngineCore.Logic.csproj" -Version "$version" -OutputDirectory "$outputFolder" -Properties "branch=$customerDriver"
  & ".\.nuget\nuget.exe" PACK "$engineCoreFolder\Private\Project\j6.EngineCore.realtime\j6.EngineCore.realtime.csproj" -Version "$version" -OutputDirectory "$outputFolder" -Properties "branch=$customerDriver"
}

function NugetProtect()
{

}




$engineCoreFolder = Join-Path $workFolder "EngineCore"
$outputFolder = Join-Path $workFolder "build\nuget_packages"

Ensure-IsPowershellMinVersion5
#Ensure-IsJ6DevRootFolder
#Ensure-IsJ6Console
Ensure-VisualStudioNotRunning "all"
$commands = @()

#cloning - have to do this first and separate because we may need to read the version from these files
if (!(Test-Path $workFolder))
{
  $commands += @{name="Cloning j6"; command="git.exe"; args=@("clone","-b", "$j6Branch", "https://jenkon.visualstudio.com/j6%20Core%20Product/_git/active","$workFolder")}
}

if (!(Test-Path $engineCoreFolder))
{
  $commands += @{name="Cloning EngineCore"; command="git.exe"; args=@("clone","-b", "$startingEngineBranch", "https://jenkon.visualstudio.com/j6%20Core%20Product/_git/EngineCore","$engineCoreFolder")}
}

ExecuteCommandsWithStatus $commands "Build Engine Core - Clones"


#once cloned, now read the version and do everything else
$commands = @()

 #get the version, if needed
 $version = CheckNewVersionDefault

 #check the original param to see if it was "default"
if (($null -ne $newVersion) -and ($newVersion.Length -gt 0))
{
  $version = $newVersion

  $newBranch = $version+"_"+$customerDriver

  #create new version branch
  $commands += @{name="Change to EngineCore repo folder"; command="cd"; args=@("$engineCoreFolder")}
  $commands += @{name="Create Branch"; command="git.exe"; args=@("checkout","-b","$newBranch")}
  #$commands += @{name="Push Branch to Origin"; command="git.exe"; args=@("push","origin","$newBranch")}

  #set new j6 version
  $commands += @{name="Change dir to root folder"; command="cd"; args=@("..")}
  $commands += @{name="Set the version for root folder"; command="feature.exe"; args=@("setversion","$version")}

  $commands += @{name="Change dir to j6 folder"; command="cd"; args=@("j6")}
  $commands += @{name="Set the version for j6 folder"; command="feature.exe"; args=@("setversion","$version")}

  $commands += @{name="Change dir to the customers folder"; command="cd"; args=@("..\customers")}
  $commands += @{name="Set the version for customers folder"; command="feature.exe"; args=@("setversion","$version")}

  #update the nuget reference to point to the new version of the nuget packages that will be created later
  $commands += @{name="Update engine core nuget package config"; command="UpdateEngineCoreNugetReference"; args=@("$customerDriver","$version")}
}

$commands += @{name="Change to main repo folder"; command="cd"; args=@("$workFolder")}

#build j6 (possibly with new version), 
#but if version is not changed, and skipbuild = true, then do not build
if (($skipBuild -eq $false) -and (($null -ne $newVersion) -or ($newVersion.Length -eq 0)))
{
  $commands += @{name="jcmd configure"; command="jcmd.ps1"; args=@("configure", "$customerDriver","$databaseName","$redisId")}
  $commands += @{name="j fastbuild"; command="msbuild.exe"; args=@("/nologo","/t:fastbuild","j6.proj")}
}
$commands += @{name="feature build enginecore"; command="feature.exe"; args=@("build","EngineCore")}

#package nuget
$commands += @{name="nuget pack"; command="NugetPack"; args=@("$version")}
#$commands += @{name="nuget protect"; command="NugetProtect"; args=@("pack", "$engineCoreFolder/Private/Project/j6.EngineCore.realtime/j6.EngineCore.realtime.csproj", "-Version", "$version", "-OutputDirectory", "$outputFolder", "-Properties","branch=$customerDriver" )}

ExecuteCommandsWithStatus $commands "Build Engine Core - Building"
