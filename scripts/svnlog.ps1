
function log-branch {
	param($url)
	$log=[xml](svn.exe log $url --xml --stop-on-copy -v)
	return $log
}

function generate-branchreport {
	param($url,$rev=1)
	$log=(log-branch $url)
	$logentry=[System.Object[]]($log.log.logentry|?{[int]($_.revision) -gt $rev})
	if(-not($logentry)){
		write-host "no changes"
		return
	}

	write-host ("{0} changes" -f $logentry.count)

	$nl = [System.Environment]::NewLine
	$authors=$logentry|%{$_.author}|sort -u
	$revisions=$logentry|%{$_.revision}|sort
	$messages=$logentry|sort -Property revision|%{"[{0}]{2}{1}{2}" -f $_.revision,$_.msg,$nl }
	$paths=$logentry|%{$_.paths|%{$_.path}}

	$affected=$paths|%{$_.get_innertext()}|sort -u

	$total=0;
	$modified=0;
	$added=0;
	$removed=0;
	$affected|%{$total++}

	$paths|?{$_.action -eq 'M'}|%{$modified++}
	$paths|?{$_.action -eq 'A'}|%{$added++}
	$paths|?{$_.action -eq 'D'}|%{$removed++}

	$revcount=$logentry.count

	$span=$logentry[$revcount-1].date.substring(0,10)
	$span += " to "
	$span += $logentry[0].date.substring(0,10)

	$msg=("MERGE FROM $url{0}{0}" -f $nl)
	$revisions|%{$_|%{$msg += ("[{0}]," -f [string]($_))}}
	$msg += ("{0}{0}Date range: {1}" -f $nl,$span)
	$msg += ("{0}{0}Authors:{0}--------{0}" -f $nl)
	$authors|%{$_|%{$msg += ("{0}{1}" -f [string]($_),$nl) }}
	$msg += ("{0}Messages:{0}---------{0}" -f $nl)
	$messages|%{$_|%{$msg += ("{0}{1}" -f [string]($_),$nl) }}

	return $msg
}

