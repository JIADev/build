using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Xml;
using System.Xml.Serialization;

namespace DeploymentTool
{
	public class Serializable<T> where T : class, new()
	{
		// ReSharper disable StaticFieldInGenericType
		private static readonly Dictionary<Type, XmlSerializer> Serializers = new Dictionary<Type, XmlSerializer>();

		private static XmlSerializer XmlSerializer
		{
			get
			{
				if (!Serializers.ContainsKey(typeof (T)))
					lock (Serializers)
						if (!Serializers.ContainsKey(typeof (T)))
						{
							Serializers.Add(typeof (T), new XmlSerializer(typeof (T)));
						}
				return Serializers[typeof (T)];
			}
		}
		// ReSharper restore StaticFieldInGenericType

		public void Save(string fileName)
		{
			using (var stream = new FileStream(fileName, FileMode.Create, FileAccess.Write, FileShare.None))
				Save(stream);
		}

		public void Save(Stream stream)
		{
			using (var writer = new StreamWriter(stream, Encoding.UTF8))
				Save(writer);
		}

		public void Save(TextWriter writer)
		{
			XmlSerializer.Serialize(writer, this);
		}

		public void Save(XmlWriter writer)
		{
			XmlSerializer.Serialize(writer, this);
		}

		public static T LoadOrCreate(string fileName)
		{
			return File.Exists(fileName) ? Load(fileName) : new T();
		}

		public static T Load(string fileName)
		{
			using (var stream = new FileStream(fileName, FileMode.Open, FileAccess.Read, FileShare.Read))
				return Load(stream);
		}

		public static T Load(Stream stream)
		{
			using (var reader = new StreamReader(stream, Encoding.UTF8))
				return Load(reader);
		}

		public static T Load(TextReader reader)
		{
			var obj = XmlSerializer.Deserialize(reader);
			return (T)obj;
		}

		public static T Load(XmlReader reader)
		{
			var obj = XmlSerializer.Deserialize(reader);
			return (T)obj;
		}
	}
}
