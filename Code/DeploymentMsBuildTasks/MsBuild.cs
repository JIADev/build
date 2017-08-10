using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DeploymentTool;
using j6.BuildTools.MsBuildTasks;
using Environment = System.Environment;
using System.IO;
using System.Xml.Linq;

namespace DeploymentMsBuildTasks
{
	public class MsBuild
	{
		public string[] Parameters { get; set; }

		public string Executable
		{
			get { return @"C:\Windows\Microsoft.NET\Framework64\v4.0.30319\Msbuild.exe"; }
		}

		public bool Run(BuildSystem.ProcessTextReceivedDelegate textReceived, string target, DeploymentTool.Environment buildEnvironment)
		{
			var parameters = GenerateParameters(buildEnvironment);
			return Run(textReceived, target, parameters);
		}

		public bool Run(BuildSystem.ProcessTextReceivedDelegate textReceived, string target, params string[] parameters)
		{
			if (string.IsNullOrWhiteSpace(target))
				throw new ArgumentNullException("target");

			var arguments = string.Format("/t:{0}{1}", target,
			                              string.Join("", parameters.Select(p => string.Format(" /p:{0}", p))));

			var buildSystem = BuildSystem.StartRunProcess(Executable, string.Join(" ", arguments),
			                                                       Environment.CurrentDirectory, textReceived: textReceived);
			buildSystem.WaitForExit();
			return buildSystem.ExitCode != 0;
		}

		public Tuple<string,string>[] GetTargets(string processName)
		{
			var projFiles = Directory.GetFiles(Environment.CurrentDirectory, "*.proj");
			var projFile = projFiles.Single();
			XDocument projContents;
			using (var stream = new StreamReader(projFile))
				projContents = XDocument.Load(stream);

			var itemGroups = projContents.Root.Elements().Where(e => e.Name.LocalName.Equals("ItemGroup"));
			var targetElements = projContents.Root.Elements().Where(e => e.Name.LocalName.Equals("Target"));
			var none = itemGroups.Elements().Where(e => e.Name.LocalName.Equals("None"));
			var element = none.Single(e => e.Attribute("Label").Value.Equals(processName));
			var targets = element.Attribute("Include").Value.Split(new[] {';'}, StringSplitOptions.RemoveEmptyEntries);
			var returnValue = targets.Select(t => targetElements.Where(te => t.Equals(te.Attribute("Name").Value))
							  .Select(e => new Tuple<string, string>(e.Attribute("Name").Value, GetDescription(e))).Single()).ToArray();
			return returnValue;
			//return new string[0];
		}

		private string GetDescription(XElement targetElement)
		{
			var descriptionElement = targetElement.Elements()
			             .Where(e => e.Name.LocalName.Equals("PropertyGroup"))
			             .SelectMany(e1 => e1.Elements().Where(e => e.Name.LocalName.Equals("TargetDescription")))
			             .SingleOrDefault();
			if (descriptionElement == null)
				return null;
			return descriptionElement.Value;
		}
		private string[] GenerateParameters(DeploymentTool.Environment buildEnvironment)
		{
			var parameterDictionary = new Dictionary<string, string>
				{
					{ "Environment_Name", buildEnvironment.Name },
					{ "Environment_Client", buildEnvironment.Client },
					{ "Environment_Database_Name", buildEnvironment.Database.Name },
					{ "Environment_Database_Server_HostName", buildEnvironment.Database.Server.HostName },
					{ "Environment_Database_Server_BackupLocation", buildEnvironment.Database.Server.BackupLocation },
					{ "Environment_Database_Server_RestoreLocation", buildEnvironment.Database.Server.RestoreLocation },
					{ "Environment_Database_Server_SqlInstance", buildEnvironment.Database.Server.SqlInstance },
					{ "Environment_Redis", string.Join(";", buildEnvironment.RedisServers.Select(SerializeServer)) },
					{ "Environment_Web_SiteUrl", buildEnvironment.WebServers.SiteUrl },
					{ "Environment_Web", string.Join(";", buildEnvironment.WebServers.WebServers.Select(SerializeServer)) },
					{ "Environment_RTE", string.Join(";", buildEnvironment.RTEServers.Select(SerializeServer)) },
				};

			return parameterDictionary.Select(p => string.Format("{0}=\"{1}\"", p.Key, p.Value)).ToArray();
		}

		private string SerializeServer<T>(T server) where T : Server
		{
			var redisServer = server as RedisServer;
			var appServer = server as AppServer;
			var webServer = server as WebServer;

			var paramDictionary = new Dictionary<string, string>
				{
					{"HostName", server.HostName}
				};

			if(redisServer != null)
				paramDictionary.Add("DbNumber", redisServer.DbNumber.ToString(CultureInfo.InvariantCulture));

			if (appServer != null)
			{
				paramDictionary.Add("AppLocation", appServer.AppLocation);
				paramDictionary.Add("BackupLocation", appServer.BackupLocation);
				paramDictionary.Add("ServiceName", appServer.ServiceName);
			}

			if (webServer != null)
			{
				paramDictionary.Add("SiteName", webServer.SiteName);
				paramDictionary.Add("ServerUrl", webServer.ServerUrl);
			}

			return string.Join("|", paramDictionary.Select(kv => string.Format("{0}={1}", kv.Key, kv.Value)));
		}



		internal static T[] DeserializeServers<T>(string[] appServers) where T : Server, new()
		{
			var returnValue = appServers.Select(DeserializeServer<T>).ToArray();
			return returnValue;
		}

		internal static T DeserializeServer<T>(string serverVariables) where T : Server, new()
		{
			var parameterDictionary =
				serverVariables.Split(new[] {'|'}, StringSplitOptions.RemoveEmptyEntries)
				         .Select(p => p.Split('='))
				         .Where(p => p.Length == 2)
				         .Select(p => new {Key = p[0], Value = p[1]})
				         .ToDictionary(p => p.Key, p => p.Value);
			
			var server = new T
				{
					HostName = TryGet(parameterDictionary, "HostName"),
				};
			
			var redisServer = server as RedisServer;
			var appServer = server as AppServer;
			var webServer = server as WebServer;

			if (redisServer != null)
				redisServer.DbNumber = byte.Parse(TryGet(parameterDictionary, "DbNumber") ?? default(byte).ToString(CultureInfo.InvariantCulture));
				

			if (appServer != null)
			{
				appServer.AppLocation = TryGet(parameterDictionary, "AppLocation");
				appServer.BackupLocation = TryGet(parameterDictionary, "BackupLocation");
				appServer.ServiceName = TryGet(parameterDictionary, "ServiceName");
			}

			if (webServer != null)
			{
				webServer.SiteName = TryGet(parameterDictionary, "SiteName");
				webServer.ServerUrl = TryGet(parameterDictionary, "ServerUrl");
			}

			return server;
		}

		private static string TryGet(Dictionary<string, string> dictionary, string keyName)
		{
			return dictionary.ContainsKey(keyName) ? dictionary[keyName] : null;
		}
	}
}
