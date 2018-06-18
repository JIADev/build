$pat = 'class[ ]*=[ ]*"(?<class>[a-zA-Z\-_]+)"'

dir -r Sites -include *.ascx,*.aspx | ? { (gc $_.fullname) -match $pat} `
	| % { 
		'==' + $_.fullname + '=='
		'===Classes==='
		$values = [regex]::Matches( (gc $_.fullname), $pat) | % { $_.groups["class"].value} `
			| sort -unique
		$values
		}