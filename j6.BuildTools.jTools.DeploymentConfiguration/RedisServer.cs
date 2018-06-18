using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

namespace DeploymentTool
{
	public class RedisServer : Server
	{
		private byte _dbNumber;

		[XmlAttribute]
		public byte DbNumber
		{
			get { return _dbNumber; }
			set
			{
				if (value > 15)
					throw new ArgumentOutOfRangeException("value", "DbNumber must be a value between 0 and 15");
				_dbNumber = value;
			}
		}

		public override object Clone()
		{
			return new RedisServer
				{
					DbNumber = DbNumber,
					HostName = HostName
				};
		}
	}
}
