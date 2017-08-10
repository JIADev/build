function convert-resx-xml($xml, $context) {
	$xml.root.data | % {
		$name = $_.name
		$value = $_.value
		"<resource ResourceSet = `"default`" Context = `"$context`" Name=`"$name`" Property=`"Text`" Culture = `"en-US`" Value = `"$value`" />"
	}
}

function convert-resx-cs($xml, $context) {
	$xml.root.data | % {
		$name = $_.name
		"public const string $name = `"$name`";"
	}
}