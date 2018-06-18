function build-ndepend-helper {
		$filename = (dir j6-ndepend.xml).fullname
		ndepend.console.exe $filename
}
build-ndepend-helper
