using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;

namespace j6.BuildTools.MsBuildTasks
{
    public class ConsolidateXmlPatches : Task
    {
        [Required]
        public string Root { get; set; }

        
        public override bool Execute()
        {
            var root = new DirectoryInfo(Root);
            var featureDirectories = root.GetDirectories().Select(fd => new { FeatureDirectory = fd, PatchFiles = fd
                .GetDirectories("Patch")
                .SelectMany(d => d.GetDirectories("Install"))
                .SelectMany(d => d.GetFiles("*.xml"))
            }).Where(fd => fd.PatchFiles.Any()).ToArray();

            foreach (var featureDir in featureDirectories)
            {
                var tableLookup = new Dictionary<string, Tuple<FileInfo, XDocument>>(StringComparer.InvariantCultureIgnoreCase);
                var modifiedFiles = new List<string>();
                foreach (var patchFile in Sort(featureDir.PatchFiles))
                {
                    XDocument doc;
                    using(var stream = patchFile.Item3.OpenRead())
                        doc = XDocument.Load(stream);
                    if(doc.Root == null)
                        continue;

                    var tableElements = doc.Root.Elements().ToArray();
                    var tableName = tableElements.Select(te => te.Name.LocalName).Distinct().SingleOrDefault();
                    if(tableName == null || tableElements.Length == 0)
                        continue;
                    var appSettingTable = tableName.ToLowerInvariant().Contains("appsetting".ToLowerInvariant());
                    if (!tableLookup.ContainsKey(tableName))
                    {
                        tableLookup.Add(tableName, new Tuple<FileInfo, XDocument>(patchFile.Item3, doc));
                    }
                    else
                    {
                        var tableFile = tableLookup[tableName];
                        modifiedFiles.Add(tableFile.Item1.FullName);
                        tableFile.Item2.Root.Add(tableElements);
                        foreach (var tableElement in tableElements)
                            tableElement.Remove();
                        patchFile.Item3.Delete();
                    }
                    if (appSettingTable)
                        Console.WriteLine(patchFile.Item3.FullName);
                }
                foreach (var updatedFiles in tableLookup.Values.Where(v => modifiedFiles.Contains(v.Item1.FullName)))
                {
                    using(var stream = updatedFiles.Item1.Open(FileMode.Create, FileAccess.Write, FileShare.None))
                        updatedFiles.Item2.Save(stream);
                }
            }
            return true;
        }

        private IEnumerable<Tuple<DateTime, bool, FileInfo>> Sort(IEnumerable<FileInfo> patchFiles)
        {
            const string PATCH_DATE_TEXT = "patch-date:";
            const string UPDATE_TEXT = "update:";
            var listToOrder = new List<Tuple<DateTime, bool, FileInfo>>();
            foreach (var patchFile in patchFiles)
            {
                DateTime? patchDate = default(DateTime?);
                bool? update = default(bool?);
                    
                using (var reader = new StreamReader(patchFile.OpenRead()))
                {
                    while ((!patchDate.HasValue || !update.HasValue) && !reader.EndOfStream)
                    {
                        var line = reader.ReadLine();
                        if (line == null)
                            break;
                        var patchDateIndex = line.IndexOf(PATCH_DATE_TEXT, StringComparison.InvariantCultureIgnoreCase);
                        
                        if (patchDateIndex >= 0)
                        {
                            var patchDateText = line.Substring(patchDateIndex + PATCH_DATE_TEXT.Length).Trim();
                            DateTime dt;
                            if (DateTime.TryParse(patchDateText, out dt))
                                patchDate = dt;
                        }

                        var updateIndex = line.IndexOf(UPDATE_TEXT, StringComparison.InvariantCultureIgnoreCase);
                        if (updateIndex < 0) continue;
                        
                        var updateText = line.Substring(updateIndex + UPDATE_TEXT.Length).Trim();
                        bool u;
                        if (bool.TryParse(updateText, out u))
                            update = u;
                    }
                }
                if(patchDate.HasValue)
                    listToOrder.Add(new Tuple<DateTime, bool, FileInfo>(patchDate.Value, update ?? false, patchFile));
            }
            return listToOrder.OrderBy(i => i.Item1);
        }
    }
}
