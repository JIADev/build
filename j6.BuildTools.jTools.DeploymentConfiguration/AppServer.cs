using System.Xml.Serialization;

namespace DeploymentTool
{
	public class AppServer : Server
	{
		[XmlAttribute]
		public string ServiceName { get; set; }

		[XmlAttribute]
		public string AppLocation { get; set; }

		[XmlAttribute]
		public string BackupLocation { get; set; }

		public override object Clone()
		{
			return new AppServer
			{
				AppLocation = AppLocation,
				BackupLocation = BackupLocation,
				HostName = HostName,
				ServiceName = ServiceName
			};
		}
	}
}
