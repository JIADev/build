-- Adds default APIUser1 to database

------------------------------------------------------------------------------------
-- Temporary Helper Procedures
------------------------------------------------------------------------------------

if object_id('tempdb..#AddRoleToUser') is not null
begin
	drop procedure #AddRoleToUser
end
go

create procedure #AddRoleToUser 
	@user varchar(100), 
	@role varchar(100)
AS
BEGIN
	declare @uid int, @rid int, @exists int, @roleToEnsure nvarchar(100)

	select @uid = id from Security.[User] where code = @user

	select @rid = id from Security.Role where code = @role
	if (@rid is null) 
	begin
		declare @message nvarchar(1000)
		select @message = @role + ' role could not be found? Not good. You may need to J PATCH.';
		RAISERROR (@message, 51000, 1)
	end

	select @exists = 1 from Security.RoleUser where [user] = @uid and role = @rid
	if (@exists is not null) print @role + ' already existed!'

	if (@exists is null)
	begin
		print 'ADDING ' + @role + ' ROLE'
		insert into Security.RoleUser ([user], role) values (@uid, @rid)
		select @exists = 1 from Security.RoleUser where [user] = @uid and role = @rid
		if (@exists is null)
		begin
			declare @message2 nvarchar(1000)
			select @message2 = @role + ' role was not correctly added to local account';			
			RAISERROR (@message2, 51000, 1)
		end
		print @role + ' has been added to the local account'
	end
END
go

------------------------------------------------------------------------------------
-- Logic
------------------------------------------------------------------------------------

declare @uid int, @rid int, @exists int, @api_username nvarchar(100)

select @api_username = 'APIUser1'

select @uid = id from [Security].[User] where code = @api_username

if (@uid is not null) 
begin
    delete from [Security].[Password] where [User] = @uid
    delete from [Security].[User] where id = @uid
end

insert into [Security].[User] 
(Code, Account, Password, Hint, Active, Culture, MustChangePassword, FailedPasswordLocked, PasswordEncoding, InheritsAccountTypeRoles, InheritsTitleRoles)
values (@api_username, null, 'Test@@1234', null, 1, 75, 0, 0, 'NONE', 1, 1)

exec #AddRoleToUser @user = @api_username, @role = 'employee'
exec #AddRoleToUser @user = @api_username, @role = 'API'