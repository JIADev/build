using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

namespace DeploymentTool
{
	public class WebServer : AppServer
	{
		[XmlAttribute]
		public string SiteName { get; set; }

		[XmlAttribute]
		public string ServerUrl { get; set; }

		public override object Clone()
		{
			return new WebServer
				{
					AppLocation = AppLocation,
					BackupLocation = BackupLocation,
					HostName = HostName,
					ServerUrl = ServerUrl,
					SiteName = SiteName
				};
		}
	}
}
