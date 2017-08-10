using System;
using System.Collections.Generic;
using System.Linq;
using System.ServiceProcess;
using System.Threading;
using DeploymentTool;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System.Diagnostics;

// ReSharper disable RedundantStringFormatCall
namespace DeploymentMsBuildTasks
{
	public class WinServiceControl : Task
	{
		private enum Operation
		{
			Start,
			Stop
		}

		[Required]
		public string RequestedOperation { get; set; }

		public string[] ServiceName { get; set; }

		public string[] ComputerName { get; set; }

		public string[] AppServers { get; set; }

		public override bool Execute()
		{
#if DEBUG
			Thread.Sleep(10000);
#endif
			if(!(AppServers == null || AppServers.Any()) && ((ServiceName != null && ServiceName.Any()) || (ComputerName != null && ComputerName.Any())))
				throw new ArgumentException("You must specify either the AppServers parameter or both the ServiceName and ComputerName parameters");

			if (AppServers != null && AppServers.Any())
			{
				var appServers = MsBuild.DeserializeServers<AppServer>(AppServers);
				var computerServices =
					appServers.Select(s => new {s.ServiceName, s.HostName})
					          .Distinct()
					          .GroupBy(s => s.HostName)
					          .ToDictionary(c => c.Key, c => c.Select(s => s.ServiceName).ToArray());
				var returnValue = 0;
				computerServices.AsParallel().ForAll(computerService =>
					{
						returnValue += Run(computerService.Value, new [] { computerService.Key });
					});
				return returnValue == 0;
			}

			return Run(ServiceName, ComputerName) == 0;
		}

		public int Run(string [] serviceNames, string [] computerNames)
		{
			try
			{
				Operation requestedOperation;
				var validRequest = Enum.TryParse(RequestedOperation, true, out requestedOperation);
				if (!validRequest)
					throw new ArgumentException(string.Format("{0} is not a valid operation.  Valid operations are: {1} or {2}", RequestedOperation, Operation.Start, Operation.Stop));
				var returnValue = 0;

				serviceNames.Where(s => !string.IsNullOrWhiteSpace(s)).AsParallel().ForAll(serviceName =>
					{
						var name = serviceName;
						computerNames.Where(s => !string.IsNullOrWhiteSpace(s)).AsParallel().ForAll(computerName =>
							{
								try
								{

									using (var controller = new ServiceController(name, computerName))
										switch (requestedOperation)
										{
											case Operation.Start:
												returnValue += RunCommand(
													controller,
													controller.Start,
													ServiceControllerStatus.Stopped,
													ServiceControllerStatus.Running,
													new[] {ServiceControllerStatus.Running},
													new[] { ServiceControllerStatus.StartPending, ServiceControllerStatus.StopPending },
													"Starting",
													"Started");
												break;
											case Operation.Stop:
												returnValue += RunCommand(
													controller,
													controller.Stop,
													ServiceControllerStatus.Running,
													ServiceControllerStatus.Stopped,
													new[] {ServiceControllerStatus.Stopped},
													new[] { ServiceControllerStatus.StopPending, ServiceControllerStatus.StartPending },
													"Stopping",
													"Stopped");
												break;
										}
								}
								catch (Exception ex)
								{
									Console.Error.WriteLine(ex.Message);
									throw;
								}
							});
					});
				return returnValue;
			}
			catch (Exception ex)
			{
				Console.Error.WriteLine(ex.Message);
				return -50;
			}
		}
		private static int RunCommand(ServiceController controller, Action command, ServiceControllerStatus desiredInitialStatus, ServiceControllerStatus desiredResultStatus, IEnumerable<ServiceControllerStatus> alreadyThereStatuses, IEnumerable<ServiceControllerStatus> waitStatuses, string pendingString, string doneString)
		{
			var currentStatus = controller.Status;
			if (waitStatuses.Contains(currentStatus))
			{
				Console.WriteLine(string.Format("Service {0} on {1} status is now {2}, waiting for {3}", controller.DisplayName, controller.MachineName, currentStatus, desiredInitialStatus));
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
	}
}
