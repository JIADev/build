using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Serialization;

namespace j6SentinelEngine
{
	[Serializable]
	public class SentinelConfiguration : SerializableObject<SentinelConfiguration>
	{
		public SentinelConfiguration()
		{
			PollingInterval = 10;
			RetryCount = 3;
		}

		/// <summary>
		/// Polling interval in seconds
		/// </summary>
		[XmlAttribute]
		public int PollingInterval { get; set; }

		[XmlAttribute]
		public int RetryCount { get; set; }

		[XmlElement("Server")]
		public Server[] Servers { get; set; }
	}

	
	public class Server
	{
		[XmlAttribute]
		public string Name { get; set; }
		[XmlAttribute]
		public string PingUrl { get; set; }
		[XmlAttribute]
		public string ServiceName { get; set; }
		[XmlAttribute]
		public string AppPoolName { get; set; }
	}
}
