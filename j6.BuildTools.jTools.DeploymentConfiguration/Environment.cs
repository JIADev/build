using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;

namespace DeploymentTool
{
    public class Environment
    {
		[XmlAttribute]
		[Category("General")]
		public string Name { get; set; }

		[XmlAttribute]
		[Category("General")]
		public string Description { get; set; }

		[XmlAttribute]
		[Category("General")]
		public string Client { get; set; }

		[Category("Database")]
		public Database Database { get; set; }

		[XmlArray("Redis")]
		[XmlArrayItem("Server")]
		[Category("Servers")]
		public RedisServer[] RedisServers { get; set; }

		[XmlElement("Web")]
		[Category("Servers")]
		public WebServerCollection WebServers { get; set; }

		[XmlArray("RTE")]
		[XmlArrayItem("Server")]
		[Category("Servers")]
		public RTEServer[] RTEServers { get; set; }

		public override string ToString()
		{
			return string.Format("{0} ({1})", Name, Description);
		}
    }
}
