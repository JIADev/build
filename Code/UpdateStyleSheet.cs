using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace TestCmd
{
    class Program
    {
        static void Main(string[] args)
        {
            string log = "ChangesetLog.xml";
            XDocument document = XDocument.Load(log);
            document.AddFirst(new XProcessingInstruction(
               "xml-stylesheet", "type=\"text/xsl\" href=\"http://jia-build1.jenkon.com/ccnet/xsl/changelog.xsl\""));
            document.Save(log);
        }
    }
}
