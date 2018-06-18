var adOpenStatic = 3;
var adLockOptimistic = 3;


var strDatabase;
var SaveSql;
var saveSqlPage;
var strData;
var sqlStr;

var lastSelectedTable = "";
var isFirstTableLoad = false;

function activatePart(p) {
    var i;
    var el;

    for (i = 0; i < 10; i += 1) {
        el = document.getElementById("part" + i);
        if (el) {
            el.className = "hidden";
        }
    }

    el = document.getElementById("part" + p);
    if (el) {
        el.className = "";
    }

    document.body.className = (p == 0) ? "wait" : "";

    return el;
}

function saveForm() {
    saveFormToPrefs(document.getElementById("database_test"));
}



function createTestOptions() {

    var el = activatePart(1);

    var tests = [
        {
            sql: [
                'Select distinct top 20 email From genealogy.Account'
            ],
            buttonText: 'Check if data has been scrubbed',
            longText: 'If there are more that just a few entries here, or if the data looks like ' +
                'real addresses.  STOP.  Delete the data.'
        },
        {
            sql: [
                "update Security.[User] set Password = 'cc03e747a6afbbcbf8be7668acfebee5', PasswordEncoding = 'MD5'"
            ],
            buttonText: 'Set all passwords to test123',
            longText: 'Change all passwords'
        },
        {
            sql: [
                "DECLARE @brokerSql VARCHAR(200)",
                "   SET @brokerSql = 'ALTER DATABASE [' + DB_NAME() + '] SET NEW_BROKER WITH ROLLBACK IMMEDIATE'",
                "   EXEC (@brokerSql)"
            ],
            buttonText: 'Set SQL Broker Service.',
            longText: 'This is the first step after cloneing a database.  You may need to run this command twice.'
        },
        {
            sql: [
                "OPEN MASTER KEY DECRYPTION BY PASSWORD = 'myPassw0rd!'; ",
                //"GO ",
                "DROP SYMMETRIC KEY J6_SYMMETRIC_KEY; ",
                //"GO ",
                "DROP CERTIFICATE J6Certificate; ",
                //"GO ",
                "ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;  ",
                //"GO ",
                "CREATE CERTIFICATE J6Certificate ",
                "      WITH SUBJECT = 'Certificate for encryption to use for J6'; ",
                //"GO ",
                "CREATE SYMMETRIC KEY J6_SYMMETRIC_KEY ",
                "      WITH ALGORITHM = AES_256 ",
                "      ENCRYPTION BY CERTIFICATE J6Certificate; ",
                //"GO ",
                ""
            ],
            buttonText: 'Create a master key',
            longText: 'This is the second step after cloning a database'
        }
    ];


    el.innerHTML += "<p>Things to run</p>";

    tests.forEach(function (test) {
        var row = document.createElement("div");
        row.style.display = "table-row";
        var cell;        
        
        cell = document.createElement("span");
        cell.appendChild(document.createTextNode(test.buttonText));
        row.appendChild(cell);


        var but = document.createElement("button");
        but.appendChild(document.createTextNode("Run"));
        but.style.display = "table-cell";

        but.onclick = function() {
            var objConnection = new ActiveXObject("ADODB.Connection");
            var objRecordSet = new ActiveXObject("ADODB.Recordset");

            var connstring = "";
            var server = document.getElementById('select-server').value;
            var database = document.getElementById('input-db').value;
            var user = document.getElementById('input-username').value;
            var password = document.getElementById('input-password').value;
            var sql;

            saveForm();
            activatePart(0);

            connstring = formatStr("Provider=SQLOLEDB;Data Source={0};Trusted_Connection=Yes;Initial Catalog={1};",
                server, database);

            if (user !== "" && password !== "") {
                connstring += formatStr("User ID={0};Password={1}",
                    user, password);
            }

            objConnection.Open(connstring);
            sql = test.sql.join("\r\n");

            objRecordSet.Open(sql, objConnection, adOpenStatic, adLockOptimistic);

            window.setTimeout(function() {
                showSqlResult(objRecordSet);
            });

        };

        row.appendChild(but);
        
        but = document.createElement("button");
        but.appendChild(document.createTextNode("Show SQL"));
        but.style.display = "table-cell";
        but.onclick = function() {
            var sql = test.sql.join("\r\n");
            alert(sql);
        };
        row.appendChild(but);


        el.appendChild(row);
        //el.appendChild(document.createElement("br"));
    });
}


function showError(err) {
    //alert("Show error:" + err);
    var el = document.getElementById("errBox");
    var m = JSON.stringify(err, undefined, 3);
    m = m.replace(/\r\n|\r|\n/g, "<br>");
    m = m.replace(/ /g, "&nbsp;");
    el.innerHTML = m;
    el.scrollIntoView();
}


function showSqlResult(rs) {
    var i;
    var o = [];
    var header = [];
    var footer = [];

    rs.MoveFirst();
    
    //First send out the column headers;
    header.push("<h1>" + strDatabase + " : " + lastSelectedTable + "</h1>");

    header.push("<table border=1>");
    /*

    header.push("<tr>");
    
    header.push("<th bgcolor=#CCCCCC>SqlRec</th>");

    for (i = 0; i < headers.length; i++) {
        str = headers[i].Name;
        if (isFirstTableLoad) {
            addNameToList(str);
        }
        header.push(formatStr("<th bgcolor=#CCCCCC><b>{0}</b><br><1></th>", str, headers[i].Type));
    }
    isFirstTableLoad = false;
    header.push("</tr>");
    */

    //Now send out the table body;

    while (!rs.EOF) {
        o.push("<tr>");        

        for (i = 0; i < rs.Fields.Count; i += 1) {
            o.push("<td>" + rs.Fields(i).Value + "</td>");
        }
        o.push("</tr>");
        rs.MoveNext();
    }

    footer.push("</table>");

    var strData = (header.join("\r") + o.join("\r") + footer.join("\r"));
    document.getElementById("txtData").innerHTML = strData;    
}


function grokSql(page) {
    activatePart(0);
    var strData;

    function inner() {
        activatePart(3);
        strData = showSqlResult(SaveSql, page);
        txtData.innerHTML = strData;
    }
    window.setTimeout(inner);
}



var addNameToList = (function () {
    var counter = -1;

    function inner(s) {
        var hostEl = document.getElementById('nameList');
        var pasteEl = document.getElementById('textSqlQuery');

        if (s === null) {
            counter = -1;
            hostEl.innerHTML = "";
            return;
        }

        counter += 1;
        if (counter === 0) {
            inner(" FROM ");
        } else {
            s = " " + s + " ";
        }

        var el = document.createElement("span");
        el.className = "canclick";
        el.appendChild(document.createTextNode(s));
        hostEl.appendChild(el);
        hostEl.appendChild(el.appendChild(document.createTextNode(" ")));

        el.onclick = function() {
            insertAtCursorPosition(pasteEl, s);
        };
    }

    return inner;
}());


function DisplayTable(strTable) {
    lastSelectedTable = strTable;
    addNameToList(null);
    addNameToList(lastSelectedTable);

    isFirstTableLoad = true;

    SaveSql = "SELECT * FROM " + strTable;
    sql.textSqlQuery.Value = "* FROM " + strTable;
    grokSql(0);
}

function ExecuteSqlStatement() {
    var strData;
    var v = document.getElementById("textSqlStatement").value;
    strData = showSqlResult(v, 0);
    txtData.innerHTML = strData;
}


function insertAtCursorPosition(myField, myValue) {
    if (document.selection) {
        myField.focus();
        sel = document.selection.createRange();
        sel.text = myValue;
    } else if (myField.selectionStart == 0 || myField.selectionStart == '0') {
        var startPos = myField.selectionStart;
        var endPos = myField.selectionEnd;
        myField.value = myField.value.substring(0, startPos) + myValue + myField.value.substring(endPos, myField.value.length);
    } else {
        myField.value += myValue;
    }
}