-- Sets user PW to "test" (except domain and api users)
Print 'Setting user passwords to "test" (except domain and api users)'
update Security.[User] 
set 
    [Password] = 'test', -- HEX must be lowercased, or it wont decode properly
    PasswordEncoding = 'NONE', 
    Hint = 'test', 
    Active = 1, MustChangePassword = 0, FailedPasswordLocked = 0
where 
    Code not like '%\%' -- dont affect system accounts which will have a backslash
    and Code not like 'APIUser%' --dont change api user password
