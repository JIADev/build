if ([int]((hg stat -u | measure-object -line).lines) -eq 0) {
	if (([int]((svn.exe stat | ? {$_.startswith("?") } | measure-object -line).lines)) -eq 0) {
		rm -fo messages.tmp
		hg log -p -r svn:tip > messages.tmp
		if (test-path messages.tmp) {
			svn.exe commit --file messages.tmp
			hg tag --force svn
		} else {
			"hg log reports no changes, nothing to commit."
		}
	} else {
		"svn stat shows unknown files. remove them, add them, 'svn propedit svn:ignore', or add to global ignore list first."
	}
} else {
	"hg stat shows unknown files. remove them, add them, or edit .hgignore first."
}