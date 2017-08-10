set-psdebug -strict

. core.ps1

$script:logfile = $()

function log-tests {
	param($msg = "---MARK---")
	if (-not($script:logfile)) {
		$logDir = join-path $baseDir "unittest-logs"
		remove-dir $logDir
		[void](mkdir $logDir)
		$dt = "{0}-log.txt" -f (get-datestamp);
		$script:logfile = join-path $logDir $dt
	}
	log $msg $script:logfile
}

function test-assembly {
	param($filename)

	$testConsole = ""
	if (test-path "xunit.console.exe") {
		$testConsole = "xUnit"
		&./xunit.console.exe $filename /nunit nunit.$filename.xml
		if (test-path "nunit.$filename.xml") {
			$output = (gc nunit.$filename.xml);
			if (-not ($output -is [System.Object[]])){
				$output = $output.split();
			} 
		} else {
			throw ("{0} did not generate an output file." -f $filename)
		}
	} 
	else {
		$testConsole = "NUnit"
		$output = & $g_NunitPath  /nologo /xmlconsole $filename
		# need to strip all output until we get to the
		# root of the xml document
		$outputLength = $output.length-1
		$startIndex = 0

		if (-not ($output -is [System.Object[]])){
			throw "--nunit output for $filename is not xml: $output"
		}

		while( `
			$startIndex -lt $outputLength `
			-and `
			(-not ($output[$startIndex].ToString().startsWith("<?xml version="))) `
		){$startIndex++}

		if($startIndex -eq $outputLength){
			throw "--Unable to parse xml output for $filename : $output"
		}

		$output = $output[$startIndex..$outputLength]
	}
	if (-not($output -eq $NULL)) {
		$xml = [xml] $output

		$results = $xml["test-results"]

		$script:failures += $results.failures
		$script:total += $results.total
		$script:successes += ([int]$results.total - [int]$results.failures)
		$errors = "`n"
		$xml.SelectNodes("//failure") | foreach {
			$node = $_
			$parent = $node.get_ParentNode()
			$msg = $node["message"].get_InnerText() + "`n" + $node["stack-trace"].get_InnerText()
			$errors += $parent.name + ":" + $msg + "`n"
		}
		$timing = "`n"
		$xml.SelectNodes("//test-suite") | foreach {
			$node = $_
			$timing += [System.String]::Format("{0,10}", $node.time) + "`t" + $node.name + "`n"
		}
		log-tests ("$testConsole timing per namespace: $timing")
		# xUnit already logs the errors, only needed for NUnit
		if ($testConsole -eq "NUnit") {
			log-tests ("$filename results: " + ([int]$results.total - [int]$results.failures) + " successes, " +  $results.failures + " failures, " + $results."not-run" + " skipped. Errors: " + $errors)
		}
	}
}

function prepare-testdirectory {
	param([string]$searchPath, [string]$filter)
	remove-dir $script:testDir
	[void](mkdir $script:testDir)
	$testDir = "shared"
	if (test-path "internalshared") { $testdir = "internalshared" }
	[string[]]$tocopy=ls $testDir -r -i *.*

	$tocopy += ls $searchPath -r -i $filter

	function exists {
		param($p);
		$p=split-path $p -leaf -resolve
		$p=join-path $script:testDir $p
		return test-path $p
	}
	$tocopy|?{-not(exists $_)}|%{cp $_ $script:testDir}
}

function run-unittests {
	param([string]$searchPath = "./", [string]$filter = "*Test*.dll")
	$script:failures=0
	$script:errors=0
	$script:successes=0
	$script:total=0

	log "Preparing test directory"
	prepare-testdirectory $searchPath $filter
	log-util (" ") "write-host"
	pushd $script:testDir
	& {
		trap {popd}
		# test each dll in the testing folder
		$tests = (ls . -r -i $filter -exclude *nunit*.dll,*castle*.dll,timing-tests.dll)
		$tests|%{
			$script:filename=$_.fullname
			trap {
				log-util ("ERROR in {0}:`n{1}`n" -f $script:filename,$_.Exception.Message) "write-host"
				$script:errors+=1
				$script:total+=1
				continue;
			}
			if(-not (Is-ExcludedTest($_.fullname))) {
				log-util ("TESTING: {0}" -f $_.fullname) "write-host"
				test-assembly $_.Name
			} else {log-util ("EXCLUDING: {0}`n" -f $_.name) "write-host"}
		}
		log-util ("COMPLETE: There were $successes successes, $failures failures, and $errors errors running $total tests.`n") "write-host"
	}
	popd
}

function is-excludedtest {
	param($filename)
	"J6.EndToEnd.Tests.dll","J6.EarningsTest.dll" | ?{ $filename -match $_ } | %{ return $true }
	return $false
}

function find-nunit {
	$nunit = join-path (split-path (gcm j6.ps1).Definition) "nunit/bin/nunit-console-x86.exe"
	#log ("First location: {0}" -f $nunit)
	if(test-path $nunit){return $nunit}
	"c:","d:","e:"|?{test-path $_}|%{
		$root=$_
		#log ("checking in {0}" -f $root)
		"program files","program files (x86)"|
			?{test-path (join-path $root $_)}|%{
				#log ("checking in {0}" -f $_)
				$path = join-path (join-path $root $_) "nunit*"
				if(test-path $path){
					$nunit=(ls -r -i "nunit-console-x86.exe" -path $path)
					if(test-path $nunit){
						$nunit=resolve-path $nunit
						#log ("Using: {0}" -f $nunit)
						return [string]$nunit
					}
				}
			}
	}
	if(-not $nunit) {
		$Error.Clear()
		throw "Unable to find nunit-console.exe"
	}
}

function run-tests {
	$baseDir = [string](pwd)
	$g_NunitPath = find-nunit
	assert-notempty $g_NunitPath  "Unable to find an nunit.exe"

	$searchPath = "./"
	$filter = "*Test*.dll"
	$script:testDir = join-path $baseDir "Testing"
	log-tests "Base dir: $baseDir"

	cd (get-releasedirectory)
	run-unittests $searchPath $filter
	cd $baseDir

	if ($script:failures -gt 0){throw ("{0} tests failed" -f $script:failures)}
	if ($script:errors -gt 0){throw ("{0} tests incomplete" -f $script:errors)}
}

function run-feature-tests {
	$baseDir = [string](pwd)
	feature test
}
