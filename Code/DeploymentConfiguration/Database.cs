using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing.Design;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

namespace DeploymentTool
{
	[Editor(typeof(UIEditor<Database>), typeof(UITypeEditor))]
	public class Database : ICloneable
	{
		[XmlAttribute]
		public string Name { get; set; }

		public DbServer Server { get; set; }

		public object Clone()
		{
			return new Database
				{
					Name = Name,
					Server = (DbServer)Server.Clone()
				};
		}

		public override string ToString()
		{
			return string.Format("{0} on {1}", Name, Server);
		}
	}
}
