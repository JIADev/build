-- Scrubs a DB for Dev (Merchant Acct, Emails, Settings)
------------------------------------------------------------------------------------
-- Temporary Helper Procedures
------------------------------------------------------------------------------------

if object_id('tempdb..#SetAppSetting') is not null
begin
	drop procedure #SetAppSetting
end
go

create procedure #SetAppSetting
	@settingName nvarchar(100),
	@value nvarchar(1000)
as
begin
	declare @sid int, @vid int

	select @sid = id from AppSetting a where a.Name = @settingName

	if (@sid is null)
	begin
		declare @message nvarchar(1000)
		select @message = 'Setting "'+@settingName+'" not found';
		RAISERROR (@message, 51000, 1)
	end
	
	--clear off any user values
	delete from AppSettingValue where AppSetting = @sid and UserOverride = 1

	--get any existing jenkon values
	select @vid = id from AppSettingValue where AppSetting = @sid and IsOverride = 1

	if (@vid is null)
	begin
		insert into AppSettingValue (AppSetting, Value, IsOverride, UserOverride) values (@sid, @value, 1, 0)
	end
	else
	begin
		update AppSettingValue set Value = @value where id = @vid and IsOverride = 1
	end

	PRINT @settingName +' = ' + @value
end
go

------------------------------------------------------------------------------------
-- Logic
------------------------------------------------------------------------------------

declare @myemail nvarchar(1000)
select @myemail = replace(SUSER_SNAME(), 'JENKON\', '')+'@jenkon.com'

--reset emails
update Genealogy.Account set Email = @myemail
update Genealogy.EmailAddress set Address = @myemail

exec #SetAppSetting 'CustomerServiceEmail', @myemail
exec #SetAppSetting 'Communication_Message_DefaultSMSForFrom', @myemail
exec #SetAppSetting 'Communication_Message_DefaultEmailForFrom', @myemail

-- point the report server back to localhost
exec #SetAppSetting 'ReportServerUrl', 'http://localhost/ReportServer'
exec #SetAppSetting 'ReportServerPathPrefix', '/j6/'

-- update qual settings for running local
exec #SetAppSetting 'Qualification_Publish_With_Partitions', false
exec #SetAppSetting 'Qualification_Compress_Data', false

--force the production flag back to false
exec #SetAppSetting 'ProductionEnvironment', false

--reset propay back to UAT/testing
DECLARE @creds NVARCHAR(max)

select @creds=[Credentials] from payment.MerchantAccount where code = 'PPSG'
select @creds = replace(@creds, 'pfmimic.propay.com', 'pfmimictest.propay.com')
select @creds = replace(@creds, 'https://protectpay.propay.com/API/SPS.svc', 'https://protectpaytest.propay.com/API/SPS.svc')

update Payment.MerchantAccount set [Credentials]=@creds where code = 'PPSG'	




