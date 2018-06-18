set-psdebug -strict

$controls = dir sites -r -include *.ascx | % {$_.name} | sort -unique
$potential_users =  dir sites -r -include *.cs,*.aspx,*.ascx,*.master,*.config
for($i = 0; $i -lt $controls.length; $i++) {
    $c = $controls[$i]
    write-progress -activity "Checking controls. Note there may be false positives!" -status $c -perc ((($i + 1)/$controls.length) * 100)
    $found = $potential_users | ? {$_.Name -ne $c} | ? {(gc $_.fullname) -imatch $c }
    if (!$found) { $c }
}
write-progress -activity "Checking controls. Note there may be false positives!" -status $c -perc ([int]($i + 1)/$controls.length) -completed
