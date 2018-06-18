write-host ***********************************************************************************************
write-host *                       Populate the database with one account.                               *
write-host ***********************************************************************************************


function ExecuteGetValue($sql)
{
  er $sql > z.tmp  
  $value = [int] (Get-Content z.tmp)[-1]
  #write-host "[$sql] $value"
  Remove-Item z.tmp
  $value
}

function Execute($sql) {
  en $sql
}


$accountsCount = [int] (ExecuteGetValue "select count(*) as Count from [Genealogy].[Account]")
echo "$accountsCount account(s) found."
if ($accountsCount -gt 2) {
  Write-Host "More than two accounts found. This is not an empty database"
  Write-Host "Bailing..... (for your own protection)"
  break
}

write-host Inserting into [Genealogy].[Account]
Execute "INSERT INTO [Genealogy].[Account] ( [Code], [Name], [ReportName], [Country], [Currency], [AccountClass], [Email], [Placement], [FamilyName], [GivenName], [MiddleName], [Prefix], [Suffix], [KnownAs], [Website], [BirthDate], [Address], [Phone], [SMS], [Culture] ) VALUES ( '000007', 'James Bond', 'Bond, James Bond', 'US', null, '4', 'jcb@jenkon.com', '0', 'Bond', 'James', '', null, null, 'James Bond', null, '1970-01-01 00:00:00.000', null, '360-256-4400', '', '75' )"

	
write-host Finding new [Genealogy].[Account] ID
$accountId = (ExecuteGetValue "select id from [Genealogy].[Account] where code='000007'")
write-host ... $accountId



write-host Updating email address.
Execute "Update [Genealogy].[Account] set [Email]='jeremy.starcher@jenkon.com' where [Code]='000007'"

write-host Finding new [Genealogy].[Account] ID
$accountId = (ExecuteGetValue "select id from [Genealogy].[Account] where code='000007'")
write-host ... $accountId


write-host "Inserting user into [Security].[User] "
$l = "insert into [Security].[User] ([Code], [Account], [AccountCode], [Password], [Hint], [Active], [Culture], [MustChangePassword], [FailedPasswordLocked], [PasswordEncoding]) VALUES ('000007', '###', '000007', '$2a$10$YuaO7xB/9Phnh/VxVUeW9utIsbAVkQCsOq0QBZxH/kiNbcmrVr21K', 'test123', 1, 75, 0, 0, 'BCrypt')"
$l = $l -replace "###","$accountId"
echo $l
Execute $l


# write-host paused
# $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


write-host Finding new id from [Security].[User]
$secUserId = (ExecuteGetValue "select id from [Security].[User] where code='000007'")
write-host ... $secUserId


write-host "Adding user to [Security].[RoleUser]"
$l = "insert into [Security].[RoleUser] ([User], [Role]) VALUES (###, 2)"
$l = $l -replace "###","$secUserId"
echo New line: $l
Execute $l

$l = "insert into [Security].[RoleUser] ([User], [Role]) VALUES (###, 1)"
$l = $l -replace "###","$secUserId"
echo New line: $l
Execute $l

$l = "insert into [Security].[RoleUser] ([User], [Role]) VALUES (###, 4)"
$l = $l -replace "###","$secUserId"
echo New line: $l
Execute $l

$l = "insert into [Security].[RoleUser] ([User], [Role]) VALUES (###, 17)"
$l = $l -replace "###","$secUserId"
echo New line: $l
Execute $l

write-host "Adding user to [Genealogy].[AccountPreference] "

$l = "insert into [Genealogy].[AccountPreference] ([Account], [Key], [Value]) VALUES (###, 'PlacementOption', null)"
$l = $l -replace "###","$accountId"
Execute "insert into [Security].[RoleAccountClass] ([AccountClass], [Role]) VALUES (###, 'PlacementOption', null)"


$l = "insert into [Genealogy].[ActivityCenter] ([Code], [Account], [Number], [JoinDate], [RenewalDate], [ModifiedDate], [PlaceHolder]) VALUES (###, ---, 1, '2007-01-30 00:00:00.000', '2008-01-23 00:00:00.000', '2013-01-29 16:09:36.367', 0)"
$l = $l -replace "###","$secUserId"
$l = $l -replace "---","$accountId"
write-host $l
Execute $l


