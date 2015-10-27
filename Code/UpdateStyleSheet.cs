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
	        string inputFileName = args.Length > 0 ? args[0] : "ChangesetLog.xml";
	        string stylesheet = args.Length > 1 ? args[1] : "changelog.xsl";
	        string outputFileName = args.Length > 2 ? args[2] : inputFileName;

	    var logInfo = new FileInfo(inputFileName);

	    if(!logInfo.Exists || logInfo.Length == 0)
	    {
	       return;
	    }
	    
            try
            {
	            XDocument document;
				using (StreamReader reader = new StreamReader(logInfo.FullName, Encoding.UTF8))
					document = XDocument.Load(reader);
	            document.Declaration.Encoding = "utf-8";
            	document.AddFirst(new XProcessingInstruction(
               	    "xml-stylesheet", string.Format("type=\"text/xsl\" href=\"{0}\"", stylesheet)));
            	    document.Save(outputFileName);
	  }
	  catch(Exception ex)
	  {
		Console.WriteLine(ex.ToString());
	}
        }
    }
}
