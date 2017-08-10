using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace j6.BuildTools.MsBuildTasks
{
    public class FileEnumerator
    {
        private readonly Dictionary<string, object> _enumerationData = new Dictionary<string,object>();

        public Dictionary<string, object> Data
        {
            get { return _enumerationData; }
        }

        public event Action<FileEnumerator, FileInfo> FileFound;
        public event Action<FileEnumerator> EnumerationComplete;
        
        public void TraverseDirectory(DirectoryInfo currentDirectory, bool isRoot = true, bool recurse = true, int? maxDepth = null)
        {
            if (FileFound != null)
            {
                if (recurse && (maxDepth ?? 1) > 0)
                {
                    var subDirs = currentDirectory.GetDirectories()
                        .Where(dInfo =>
                               !dInfo.Attributes.HasFlag(FileAttributes.Hidden)
                               && !dInfo.Name.StartsWith("."));
                    foreach (var subDir in subDirs)
                    {
                        TraverseDirectory(subDir, false, true, maxDepth.HasValue ? maxDepth.Value - 1 : (int?) null);
                    }
                }
                var files = currentDirectory.GetFiles().Where(fInfo => !fInfo.Attributes.HasFlag(FileAttributes.Hidden) && !fInfo.Name.StartsWith("."));
                foreach (var file in files)
                    FileFound(this, file);
            }

            if (isRoot && EnumerationComplete != null)
                EnumerationComplete(this);
        }
    }
}
