using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing.Design;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

namespace DeploymentTool
{
	[Editor(typeof(UIEditor<WebServerCollection>), typeof(UITypeEditor))]
	[DefaultProperty("SiteUrl")]
	public class WebServerCollection : ICloneable
	{
		[XmlAttribute]
		public string SiteUrl { get; set; }

		[XmlElement("Server")]
		public WebServer[] WebServers { get; set; }

		public override string ToString()
		{
			return SiteUrl;
		}

		public object Clone()
		{
			return new WebServerCollection
				{
					SiteUrl = SiteUrl,
					WebServers = WebServers == null ? null : WebServers.Select(ws => ws.Clone()).Cast<WebServer>().ToArray()
				};
		}
	}
}
