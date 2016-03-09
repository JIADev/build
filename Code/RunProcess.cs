using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;

namespace j6.BuildTools.MsBuildTasks
{
	public class BuildSystem
	{
		public bool ProcessRunning { get { return !Process.HasExited; } }
		public int ExitCode { get { return Process.ExitCode; } }

		public delegate void ProcessTextReceivedDelegate(object sender, ProcessTextReceivedEventArgs args);
		public event ProcessTextReceivedDelegate ProcessTextReceived;

		private Process Process { get; set; }

		public static BuildSystem StartRunProcess(string process,
		                                          string args,
		                                          string workingDirectory,
		                                          Dictionary<string, string> extraEnvVariables = null,
		                                          int timeoutSeconds = 0,
		                                          bool displayStdOut = true,
		                                          bool displayStdErr = true,
		                                          ProcessTextReceivedDelegate textReceived = null)
		{
			var buildSystem = new BuildSystem();
			var startInfo = CreateStartInfo(process, args, workingDirectory);
			buildSystem.GetProcess(startInfo, null, null, extraEnvVariables, displayStdOut, displayStdErr);
			if (textReceived != null)
				buildSystem.ProcessTextReceived += textReceived;
			buildSystem.Start();
			return buildSystem;
		}

		public static string RunProcess(string process,
		                                string args,
		                                string workingDirectory,
		                                Dictionary<string, string> extraEnvVariables = null,
		                                int timeoutSeconds = 0,
		                                bool displayStdOut = true,
		                                bool displayStdErr = true)

		{
			var buildSystem = new BuildSystem();
			var startInfo = CreateStartInfo(process, args, workingDirectory);
			var outputString = new StringWriter();
			var errorBuilder = new StringWriter();
			buildSystem.GetProcess(startInfo, outputString, errorBuilder, extraEnvVariables, displayStdOut, displayStdErr);
			buildSystem.Start();

			buildSystem.WaitForExit(timeoutSeconds);
			
			if (buildSystem.ProcessRunning)
			{
				buildSystem.KillProcess();
				throw new TimeoutException(string.Format("Process {0} timed out after {1} seconds", startInfo.FileName, timeoutSeconds));
			}
			if (buildSystem.ExitCode != 0 || !string.IsNullOrWhiteSpace(errorBuilder.ToString()))
				throw new Exception(
					string.Format("{0} {1}: {2}{3}{4}", process, args, buildSystem.ExitCode, Environment.NewLine, errorBuilder));

			return outputString.ToString();
		}

		private void Start()
		{
			Process.Start();
			Process.BeginOutputReadLine();
			Process.BeginErrorReadLine();
		}

		private void GetProcess(ProcessStartInfo startInfo, TextWriter outputString, TextWriter errorString,
			Dictionary<string, string> extraEnvVariables = null,
			bool displayStdOut = true,
			bool displayStdErr = true)
		{
			foreach (var extraEnvVariable in extraEnvVariables ?? new Dictionary<string, string>())
			{
				startInfo.EnvironmentVariables[extraEnvVariable.Key] = extraEnvVariable.Value;
			}
			var proc = new Process
			{
				StartInfo = startInfo
			};

			proc.OutputDataReceived += (sender, eventArgs) => proc_OutputDataReceived(sender, eventArgs, outputString, displayStdOut);
			proc.ErrorDataReceived += (sender, eventArgs) => proc_OutputDataReceived(sender, eventArgs, errorString, displayStdErr, true);

			Trace.WriteLine(string.Format("Starting: {0} with arguments: {1}", startInfo.FileName, startInfo.Arguments));
			Process = proc;
		}

		private static ProcessStartInfo CreateStartInfo(string process, string args, string workingDirectory)
		{
			return
				new ProcessStartInfo
				{
					FileName = process,
					UseShellExecute = false,
					RedirectStandardError = true,
					RedirectStandardOutput = true,
					CreateNoWindow = true,
					Arguments = args,
					WorkingDirectory = workingDirectory,
					StandardErrorEncoding = Encoding.UTF8,
					StandardOutputEncoding = Encoding.UTF8,
				};
		}

		private void proc_OutputDataReceived(object sender, DataReceivedEventArgs e, TextWriter outputString,
		                                            bool displayStdOut, bool isError = false)
		{
			var lockObject = outputString ?? new object();

			lock (lockObject)
			{
				if (displayStdOut)
				{
					if (isError)
					{
						Console.ForegroundColor = ConsoleColor.Red;
						Console.Error.WriteLine(e.Data);
						Console.ResetColor();
					}
					else
					{
						Console.WriteLine(e.Data);
					}
				}
				if(outputString != null)
					outputString.WriteLine(e.Data);
			}
			if (ProcessTextReceived != null && e.Data != null)
				ProcessTextReceived(this, new ProcessTextReceivedEventArgs
					{
						Text = e.Data,
						IsError = isError
					});
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

		internal void WaitForExit(int timeoutSeconds = 0)
		{
			if (timeoutSeconds > 0)
			{
				Process.WaitForExit(timeoutSeconds*1000);
				return;
			}
			Process.WaitForExit();
		}

		internal void KillProcess()
		{
			Process.Kill();
		}
	}

	public class ProcessTextReceivedEventArgs
	{
		public string Text { get; set; }

		public bool IsError { get; set; }
	}
}
