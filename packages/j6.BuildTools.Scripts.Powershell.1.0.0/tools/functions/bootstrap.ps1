set-psdebug -strict

. build-cc.ps1


function build-j6debug {
	# ---- start of main ---
	$buildroot = [string](pwd)
	$workingDir=get-workingdirectory

	init-fromsvn $workingDir (get-buildsettings).settings.configurations.svnRepository
	build-cc

	#just in case another script left us somewhere unexpected
	cd $buildroot

	$releasePath = get-releasedirectory
	validate-command {remove-dir $releasePath} "Unable to delete $releasePath"
	validate-command {copy-dir $workingDir $releasePath} "Unable to copy to $releasePath"
	validate-command {remove-dir $workingDir} "Unable to cleanup folder"
}
