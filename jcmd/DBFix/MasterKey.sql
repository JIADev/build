-- Resets the masterkey
DECLARE @brokerSql VARCHAR(200) 
SET @brokerSql = 'ALTER DATABASE [' + DB_NAME() + '] SET NEW_BROKER WITH ROLLBACK IMMEDIATE' 
EXEC (@brokerSql) 
GO

begin try
    begin try
        OPEN MASTER KEY DECRYPTION BY PASSWORD = 'odljirrzV0nCdhscxel.thzrmsFT7_&#$!~<SdjrZSlJwq<g'  
        DROP SYMMETRIC KEY J6_SYMMETRIC_KEY 
        DROP CERTIFICATE J6Certificate 
        DROP MASTER KEY
    end try
    begin catch
    end catch

    begin try
        OPEN MASTER KEY DECRYPTION BY PASSWORD = '$tarting_)6^^aster|<ey|>ass'
        DROP SYMMETRIC KEY J6_SYMMETRIC_KEY 
        DROP CERTIFICATE J6Certificate 
        DROP MASTER KEY
    end try
    begin catch
    end catch

    begin try
        OPEN MASTER KEY DECRYPTION BY PASSWORD = 'myPassw0rd!'
        DROP SYMMETRIC KEY J6_SYMMETRIC_KEY 
        DROP CERTIFICATE J6Certificate 
        DROP MASTER KEY
    end try
    begin catch
    end catch

end try
begin catch
end catch

CREATE MASTER KEY ENCRYPTION BY PASSWORD = '$tarting_)6^^aster|<ey|>ass'
GO

ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY  
GO 

declare @masterKeySQL nvarchar(1000)
set @masterKeySQL = 'CREATE CERTIFICATE J6Certificate WITH SUBJECT = ''Certificate for encryption to use for J6'''
EXEC (@masterKeySQL)
GO 

declare @masterKeySQL nvarchar(1000)
set @masterKeySQL = 'CREATE SYMMETRIC KEY J6_SYMMETRIC_KEY WITH ALGORITHM = AES_256 ENCRYPTION BY CERTIFICATE J6Certificate '
EXEC (@masterKeySQL)
GO

