using System;
using System.Xml.Serialization;
namespace DeploymentTool
{
	public abstract class Server : ICloneable
	{
		[XmlAttribute]
		public string HostName { get; set; }

		public override string ToString()
		{
			return HostName;
		}

		public abstract object Clone();
	}
}