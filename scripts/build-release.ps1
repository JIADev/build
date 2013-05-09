set-psdebug -strict

. build-cc.ps1

function veil-dlls {
	log "CodeVeil begin"
	$script:obfuscateCmd = "C:\Program Files (x86)\XHEO\CodeVeil\v1.0\cve.exe"
	if(test-path $script:obfuscateCmd) {
		(ls J6*.dll,Jenkon*.dll) | %{ & $script:obfuscateCmd $_ }
		cp -force veiled\* .
		rm -r -force veiled
	}
	log "CodeVeil end"
}

function build-j6release {
	param(
		$config = (get-buildsettings),
		$conf = $config.settings.configurations,
		$sql = $config.settings.sql,
		$buildroot=$conf.buildDirectory,
		$svnpath = $conf.svnRepository,
		$j6version = (get-version $svnpath),
		$builddir = (join-path $buildroot $conf.workingDirectory),
		$customer = $config.settings.customer,
		$dbserver = $sql.server,
		$db = $sql.database,
		$dbuser = $sql.uid,
		$dbpass = $sql.pwd,
		$tiers = $conf.remoteTiersDirectory,
		$dbremotedir = $conf.dbDirAsRemote,
		$dblocaldir = $conf.dbDirAsLocal
	)

	$global:configuration = "Release"

	pushd $buildroot
		# sync down source
		init-fromsvn $builddir $svnpath "export"
		pushd $builddir
			# set assemblyversion.cs properties to reflect version
			update-assemblyversions -version $j6version
			# configure settings doc
			init-j6 `
				-server $dbserver -db $db -user $dbuser -pass $dbpass `
				-customer $customer -tiers $tiers -remote $dbremotedir -local $dblocaldir
			# clean database from subversion
			revert-database
			# remove non required/configured features from build
			prepare-features -working $builddir
			# clean generation of data layer
			generate-nettiers
			build-nettiers
			# begin building libraries
			build-core
			build-business
			build-sis
			build-customsolutions
			clean-webconfigs
			
			# obfuscate/encrypt dll's
			pushd Shared
				veil-dlls
			popd #Shared

			# we'll uncomment this when it works...
			#build-installers

			# build test code, web code, etc. dependent on veiled libs
			build-testing
			generate-webservice
			build-web
		popd #$builddir
	popd #c:\
}





function build-j6releaseold {

	$error.clear()
	$global:isInteractiveBuild = $false
	$global:configuration = "Release"
	$releaseDir=get-releasedirectory
	$curDir=[string](pwd)

	$buildLogDir=join-path (pwd) "release-build-logs"
	if(test-path $buildLogDir){$null=rm $buildLogDir}
	if(-not(test-path $buildLogDir)){$null=mkdir $buildLogDir}

	if(test-path (join-path $releaseDir "shared")) {
		log "removing pdbs from $releaseDir\shared"
		(ls "$releaseDir\shared" -r -inc *.pdb)|%{rm $_}
	}

	cd $releaseDir

	log "Building in release mode"
	prepare-features -working $releaseDir
	build-projectswithlogger $preLoadPatchBuilds $false
	build-projectswithlogger $postLoadPatchBuilds $false

	build-installers

	$obfuscateCmd = "C:\Program Files (x86)\XHEO\CodeVeil\v1.0\cve.exe"

	if(test-path $obfuscateCmd) {
		log "Obfuscating"
		pushd shared
		(ls J6*.dll,Jenkon*.dll) | %{ & $obfuscateCmd $_ }
		log "Copying obfuscated files over originals"
		cp -force veiled\* .
		popd
	} else { log-warning "CODE NOT OBFUSCATED" }


	cd $curDir
	return $error.count
}

