using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;

namespace j6.BuildTools
{
	class Program
	{
		private static int Main(string[] args)
		{
			var files = args;
			if (files.Length == 0)
				files = Directory.GetFiles(Environment.CurrentDirectory, "*.*");

			foreach (var file in files)
			{
				var info = new FileInfo(file);
				if(!info.Exists)
					continue;
				if(info.Length == 0)
					info.Delete();
			}
			return 0;
		}
	}
}
