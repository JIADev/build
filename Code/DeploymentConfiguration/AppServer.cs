using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

namespace DeploymentTool
{
	public abstract class AppServer : Server
	{
		[XmlAttribute]
		public string AppLocation { get; set; }

		[XmlAttribute]
		public string BackupLocation { get; set; }
	}
}
