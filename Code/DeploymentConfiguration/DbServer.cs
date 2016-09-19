using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing.Design;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

namespace DeploymentTool
{
	[Editor(typeof(UIEditor<DbServer>), typeof(UITypeEditor))]
	public class DbServer : Server
	{
		[XmlAttribute]
		public string BackupLocation { get; set; }
		
		[XmlAttribute]
		public string RestoreLocation { get; set; }

		[XmlAttribute]
		public string SqlInstance { get; set; }

		public override object Clone()
		{
			return new DbServer
				{
					BackupLocation = BackupLocation,
					RestoreLocation = RestoreLocation,
					HostName = HostName,
					SqlInstance = SqlInstance
				};
		}
	}
}
