using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Xml.Linq;
using System.Xml.XPath;

namespace j6.BuildTools
{
	class Program
	{
		private const string START = "start";
		private const string STOP = "stop";
		private static readonly string[] ValidOperations = new [] { START, STOP };

		private static int Main(string[] args)
		{
			try
			{

				if (args.Length < 2)
				{
					ShowUsage();
					return -1;
				}
				var serviceName = args[0];
				var computerName = ValidOperations.Contains(args[1], StringComparer.InvariantCultureIgnoreCase)
					                   ? Environment.MachineName
					                   : args[1];
				var operation = (args.Length < 3 ? args[1] : args[2]).ToLowerInvariant();

				using(var controller = new ServiceController(serviceName, computerName))
					switch (operation)
					{
						case START:
							return RunCommand(
								controller,
								controller.Start,
								ServiceControllerStatus.Stopped,
								ServiceControllerStatus.Running,
								new[] {ServiceControllerStatus.Running},
								new[] { ServiceControllerStatus.StartPending, ServiceControllerStatus.StopPending },
								"Starting",
								"Started");
						case STOP:
							return RunCommand(
								controller,
								controller.Stop,
								ServiceControllerStatus.Running,
								ServiceControllerStatus.Stopped,
								new ServiceControllerStatus[] {ServiceControllerStatus.Stopped},
								new ServiceControllerStatus[] { ServiceControllerStatus.StopPending, ServiceControllerStatus.StartPending },
								"Stopping",
								"Stopped");
					}
			}
			catch (Exception ex)
			{
				Console.WriteLine(string.Format("ERROR: {0}", ex.Message));
				return -50;
			}

			return 0;
		}

		private static int RunCommand(ServiceController controller, Action command, ServiceControllerStatus desiredInitialStatus, ServiceControllerStatus desiredResultStatus, ServiceControllerStatus[] alreadyThereStatuses, ServiceControllerStatus[] waitStatuses, string pendingString, string doneString)
		{
			var currentStatus = controller.Status;
			if (waitStatuses.Contains(currentStatus))
			{
				Console.WriteLine(string.Format("Service {0} on {1} status is now {1}, waiting for {2}", controller.DisplayName, controller.MachineName, currentStatus, desiredInitialStatus));
				controller.WaitForStatus(desiredInitialStatus, new TimeSpan(0, 1, 0, 0));
			}
			currentStatus = controller.Status;
			if (currentStatus != desiredInitialStatus)
			{
				if (alreadyThereStatuses.Contains(currentStatus))
				{
					Console.WriteLine(string.Format("Service {0} on {1} is in status {2}, nothing to do.", controller.DisplayName, controller.MachineName, currentStatus));
					return 0;
				}
				Console.WriteLine(string.Format("Service {0} on {1} is not in a valid state ({2}) for action", controller.DisplayName, controller.MachineName, currentStatus));
				return -1;
			}
			Console.WriteLine(string.Format("{0} {1} on {2}", pendingString, controller.DisplayName, controller.MachineName));
			command();
			controller.WaitForStatus(desiredResultStatus, new TimeSpan(0, 1, 0, 0));
			Console.WriteLine("{0} {1} on {2}", doneString, controller.DisplayName, controller.MachineName);
			return 0;
		}



		private static void ShowUsage()
		{
			Console.WriteLine(string.Format("Usage: WinServiceCtrl <serviceName> [<computerName>] <{0}>", string.Join("/", ValidOperations)));
		}
	}
}
