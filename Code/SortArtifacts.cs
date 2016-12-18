using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Microsoft.Build.Utilities;
using System.Xml.Linq;

namespace j6.BuildTools.MsBuildTasks
{
    public class SortArtifacts : Task
    {
        public override bool Execute()
        {
            var serverNames = new []
            {
                new { ServerName = "jia-build0", Letter = 'z' },
                new { ServerName = "jia-build1", Letter = 'a' },
                new { ServerName = "jia-build2", Letter = 'b' },
                new { ServerName = "jia-build3", Letter = 'c' },
                new { ServerName = "jia-build4", Letter = 'd' },
            };

            var doc = XDocument.Load(@"C:\build\config\cruisecontrol\common\server\tracks.xml");
            Func<XAttribute, bool> predicate =
                a =>
                a.Name.LocalName.Equals("name", StringComparison.InvariantCultureIgnoreCase) &&
                a.Value.StartsWith("queue", StringComparison.InvariantCultureIgnoreCase);
            Func<XAttribute, bool> projectPredicate =
                a =>
                a.Name.LocalName.Equals("projectName", StringComparison.InvariantCultureIgnoreCase);

            var elements = doc.Root.Elements()
               .Select(e => new {Element = e, Attributes = e.Attributes()})
               .Where(
                   e =>
                   e.Attributes.Any(predicate));
            foreach (var element in elements)
            {
                var queueName = element.Attributes.Single(predicate).Value;
                var server = serverNames.Single(s => s.Letter.Equals(queueName[queueName.Length - 1]));
                var projects = element.Element.Elements().Attributes().Where(projectPredicate).Select(p => p.Value).ToArray();
                EnsureProjectsInCorrectLocation(server.ServerName, projects,
                                                serverNames.Select(s => s.ServerName).ToArray());
            }
            return false;
        }

        private void EnsureProjectsInCorrectLocation(string correctServer, string[] projects, string[] allServers)
        {
            var directoryNames = new[] {"artifacts", "artifacts.sort"};
            var possibleLocations =
                allServers.SelectMany(
                    server =>
                    projects.SelectMany(
                        project =>
                        directoryNames.Select(
                            dir => new { Project = project, Directory = new DirectoryInfo(string.Format(@"\\{0}\e$\{1}\{2}", server, dir, project)) }))).ToArray();

            var correctLocations =
                possibleLocations.Where(p => p.Directory.FullName.StartsWith(string.Format(@"\\{0}\e$\artifacts\", correctServer))).ToArray();

            foreach (var correctLocation in correctLocations.Where(c => !c.Directory.Exists))
            {
                var existingLocations =
                    possibleLocations.Where(p => p.Project.Equals(correctLocation.Project, StringComparison.InvariantCultureIgnoreCase) && p.Directory.Exists).ToArray();

                foreach (var location in existingLocations)
                    location.Directory.MoveTo(correctLocation.Directory.FullName);
            }
        }

    }
}
