set-psdebug -strict

. core.ps1

$svnHost="http://source.jenkon.com/svn"
$svnBuildConfigRoot="/build/config"
$svnCustomerConfigRoot="/custom"


function exec-svn {svn.exe $Args --username build --password build --no-auth-cache --non-interactive  2>$null}

function svn-exists {
	param($url=$(throw "specify url to check"))
	trap{return $false}
	$r=[xml](exec-svn info $url --xml)
	if($r.info.entry){return $r.info.entry}
	return $false
}

function get-fromsvn {
	param(
		$repopath=$(throw "specify path to export"),
		$destination=".",
		$method="export",
		$repohost=$svnHost
	)
	$url=("{0}{1}" -f $repohost,$repopath)
	exec-svn $method $url $destination
}

function get-xmlfromsvn {
	param($url=$(throw "specify url"))
	$ret = [xml](exec-svn cat $url)
	if($ret){return $ret}
	else{
		log-warning "$url does not exist"
		return $null
	}
}

function get-lastsvnentry {
	param($url=$(throw "specify url"))
    trap { return 0; }
    if (svn-exists $url) {
	    return [xml](exec-svn log $url --xml --limit 1)
    } else {
        return 0
    }
}



##
## Config File Functions
##

function get-config {
	param($configName=$(throw "specify config file"))
	$url=("{0}{1}/{2}.xml" -f $svnHost,$svnBuildConfigRoot,$configName)
	return (get-xmlfromsvn $url)
}

function get-hostconfig {
	$ret=get-config ($env:COMPUTERNAME.ToLower())
	if(-not($ret)){$ret=get-config "default-machine"}
	return $ret
}

function get-availablefeatures {
	param($version)
	$ret=get-config ("{0}-features" -f $version)
	if(-not($ret)){$ret=get-config "latest-features"}
	return $ret
}

function merge-hostconfig {
	param(
		$config=$(throw "must specify base config"),
		$hostconfig=$(get-hostconfig)
	)
	$cfs=$config.settings.configurations
	if($cfs){
		$root=$hostconfig.config.debug.buildroot
		if("release" -eq ($cfs.configuration).ToLower()){
			$root=$hostconfig.config.release.buildroot
			$global:configuration="Release"
		}
		log ("BuildRoot: {0}" -f $root)
		if($cfs.buildDirectory){
			log ("Previous buildDirectory: {0}" -f $cfs.buildDirectory)
			$cfs.buildDirectory=[string](join-path $root ($cfs.buildDirectory))
			log ("New buildDirectory: {0}" -f $cfs.buildDirectory)
		}
		if($cfs.releaseDirectory){
			log ("Previous releaseDirectory: {0}" -f $cfs.releaseDirectory)
			$cfs.releaseDirectory=[string](join-path $root ($cfs.releaseDirectory))
			log ("New releaseDirectory: {0}" -f $cfs.releaseDirectory)
		}
	}
	return $config
}

function get-customerconfig {
	param($Customer="IH00000",$File="CustomerFeatures")
	$url = ("{0}{1}/{2}/Config/{3}.xml" -f $svnHost,$svnCustomerConfigRoot,$Customer,$File)
	return (merge-hostconfig (get-xmlfromsvn $url))
}

function get-releaseconfig {
	param($Customer="IH00000")
	return get-customerconfig $Customer "ReleaseConfig"
}

function get-autodeployconfig {
	param($Customer="IH00000")
	return get-customerconfig $Customer "AutoDeploy"
}

function get-debugconfig {
	param($Customer="IH00000")
	return get-customerconfig $Customer "DebugConfig"
}

function get-customerfeatures {
	param($Customer="IH00000")
	return get-customerconfig $Customer "CustomerFeatures"
}

function get-optionalpatches {
	param($Customer="IH00000")
	return get-customerconfig $Customer "OptionalPatches"
}


set-alias -name "tsvn" -value "C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe"
function tsvn-base { param($path=".",$command="log"); $path=(resolve-path $path); tsvn /command:$command /path:"$path" /notempfile /closeonend $Args }
function tsvn-log { param($path="."); tsvn-base -path $path -command "log" }
function tsvn-browse { param($path="."); tsvn-base -path $path -command "repobrowser" }
function tsvn-blame { param($path="."); tsvn-base -path $path -command "blame" /startrev:1 /endrev:-1 }
function tsvn-compare { param($path="."); tsvn-base -path $path -command "diff" }
function tsvn-revert { param($path="."); tsvn-base -path $path -command "revert" }
function tsvn-delete { param($path="."); tsvn-base -path $path -command "remove" }
function tsvn-add { param($path="."); tsvn-base -path $path -command "add" }
function tsvn-update { param($path="."); tsvn-base -path $path -command "update" }
function tsvn-commit { param($path="."); tsvn-base -path $path -command "commit" }
function tsvn-cleanup { param($path="."); tsvn-base -path $path -command "cleanup" }
function tsvn-updateall { param($path=".");$paths = (get-childitem -fo -r -inc .svn $path|%{"`"{0}`"" -f $_.FullName}); write-host $paths; write-host $paths.Count ; tsvn-update ([string]::Join('*',$paths));}
function tsvn-status { param($path="."); tsvn-base -path $path -command "repostatus"; }
function tsvn-patch { param($path="."); tsvn-base -path $path -command "createpatch"; }
function tsvn-conflict { param($path="."); tsvn-base -path $path -command "conflicteditor"; }
function tsvn-resolve { param($path="."); tsvn-base -path $path -command "resolve"; }
