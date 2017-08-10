using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

namespace DeploymentTool
{
	public class RTEServer : AppServer
	{
		public override string ToString()
		{
			return string.Format("{0}/{1}", base.ToString(), ServiceName);
		}

		public override object Clone()
		{
			return new RTEServer
				{
					AppLocation = AppLocation,
					BackupLocation = BackupLocation,
					HostName = HostName,
					ServiceName = ServiceName
				};
		}
	}
}
