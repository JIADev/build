
	param($siteDir)
	$webConfigPath= "\\sparrow\J6\QA_SITES\\" + $siteDir+ "\employeeportal\web.config"
	$backup = $webConfigPath + ".bak"
	$formXml = '<forms name="J6EmployeePortal" loginUrl="Login.aspx" />'

	# Get the content of the config file
	$xml = [xml](get-content $webConfigPath)

	#Save a backup of the current web.config
	$xml.Save($backup)
	
	#Change to forms authentication
	$xml.configuration."system.web".authentication.mode = "Forms"
	$xml.configuration."system.web".authentication.set_InnerXml($formXml)
	
	# Save Changes to web.config
	$xml.Save($webConfigPath)
	


