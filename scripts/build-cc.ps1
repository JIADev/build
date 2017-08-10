set-psdebug -strict

. build.ps1

function build-cc {
	param([string]$logDir ="build-logs")
	profile-process "Build-CC" {
		Log ("starting j6 build")
		$settings = (get-buildsettings).settings
		$workingDir = $settings.configurations.workingDirectory
		$svnRepUrl =  $settings.configurations.svnRepository

		validate-command {
			cp $workingDir/build/ThoughtWorks.CruiseControl.MSBuild.dll $workingDir
		} "Unable to copy build logger"

		$rootDir = (pwd).path
		$buildLogDir = join-path $rootDir $logDir
		if(test-path $buildLogDir) { rm $buildLogDir\* }
		cd $workingDir
		dropandreplace-database
		cleanbuild-j6
	}
}


