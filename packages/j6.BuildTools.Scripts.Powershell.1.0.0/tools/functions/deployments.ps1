set-psdebug -strict

. core.ps1
. build.ps1

function deploy-all {
	param($script:customer=$((get-buildsettings).settings.customer))
	$settings=(get-autodeployconfig $script:customer).settings.deployments
	cd (get-releasedirectory)
	log ("current directory: {0}" -f (pwd))
	($settings.site)|%{
		create-ifelementmissing $_ "destination"
		create-ifelementmissing $_ "source"
		$_.destination = [string](join-path $settings.destination_base $_.destination)
		$_.source = [string](join-path $settings.source_base $_.source)
		deploy-site $_
	}
}

function deploy-site {
	param($site=$(throw "pass site node in"))
	switch ($site.action) {

		{$_.type -eq 'custom'}
		{ invoke-expression $_.command }

		{$_.type -eq 'artifact'}
		{
			$from = (join-path $site.source $_.source)
			$to = (join-path $site.destination $_.destination)
			if(-not (test-path (split-path $to))){
				warn ("{0} doesn't exist... creating" -f (split-path $to))
				mkdir -force (split-path $to)
			}
			log ("copying: {0} to {1}" -f $from,$to)
			cp -path $from -destination $to -recurse -force -ErrorAction stop
		}

		default
		{ log-warning "Unknown Command" }
	}

	if($site.sql) {
		$settingspath = join-path $site.destination "sql-settings.xml"
		(generate-sqlsettings $site).Save($settingspath)
		run-patches $site
	}
}

function run-patches {
	param($site)
	$settings=get-buildsettings
	$here = [string](pwd)
	log "Loading patches from $here"
	if (!(feature list "--dir=$here")) {
		log ("CustomPatches for {0}" -f $settings.settings.customer)
		$cust = join-path 'data\CustomPatches' $settings.settings.customer
		$defaultPath = resolve-path (join-path $site.source 'data\patches')
		$customPath =  resolve-path (join-path $site.source $cust)
		$sharedPath = resolve-path (join-path $site.source 'shared')
		$td = (join-path $site.source "temppatch")
		if(test-path $td){rm -r -force $td}
		$tempdir = (mkdir $td).FullName

		$defpatches = ""
		$custpatches = ""
		if(test-path $defaultPath){$defpatches=$defaultPath}
		if(test-path $customPath){$custpatches=$customPath}
		if(test-path $sharedPath){
			cp (join-path $site.destination "sql-settings.xml") (join-path $tempdir "build-settings.xml")
			cp -r -force $sharedPath (join-path $tempdir "shared")
		}

		log "loading patches for $defpatches $custpatches"
		$patcher = join-path $tempdir "shared\loadpatch.exe"
		&$patcher $defpatches $custpatches
		if(-not $?){throw "loadpatch failed"}
		rm -r -force $tempdir
	} else {
		feature install --patch "--dir=$here" --verbose
	}
}

function generate-sqlsettings {
	param($site)
	$ret = @"
<?xml version='1.0'?>
<settings>
<sql>
	<server>{0}</server>
	<database>{1}</database>
	<uid>{2}</uid>
	<pwd>{3}</pwd>
</sql>
</settings>

"@
	return [xml]($ret -f $site.sql.server,$site.sql.database,$site.sql.uid,$site.sql.pwd)
}

function remove-directory {
	param($directory)
	if(test-path $directory) {
		log-warning ("deleting {0}" -f $directory)
		remove-item -recurse -force $directory -erroraction stop
	} else {
		log-warning ("{0} didn't exist" -f $directory)
	}
}

function clean-webconfig {
	param($webconfig)
	log ("getting web.config from {0}" -f $webconfig)
	$wc = [xml](gc $webconfig)
	$assemblies = $wc.configuration.Item("system.web").compilation.assemblies.add
	$assemblies | ?{$_.assembly -match "stdole"} | %{[void]($_.get_ParentNode().RemoveChild($_))}
	$wc.Save($webconfig)
}

function make-versionpage {
	$settings=get-buildsettings
  $title = "Version Info - deployed $((get-date).ToShortDateString()) $((get-date).ToShortTimeString())"
	return @"
<html>
	<head><title>$($title)</title></head>
	<body>
		<h3>$($title)</h3>
		<pre>
$([string]::Join([Environment]::NewLine,(exec-svn info $settings.settings.configurations.svnRepository)))
		</pre>
	</body>
</html>
"@
}

