##
# copied from Jenkon.Payment.PfproPaymentFlow.MaskCardNumber
# depends on get-delegate
##

function clean-creditcardnumber {
	param([string]$number=$(throw "pass in cc number"))
	return [regex]::replace($number,"[^\d]","");
}

function mask-cardnumber {
	param(
		$number=$(throw "pass in cc number"),
		$maskchar='*',
		$leading=0,
		$trailing=4
	)
	$number = clean-creditcardnumber $number
	$l = "(\d{{{0}}})" -f $leading
	$t = "(\d{{{0}}})" -f $trailing
	$r = "(.*?){0}(\d{{5,}}){1}(.*?)" -f $l,$t
	$d = (get-delegate system.text.regularexpressions.matchevaluator {
		$m=$args[0]
		if($m.Groups.Count -eq 6){
			$repl=""
			1..$m.Groups[3].Length|%{$repl+=$maskchar}
			return ("{0}{1}{2}{3}{4}" -f $m.Groups[1],$m.Groups[2],$repl,$m.Groups[4],$m.Groups[5])
		}
		return $m.Value
	})
	return [regex]::replace($number,$r,$d);
}

