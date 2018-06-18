/*globals Enumerator, ActiveXObject */

/*jslint continue: true, white: true, browser: true, devel: true */

/*
function doSomething(e) {
    var targ;
    if (!e) var e = window.event;
    if (e.target) targ = e.target;
    else if (e.srcElement) targ = e.srcElement;
    if (targ.nodeType == 3) // defeat Safari bug
        targ = targ.parentNode;
}
*/


var fileFinder = function (cfg) {
	"use strict";
	var debugMessages = false,
        found = {};

	function FileFinderException(value) {
		var that = this;
		this.value = value;
		this.message = "fileFinder config error";
		this.toString = function () {
			return [that.value, that.message].join(" ");
		};
	}


	if (cfg.Folder === undefined) {
		throw new FileFinderException("Path Undefined");
	}

	if (cfg.filePattern === undefined) {
		cfg.filePattern = ".*";
	}

	if (cfg.dirPattern === undefined) {
		cfg.dirPattern = ".*";
	}

	if (cfg.directorySeparator === undefined) {
		cfg.directorySeparator = "\\";
	}

	cfg.includeFiles = !!cfg.includeFiles;
	cfg.includeFolders = !!cfg.includeFolders;


	found.messages = [];
	found.files = cfg.includeFiles ? [] : null;
	found.folders = cfg.includeFolders ? [] : null;

	function walkDirectoryTree(folder, folder_name) {
		var subfolders = folder.SubFolders,
            en,
            subfolder;

		function walkDirectoryFilter(items, re_pattern, list) {
			var e = new Enumerator(items),
                item;
			while (!e.atEnd()) {
				item = e.item();
				if (item.name.match(re_pattern)) {
					if (debugMessages) {
						found.messages.push(item.name);
					}
					if (list) {
						list.push(folder_name + cfg.directorySeparator + item.name);
					}
				}
				e.moveNext();
			}
		}


		if (debugMessages) {
			found.messages.push("Files in " + folder_name + " matching '" + cfg.filePattern + "':");
		}
		walkDirectoryFilter(folder.files, cfg.filePattern, found.files);

		if (debugMessages) {
			found.messages.push("Folders in " + folder_name + " matching '" + cfg.dirPattern + "':");
		}
		walkDirectoryFilter(subfolders, cfg.dirPattern, found.folders);

		en = new Enumerator(subfolders);
		while (!en.atEnd()) {
			subfolder = en.item();
			walkDirectoryTree(subfolder, folder_name + cfg.directorySeparator + subfolder.name);
			en.moveNext();
		}
	}


	//walkDirectoryTree(cfg.Folder, cfg.Folder.Name);
	walkDirectoryTree(cfg.Folder, ".");
	return found;
};


function normalizePath(path) {
	"use strict";
	var s = path.replace(/\//g, "\\");
	return s;
}

function mkdir_r(dirOrig) {
	"use strict";
	var fso = new ActiveXObject("Scripting.FileSystemObject"),
        dir = normalizePath(dirOrig),
        bits = dir.split("\\"),
        bit,
        i, l,
        s;

	l = bits.length;
	s = bits[0];
	for (i = 1; i < l; i += 1) {
		bit = bits[i];
		if (bit === ".") {
			continue;
		}
		s += "/" + bit;
		if (!fso.FolderExists(s)) {
			fso.CreateFolder(s);
		}
	}
}

var ie_writeFile = function (fname, data, useUnicode) {
	"use strict";
	useUnicode = !!useUnicode;

	alert(fname);

	var fso, fileHandle;
	fso = new ActiveXObject("Scripting.FileSystemObject");
	fileHandle = fso.CreateTextFile(fname, true, useUnicode);
	fileHandle.write(data);
	fileHandle.close();
};

var ie_readFile = function (fname, useUnicode) {
	"use strict";
	var triState = 0; // Default to Ascii
	if (useUnicode) {
		triState = -1; // Use Unicode
	}


	try {
		var fso = new ActiveXObject("Scripting.FileSystemObject"),
            filehandle = fso.OpenTextFile(fname, 1, false, triState),  // ReadOnly, no create, open as unicode
            contents = filehandle.ReadAll();
		filehandle.Close();
		return contents;
	} catch (err) {
		return null;
	}
};



var prefManager = (function () {
	"use strict";
	var LOCALAPPDATA = 0x1c,
        localAppDataPath = new ActiveXObject("Shell.Application").NameSpace(LOCALAPPDATA).Self.Path,
        path = localAppDataPath + "/UiUx",
        fullname = path + "/prefs.json";
	mkdir_r(path);

	function parse(data) {
		try {
			data = JSON.parse(data);
		} catch (e) {
			data = {};
		}
		if (!data) {
			data = {};
		}
		return data;
	}

	function getValue(key, def) {
		var d = ie_readFile(fullname),
            val,
            data = parse(d);

		val = data[key];
		if (val === undefined) {
			val = def;
		}
		return val;
	}

	function setValue(key, val) {
		var d = ie_readFile(fullname),
            data = parse(d),
            json;

		data[key] = val;
		json = JSON.stringify(data, undefined, 2);
		ie_writeFile(fullname, json);
	}

	return {
		setValue: setValue,
		getValue: getValue
	};

}());



var serializeForm;
var deserializeForm;

(function () {
	"use strict";
	var getOptionValue,
        urlencode,
        reCheck = new RegExp('^(checkbox|radio)$'),
        reText = new RegExp('^(text|password|hidden|textarea)$');

	getOptionValue = function (o) {
		return (o.value || o.text);
	};

	urlencode = (function () {
		var f = function (s) {
			return encodeURIComponent(s).replace(/%20/g, '+').replace(/(.{0,3})(%0A)/g,
                function (m, a, b) { return a + (a === '%0D' ? '' : '%0D') + b; }).replace(/(%0D)(.{0,3})/g,
                    function (m, a, b) { return a + (b === '%0A' ? '' : '%0A') + b; });
		};

		if (encodeURIComponent !== undefined && String.prototype.replace && f('\n \r') === '%0D%0A+%0D%0A') {
			return f;
		}
		return null;
	}());


	function isNoAutoComplete(e) {
		var a = e.getAttribute("autocomplete");
		if (typeof a === "string") {
			a = a.toLowerCase();
			return (a === "off");
		}
		return false;
	}


	function setSelectValue(s, v) {
		var i,
            optionVal;
		for (i = 0; i < s.options.length ; i += 1) {
			optionVal = getOptionValue(s.options[i]);
			if (optionVal === v) {
				s.selectedIndex = i;
				return;
			}
		}
	}



	if (urlencode && getOptionValue) {
		deserializeForm = function (f, formData) {
			var e, // form element
                n, // form element's name
                t, // form element's type
                es = f.elements,
                i,
                ilen;


			for (i = 0, ilen = es.length; i < ilen; i += 1) {
				e = es[i];
				n = e.name;

				if (isNoAutoComplete(e)) {
					continue;
				}

				if (!formData[n]) {
					// Skip any fields with no saved value
					continue;
				}

				if (n && !e.disabled) {
					t = e.type;
					if (t.indexOf('select') === 0) {
						if (t === 'select-one' || e.multiple === false) {
							setSelectValue(e, formData[n]);
						} else {
							throw ("No support for multiple selects right now");
						}
					} else if (reCheck.test(t)) {
						e.checked = true;
					} else if (reText.test(t)) {
						e.value = formData[n];
					}
				}
			}
		};



		serializeForm = function (f) {
			var e, // form element
                n, // form element's name
                t, // form element's type
                o, // option element
                es = f.elements,
                formData = {}, // The form data
                c = [], // the serialization data parts
                i,
                ilen,
                j,
                jlen;

			function add(n, v) {
				c[c.length] = urlencode(n) + "=" + urlencode(v);
				formData[n] = v;
			}

			for (i = 0, ilen = es.length; i < ilen; i += 1) {
				e = es[i];
				n = e.name;

				if (n && !e.disabled) {
					t = e.type;
					if (t.indexOf('select') === 0) {
						// The 'select-one' case could reuse 'select-multiple' case
						// The 'select-one' case code is an optimization for
						// serialization processing time.
						if (t === 'select-one' || e.multiple === false) {
							if (e.selectedIndex >= 0) {
								add(n, getOptionValue(e.options[e.selectedIndex]));
							}
						} else {
							for (j = 0, jlen = e.options.length; j < jlen; j++) {
								o = e.options[j];
								if (o.selected) {
									add(n, getOptionValue(o));
								}
							}
						}
					} else if (reCheck.test(t)) {
						if (e.checked) {
							add(n, e.value || 'on');
						}
					} else if (reText.test(t)) {
						if (isNoAutoComplete(e)) {
							add(n, "");
						} else {
							add(n, e.value);
						}

					}
				}
			}
			return formData;
		};
	}
}());

function saveFormToPrefs(form) {
	"use strict";
	var o = serializeForm(form),
        key,
        id = form.id || form.name,
        value;

	for (key in o) {
		if (o.hasOwnProperty(key)) {
			value = o[key];
			prefManager.setValue(id + "." + key, value);
		}
	}
}

function loadFormFromPrefs(form) {
	"use strict";
	var es = form.elements,
        i,
        el,
        id = form.id || form.name,
        name,
        v,
        formData = {};

	for (i = 0; i < es.length; i += 1) {
		el = es[i];
		name = el.name;
		v = prefManager.getValue(id + "." + name);
		formData[name] = v;
	}

	//alert(JSON.stringify(formData));
	deserializeForm(form, formData);
}

function hasClass(ele, cls) {
	"use strict";
	return ele.className.match(new RegExp('(\\s|^)' + cls + '(\\s|$)'));
}

function addClass(ele, cls) {
	"use strict";
	if (!hasClass(ele, cls)) {
		ele.className += " " + cls;
	}
}

function removeClass(ele, cls) {
	"use strict";
	if (hasClass(ele, cls)) {
		var reg = new RegExp('(\\s|^)' + cls + '(\\s|$)');
		ele.className = ele.className.replace(reg, ' ');
	}
}

function gup(name) {
	"use strict";
	name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
	var regexS = "[\\?&]" + name + "=([^&#]*)",
        regex = new RegExp(regexS),
        results = regex.exec(window.location.href);

	if (!results) {
		return null;
	} else {
		return results[1];
	}
}

function formatStr() {
	var args = arguments;
	var st = args[0];

	return st.replace(/\{\{|\}\}|\{(\d+)\}/g, function (m, n) {
		if (m == "{{") {
			return "{";
		}
		if (m == "}}") {
			return "}";
		}
		return args[+n + 1];
	});
};
