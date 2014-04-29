using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;

namespace j6.BuildTools
{
	public static class BuildSystem
	{
		public static string RunProcess(string process,
			string args,
			string workingDirectory,
			Dictionary<string, string> extraEnvVariables = null)
		{
			var startInfo =
				new ProcessStartInfo
				{
					FileName = process,
					UseShellExecute = false,
					RedirectStandardError = true,
					RedirectStandardOutput = true,
					Arguments = args,
					WorkingDirectory = workingDirectory,
					StandardErrorEncoding = Encoding.UTF8,
					StandardOutputEncoding = Encoding.UTF8,
				};
			foreach (var extraEnvVariable in extraEnvVariables ?? new Dictionary<string, string>())
			{
				startInfo.EnvironmentVariables[extraEnvVariable.Key] = extraEnvVariable.Value;
			}
			var proc = new Process
			{
				StartInfo = startInfo
			};

			var outputString = new StringWriter();
			Trace.WriteLine(string.Format("Starting: {0} with arguments: {1}", startInfo.FileName, startInfo.Arguments));
			proc.Start();
			var errorBuilder = new StringBuilder();

			var outputWriter = new Thread(() =>
			{
				string line;
				lock (proc)
					while ((line = proc.StandardOutput.ReadLine()) != null)
					{
						Console.WriteLine(line);
						outputString.WriteLine(line);
					}
			});
			var errorWriter = new Thread(() =>
			{
				string line;
				lock (proc)
					while ((line = proc.StandardError.ReadLine()) != null)
					{
						Console.Error.WriteLine(line);
						errorBuilder.AppendLine(line);
					}
			});
			outputWriter.Start();
			errorWriter.Start();
			if (!string.IsNullOrEmpty(errorBuilder.ToString()))
				throw new Exception(errorBuilder.ToString());

			proc.WaitForExit();
			outputWriter.Join();
			errorWriter.Join();

			if (proc.ExitCode != 0)
				throw new Exception(
					string.Format("{0} {1}: {2}", process, args, proc.ExitCode));

			return outputString.ToString();
		}

		public static void PowerShell(string command, string workingDirectory = ".", bool encodeCommand = false)
		{
			if (encodeCommand)
			{
				command = Convert.ToBase64String(Encoding.Unicode.GetBytes(command));
			}
			RunProcess("powershell",
				string.Format("-{1} \"{0}\"", command, encodeCommand ? "EncodedCommand" : "Command"),
					workingDirectory);
		}
	}
}
