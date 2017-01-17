using System;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;

namespace j6.BuildTools.MsBuildTasks
{
	public class LogEntry
	{
		// ReSharper disable UnusedAutoPropertyAccessor.Local
		// ReSharper disable MemberCanBePrivate.Local
		public int? Revision { get; set; }
		public string Node { get; set; }
		public string ParentRevision { get; set; }
		public string ParentNode { get; set; }
		public string Branch { get; set; }
		public string Author { get; set; }
		public string Email { get; set; }
		public DateTime? Date { get; set; }
		public string Msg { get; set; }
		public string[] FilesModified { get; set; }

		// ReSharper restore MemberCanBePrivate.Local
		// ReSharper restore UnusedAutoPropertyAccessor.Local

		public XElement ToXElement()
		{
			var returnValue = new XElement("modification");

			returnValue.Add(new XAttribute("type", "Changeset"));

			if (Date.HasValue)
				returnValue.Add(CreateElement("date", Date.Value.ToString("yyyy-MM-dd HH:mm:ss")));

			if (!string.IsNullOrWhiteSpace(Author))
				returnValue.Add(CreateElement("user", Author));

			if (!string.IsNullOrWhiteSpace(Msg))
				returnValue.Add(CreateElement("comment", Msg));

			if (!string.IsNullOrWhiteSpace(Node))
			{
				returnValue.Add(Node.Length > 12
					? CreateElement("changeNumber", Node.Substring(0, 12))
					: CreateElement("changeNumber", Node));
			}

			if (!string.IsNullOrWhiteSpace(Node))
				returnValue.Add(CreateElement("version", Node));

			if (!string.IsNullOrWhiteSpace(Email))
				returnValue.Add(CreateElement("email", Email));

			if (!string.IsNullOrWhiteSpace(Branch))
				returnValue.Add(new XAttribute("branch", Branch));

			return returnValue;
		}

		private XElement CreateElement(string elementName, string innerText)
		{
			var newElement = new XElement(elementName);
			newElement.SetValue(innerText);
			return newElement;
		}

		public static LogEntry CreateNew(XElement logEntryElement)
		{
			var author = logEntryElement.XPathSelectElement("author");
			var email = author == null ? null : author.Attribute("email");
			var parent = logEntryElement.XPathSelectElement("parent");
			var parentRevision = parent == null ? null : parent.Attribute("revision");
			var parentNode = parent == null ? null : parent.Attribute("node");
			var revision = logEntryElement.Attribute("revision");
			var node = logEntryElement.Attribute("node");
			var branch = logEntryElement.XPathSelectElement("branch");
			var date = logEntryElement.XPathSelectElement("date");
			var pathsElement = logEntryElement.XPathSelectElement("paths");
			var paths = pathsElement == null ? null : pathsElement.XPathSelectElements("path").ToArray();

			var returnValue = new LogEntry
			{
				Revision = revision == null ? null : (int?)int.Parse(revision.Value),
				Node = node == null ? null : node.Value,
				Branch = branch == null ? null : branch.Value,
				ParentRevision = parentRevision == null ? null : parentRevision.Value,
				ParentNode = parentNode == null ? null : parentNode.Value,
				Author = author == null ? null : author.Value,
				Email = email == null ? null : email.Value,
				Date = date == null ? null : (DateTime?)DateTime.Parse(date.Value),
				Msg = logEntryElement.XPathSelectElement("msg").Value,
				FilesModified = paths == null ? null : paths.Select(p => p.Value).ToArray()
			};
			return returnValue;
		}
	}

}
