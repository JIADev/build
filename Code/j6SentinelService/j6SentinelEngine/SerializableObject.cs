using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

namespace j6SentinelEngine
{
	public class SerializableObject<T> where T : class, new()
	{
		protected static XmlSerializer _serializer = new XmlSerializer(typeof(T));

		public void Save(string fileName)
		{
			using (var fileStream = new FileStream(fileName, FileMode.Create, FileAccess.Write, FileShare.None))
			{
				Save(fileStream);
			}
		}

		public void Save(FileStream fileStream)
		{
			using (var streamWriter = new StreamWriter(fileStream))
			{
				Save(streamWriter);
			}
		}

		public void Save(StreamWriter streamWriter)
		{
			_serializer.Serialize(streamWriter, this);
		}

		public static T Load(string fileName)
		{
			using (var fileStream = new FileStream(fileName, FileMode.Open, FileAccess.Read, FileShare.Read))
			{
				return Load(fileStream);
			}
		}

		public static T Load(FileStream fileStream)
		{
			using (var streamReader = new StreamReader(fileStream))
			{
				return Load(streamReader);
			}
		}

		public static T Load(StreamReader streamReader)
		{
			return (T)_serializer.Deserialize(streamReader);
		}
	}
}
