set-psdebug -strict

. core.ps1
. sql-utils.ps1

$sql = "

	DECLARE @enable AS VARCHAR(200)
	SET @enable = 'ALTER DATABASE ' + QUOTENAME(DB_NAME()) + ' SET NEW_BROKER WITH ROLLBACK IMMEDIATE'
	EXEC(@enable)

"

$query = " SELECT is_broker_enabled FROM sys.databases WHERE name = db_name() "

[void](en $sql)
$res = (er $query)
log ( "Result of query: '{0}' is {1}" -f $query,$res )
$res|?{$_ -isnot [int]}|fl


