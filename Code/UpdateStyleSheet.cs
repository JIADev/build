using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;
using System.IO;

namespace TestCmd
{
    class Program
    {
        static void Main(string[] args)
        {
            string log = "ChangesetLog.xml";
	    var logInfo = new FileInfo("ChangesetLog.xml");
	    if(!logInfo.Exists || logInfo.Length == 0)
	    {
	       return;
	    }
	    
            try
	    {	    
	    	    XDocument document = XDocument.Load(log);
            	    document.AddFirst(new XProcessingInstruction(
               	    "xml-stylesheet", "type=\"text/xsl\" href=\"changelog.xsl\""));
            	    document.Save(log);
	  }
	  catch(Exception ex)
	  {
		Console.WriteLine(ex.ToString());
	}
        }
    }
}
