using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml;
using System.Xml.Serialization;

namespace j6.BuildTools.MsBuildTasks
{
	[Serializable]
	public abstract class SerializableObject<T> where T : SerializableObject<T>, new()
	{
		[XmlIgnore]
		public string FileName { get; set; }

		static readonly XmlSerializer serializer = new XmlSerializer(typeof(T));

		public static T Load(FileInfo inputFile)
		{
			return Load(inputFile.FullName);
		}

		public static T Load(string inputFile)
		{
			using (var inputStream = File.OpenRead(inputFile))
			{
				var returnValue = Load(inputStream);
				returnValue.FileName = inputFile;
				return returnValue;
			}
		}

		public static T Load(Stream inputStream)
		{
			return (T) serializer.Deserialize(inputStream);
		}

		public static T Load(TextReader inputReader)
		{
			return (T) serializer.Deserialize(inputReader);
		}

		public static T Load(XmlReader inputReader)
		{
			return (T) serializer.Deserialize(inputReader);
		}

		public static T Load(XmlReader inputReader, string encodingStyle)
		{
			return (T) serializer.Deserialize(inputReader, encodingStyle);
		}

		public static T Load(XmlReader inputReader, string encodingStyle, XmlDeserializationEvents events)
		{
			return (T) serializer.Deserialize(inputReader, encodingStyle, events);
		}

		public static T Load(XmlReader inputReader, XmlDeserializationEvents events)
		{
			return (T) serializer.Deserialize(inputReader, events);
		}

		public void Save(XmlSerializerNamespaces namespaces = null, Encoding outputEncoding = null)
		{
			Save(FileName, namespaces, outputEncoding);
		}

		public void Save(FileInfo outputFile, XmlSerializerNamespaces namespaces = null, Encoding outputEncoding = null)
		{
			Save(outputFile.FullName, namespaces, outputEncoding);
		}

		public void Save(string outputFile, XmlSerializerNamespaces namespaces = null, Encoding outputEncoding = null)
		{
			using (var outputStream = new FileStream(outputFile, FileMode.Create, FileAccess.Write, FileShare.None))
				Save(outputStream, namespaces, outputEncoding);
		}

		public void Save(Stream outputStream, XmlSerializerNamespaces namespaces = null, Encoding outputEncoding = null)
		{
			if(outputEncoding == null)
				serializer.Serialize(outputStream, this, namespaces);
			else
				using (var writer = new XmlTextWriter(outputStream, outputEncoding))
				{
					writer.Formatting = Formatting.Indented;
					serializer.Serialize(writer, this, namespaces);
				}
		}

		public void Save(TextWriter writer)
		{
			serializer.Serialize(writer, this);
		}

		public void Save(TextWriter writer, XmlSerializerNamespaces namespaces)
		{
			serializer.Serialize(writer, this, namespaces);
		}

		public void Save(XmlWriter writer)
		{
			serializer.Serialize(writer, this);
		}

		public void Save(XmlWriter writer, XmlSerializerNamespaces namespaces)
		{
			serializer.Serialize(writer, this, namespaces);
		}

		public void Save(XmlWriter writer, XmlSerializerNamespaces namespaces, string encodingStyle)
		{
			serializer.Serialize(writer, this, namespaces, encodingStyle);
		}

		public void Save(XmlWriter writer, XmlSerializerNamespaces namespaces, string encodingStyle, string id)
		{
			serializer.Serialize(writer, this, namespaces, encodingStyle, id);
		}
	}
}
