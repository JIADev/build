using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace j6.BuildTools.MsBuildTasks
{
    public class DeleteIdenticalFiles : Task
    {
        [Required]
        public string SourceDir { get; set; }

        [Required]
        public string TargetDir { get; set; }

        public override bool Execute()
        {
            var source = new DirectoryInfo(SourceDir);
            var target = new DirectoryInfo(TargetDir);

            DeleteDuplicates(source, target);
            return true;
        }

        private void DeleteDuplicates(DirectoryInfo source, DirectoryInfo target)
        {
            var sourceContents = source.GetFileSystemInfos();
            var targetContents = target.GetFileSystemInfos();

            var sourcesAndTargets = sourceContents.Join(targetContents, fsi => fsi.Name.ToLowerInvariant(),
                                                      fsi => fsi.Name.ToLowerInvariant(),
                                                      (s, t) => new {Source = s, Target = t}).Where(st => st.Source != null && st.Target != null);

            foreach (var sourceAndTarget in sourcesAndTargets)
            {
                var sourceDir = sourceAndTarget.Source as DirectoryInfo;
                var sourceFile = sourceAndTarget.Source as FileInfo;
                var targetDir = sourceAndTarget.Target as DirectoryInfo;
                var targetFile = sourceAndTarget.Target as FileInfo;

                var typesMisMatch = (sourceDir == null && targetDir != null) || 
                                    (sourceDir != null && targetDir == null) ||
                                    (sourceFile == null && targetFile != null) ||
                                    (sourceFile != null && targetFile == null);
                
                if(typesMisMatch)
                    continue;

                if (sourceDir != null)
                {
                    DeleteDuplicates(sourceDir, targetDir);
                    if(!targetDir.GetFileSystemInfos().Any())
                        targetDir.Delete();
                    continue;
                }
                if (sourceFile != null && FilesMatch(sourceFile, targetFile))
                {
                    targetFile.Delete();
                }
            }

        }
        static readonly MD5 Hash = MD5.Create();
                
        private bool FilesMatch(FileInfo sourceFile, FileInfo targetFile)
        {
            if (sourceFile.Length != targetFile.Length)
                return false;
            byte[] sourceHash;
            byte[] targetHash;
            
            using(var sourceStream = sourceFile.OpenRead())
            using (var targetStream = targetFile.OpenRead())
            {
                sourceHash = Hash.ComputeHash(sourceStream);
                targetHash = Hash.ComputeHash(targetStream);
                
                if (sourceHash.Length != targetHash.Length || sourceHash.Length == 0)
                    return false;

            }

            return !sourceHash.Where((t, i) => t != targetHash[i]).Any();
        }
    }
}
