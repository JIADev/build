set-psdebug -strict

$scripts = dir sites -r -include *.js | % {$_.name} | sort -unique
$potential_users =  dir sites -r -include *.cs,*.aspx,*.ascx,*.master,*.js
for($i = 0; $i -lt $scripts.length; $i++) {
    $c = $scripts[$i]
    write-progress -activity "Checking scripts. Note there may be false positives!" -status $c -perc ((($i + 1)/$scripts.length) * 100)
    $found = $potential_users | ? {$_.Name -ne $c} | ? {(gc $_.fullname) -imatch $c }
    if (!$found) { $c }
}
write-progress -activity "Checking scripts. Note there may be false positives!" -status $c -perc ([int]($i + 1)/$scripts.length) -completed
