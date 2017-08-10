
function choose_resource_file(id) {
	"use strict";
	function get_directory_object() {
		var oShell = new ActiveXObject("shell.application"),
            dir = oShell.BrowseForFolder(0, "Choose Resource File",0x4000);
		return dir;
	}

	var dir = get_directory_object();
	if (dir) {
		document.getElementById(id).value = dir.Self.Path;
	}
}
