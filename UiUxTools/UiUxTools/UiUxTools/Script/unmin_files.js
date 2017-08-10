/*global  gup, ie_readFile, ie_writeFile, 
saveFormToPrefs, loadFormFromPrefs, normalizePath,
mkdir_r,
removeClass, addClass,
css_beautify, js_beautify,
ActiveXObject, fileFinder
*/

/*jslint white: true, browser: true, devel: true */

var OPERATION_MODE = gup("mode");


function buildlist(path) {
	"use strict";
	var fso = new ActiveXObject("Scripting.FileSystemObject"),
        dir = fso.GetFolder(path),
        found;

	found = fileFinder({
		Folder: dir,
		filePattern: '\\.' + OPERATION_MODE + '$',
		includeFiles: true
	});

	return found;
}


var found_list;

function processFileConvert(srcPath, destPath) {
	"use strict";
	var found = found_list,
        idx = 0,
        beautifierOptions,
        tr;

	function inner() {
		var src = srcPath + "/" + found.files[idx],
            dest = destPath + "/" + found.newnames[idx],
            code = ie_readFile(src),
            res,    // Result from beautifier
            id;


		function loop(code) {
			var fname = normalizePath(dest),
                bits = fname.split("\\"),
                path;

			bits.pop(); // Loose the last element (filename);
			path = bits.join("\\"); // And then re-assemble.
			mkdir_r(path);
			ie_writeFile(fname, code);

			if (tr) {
				removeClass(tr, 'is-highlighted');
			}

			if (idx < found.files.length) {
				inner();
			} else {
				alert("Unminification done");
			}
		}

		id = "tr_row_" + idx;
		tr = document.getElementById(id);
		addClass(tr, 'is-highlighted');
		tr.scrollIntoView();

		idx += 1;
		beautifierOptions = {
			'indent_size': 1,
			'indent_char': '\t'
		};

		if (OPERATION_MODE === "css") {
			res = css_beautify(code, beautifierOptions);
		} else {
			res = js_beautify(code, beautifierOptions);
		}

		window.setTimeout(function () {
			loop(res);
		});
	}
	inner();
}

function generateNewNames(found) {
	"use strict";
	var min = 'min',
        version = 'exploded',
        delims = ['.', '-', '_'];

	found.newnames = [];

	// Check for every variation of
	// -min- -min. _min_ 
	found.files.forEach(function (name, idx) {
		var newname = name;
		delims.forEach(function (startChar) {
			delims.forEach(function (endChar) {
				var oldstr = startChar + min + endChar,
                    newstr = startChar + version + endChar;
				newname = newname.replace(oldstr, newstr);
				found.newnames[idx] = newname;
			});
		});
	});
}

function buildtable(found) {
	"use strict";
	var filelist = found.files,
        o = [],
        i,
        l = filelist.length,
        id,
        file;

	o.push("<table border='1'>");
	for (i = 0; i < l; i += 1) {
		file = filelist[i];
		id = "tr_row_" + i;
		o.push("<tr id='" + id + "'>");
		o.push("<td>" + found.files[i] + "</td>");
		o.push("<td>" + found.newnames[i] + "</td>");
		o.push("</tr>");
	}
	o.push("</table>");
	document.getElementById("filelist").innerHTML = o.join("");
}


function removeUnchangedNames(found) {
	var l = found.files.length;

	// We are removing things from the array,
	// so run backwards
	while (l--) {

		if (found.files[l] === found.newnames[l]) {
			found.files.splice(l, 1);
			found.newnames.splice(l, 1);
		}
	}
}

function processNameList() {
	"use strict";
	var but = document.getElementById("processNameButton");

	function inner() {
		var source = document.getElementById("source").value,
            found = buildlist(source);

		generateNewNames(found);
		removeUnchangedNames(found);
		buildtable(found);
		but.disabled = false;
		found_list = found;
		document.getElementById("processFileConvertButton").disabled = false;
	}
	saveFormToPrefs(but.form);
	but.disabled = true;
	window.setTimeout(inner);
}

function set_dir_choice(id) {
	"use strict";
	function get_directory_object() {
		var oShell = new ActiveXObject("shell.application"),
            dir = oShell.BrowseForFolder(0, "Choose files to be unminified/beautified", 0, "");
		return dir;
	}

	var dir = get_directory_object();
	if (dir) {
		document.getElementById(id).value = dir.Self.Path;
	}
}


function choose_source() {
	"use strict";
	set_dir_choice("source");
}

function choose_dest() {
	"use strict";
	set_dir_choice("dest");
}

function init() {
	"use strict";
	var form = document.getElementById("source").form;
	function setVisible(classes, val) {
		var els = document.getElementsByClassName(classes),
            i;

		for (i = 0; i < els.length; i += 1) {
			els[i].style.display = val ? "none" : "";
		}
	}

	// Give the two  modes a different form name so the prefs
	// will be saved separately.
	form.name = OPERATION_MODE + "_" + form.name;
	form.id = OPERATION_MODE + "_" + form.id;
	loadFormFromPrefs(document.getElementById("source").form);

	setVisible("is-js-reference", true);
	setVisible("is-css-reference", true);
	setVisible("is-" + OPERATION_MODE + "-reference", false);

	var but = document.getElementById("processFileConvertButton");
	but.onclick = function () {
		var srcPath = document.getElementById("source").value,
            destPath = document.getElementById("dest").value;
		processFileConvert(srcPath, destPath);
	};
}
