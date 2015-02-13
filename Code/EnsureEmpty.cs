using System;
using System.IO;

namespace j6.BuildTools
{
	internal class Program
	{
		private const string ShowContentsSwitch = "--ShowContents=";
		private const string MessageSwitch = "--Message=";
		
		private static int Main(string[] args)
		{
			if (args.Length < 1)
			{
				ShowUsage();
				return -100;
			}
			var fileName = args[0];
			var showContents = true;
			var message = (string)null;

			for (var i = 1; i < args.Length; i++)
			{
				if (args[i].StartsWith(ShowContentsSwitch, StringComparison.InvariantCultureIgnoreCase))
				{
					var value = args[i].Substring(ShowContentsSwitch.Length);
					if (!bool.TryParse(value, out showContents))
					{
						Console.WriteLine(string.Format("Cannot understand {0} as valid true/false value", value));
						return -100;
					}
				}
				if (args[i].StartsWith(MessageSwitch, StringComparison.InvariantCultureIgnoreCase))
					message = args[i].Substring(MessageSwitch.Length);
			}

			var fileInfo = new FileInfo(fileName);
			if (!fileInfo.Exists)
			{
				Console.WriteLine(string.Format("File {0} does not exist.", fileInfo.FullName));
				return -100;
			}

			if (fileInfo.Length == 0)
			{
				// Success!  Empty file
				return 0;
			}
			if (message != null)
			{
				Console.WriteLine(string.Format("{0}{1}", message, Environment.NewLine));
			}
			if (showContents)
			{
				using (var fileStream = fileInfo.Open(FileMode.Open, FileAccess.Read, FileShare.Read))
				using(var fileInput = new StreamReader(fileStream))
				{
					Console.Write(fileInput.ReadToEnd());
				}
			}
			var returnValue = (int)(fileInfo.Length%int.MaxValue);
			return returnValue == 0 ? 1 : returnValue;
		}

		private static void ShowUsage()
		{
			Console.WriteLine(string.Format("Usage: EnsureEmpty <FileName> [{0}<true/false>] [{1}<OptionalMessageIfFileIsNotEmpty>]", ShowContentsSwitch, MessageSwitch));
		}
	}
}
