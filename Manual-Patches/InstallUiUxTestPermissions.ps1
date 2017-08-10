write-host "***********************************************************************************************"
write-host "*                               Installing UiUx Test Permissions                              *"
write-host "***********************************************************************************************"


function ExecuteGetValue($sql)
{
  er $sql > z.tmp  
  $value = [int] (Get-Content z.tmp)[-1]
  write-host "[$sql] $value"
  Remove-Item z.tmp
  $value
}

function Execute($sql) {
  en $sql
}


$permissionName = "UiUxPassWithPatches"
$l = "INSERT INTO [Security].[Permission] ([Code], [Description]) VALUES( '###', 'UiUxTestPermission - Added by script')"
$l = $l -replace "###","$permissionName"
Execute $l

$l = "SELECT [Id] FROM [Security].[Permission] WHERE [Code] = '###'"
$l = $l -replace "###","$permissionName"
$permissionNameId = [int] (ExecuteGetValue $l)

Write-Host "ID Found ... $permissionNameId"


$everyoneId = [int] (ExecuteGetValue "SELECT [Id] FROM [Security].[Role] where [Code] = 'Everyone'")
Write-Host "Everyone's ID = $everyoneId"


$portalId = [int] (ExecuteGetValue "SELECT  [Id]  FROM [Security].[Role] where [Code] = 'business-portal'")
Write-Host "Portal's ID = $portalId"

Write-Host Adding rows to [Security].[RolePermission]
$ins = "INSERT INTO [Security].[RolePermission] ([Role], [Permission], [Grant]) VALUES (##, --, 1)"
$l = $ins -replace "##","$everyoneId"
$l = $l -replace "--","$permissionNameId"
Execute $l

$l = $ins -replace "##","$portalId"
$l = $l -replace "--","$permissionNameId"
Execute $l


Write-Host "Database Updated"
Write-Host "Don't forget to Flush Redit and restart your app-pool."

