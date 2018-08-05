<#
.SYNOPSIS
  Executes Webpack build target for PWS.
.DESCRIPTION
  Executes Webpack build target for PWS.
.EXAMPLE
  PS C:\> jcmd webpack
.NOTES
  Created by Richard Carruthers on 08/05/18
#>

if (Test-Path ".\Site\WebPWS\WebPWS.csproj") {
  & "msbuild.exe" "Site\WebPWS\WebPWS.csproj" "/t:Webpack"
}