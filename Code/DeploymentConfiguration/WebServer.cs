using System.Xml.Serialization;

namespace DeploymentTool
{
	public class WebServer : AppServer
	{
		[XmlAttribute]
		public string SiteName { get; set; }

		[XmlAttribute]
		public string ServerUrl { get; set; }

		[XmlAttribute]
// ReSharper disable ValueParameterNotUsed
		public new string ServiceName { get { return "w3svc"; } set { } }
// ReSharper restore ValueParameterNotUsed

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
