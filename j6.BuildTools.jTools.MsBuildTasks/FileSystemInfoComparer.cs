using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace j6.BuildTools.MsBuildTasks
{
	public class FileSystemInfoComparer : IEqualityComparer<FileSystemInfo>
	{
		public bool Equals(FileSystemInfo x, FileSystemInfo y)
		{
			if (ReferenceEquals(x, y))
				return true;

			if (x == null || y == null)
				return false;

			return x.FullName.Equals(y.FullName, StringComparison.InvariantCultureIgnoreCase);
		}

		public int GetHashCode(FileSystemInfo obj)
		{
			return obj.FullName.GetHashCode();
		}
	}
}
