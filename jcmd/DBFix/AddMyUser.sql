-- Adds current logged in domain user to DB
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
-- Ensure Jenkon\[your name] exists
------------------------------------------------------------------------------------
--select user_name(),suser_sname()

declare @uid int, @rid int, @exists int

--select * from Security.[User] where code like '%jenkon%'
--select * from Security.[User] where code = suser_sname()

if (suser_sname() not like 'jenkon\%')
RAISERROR ('Current user must be in the jenkon domain!', 51000, 1)

select @uid = id from Security.[User] where code = suser_sname()

if (@uid is not null) print 'User exists: '+convert(varchar, @uid)

if (@uid is null)
begin
	insert into Security.[User] 
	(Code, Account, Password, Hint, Active, Culture, MustChangePassword, FailedPasswordLocked, PasswordEncoding, InheritsAccountTypeRoles, InheritsTitleRoles)
	values (suser_sname(), null, 'test', null, 1, 75, 0, 0, 'NONE', 1, 1)

end

------------------------------------------------------------------------------------
-- Ensure Jenkon\[your name] has proper roles
------------------------------------------------------------------------------------
declare @user nvarchar(100)
select @user = suser_sname();

-- select * from security.role
exec #AddRoleToUser @user = @user, @role = 'administrators'
exec #AddRoleToUser @user = @user, @role = 'employee'
exec #AddRoleToUser @user = @user, @role = 'j6-sysadmin'
exec #AddRoleToUser @user = @user, @role = 'RealTimeService'
exec #AddRoleToUser @user = @user, @role = 'API'
go
