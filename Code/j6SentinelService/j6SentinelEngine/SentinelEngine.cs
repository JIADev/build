using System.Threading;
using System.Threading.Tasks;
using Microsoft.Web.Administration;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;

namespace j6SentinelEngine
{
    public class SentinelEngine
    {
	    public SentinelConfiguration Config
	    {
			get
			{
				return SentinelConfiguration.Load(ConfigurationManager.AppSettings["ConfigFile"]);
			}
	    }

		const ServiceControllerStatus Stop = ServiceControllerStatus.Stopped;
		const ServiceControllerStatus Start = ServiceControllerStatus.Running;
		const ObjectState StartAppPool = ObjectState.Started;
	    const ObjectState StopAppPool = ObjectState.Stopped;

		public void CheckServers()
		{
			foreach (var server in Config.Servers)
			{
				try
				{
					var service = new YanbalIntegrationService.YanbalIntegrationService {Url = server.PingUrl};
					bool pingResult;
					bool pingResultSpecified;
					service.Ping(out pingResult, out pingResultSpecified);
					//return;
				}
				catch(Exception ex)
				{
					Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} Ping exception: {1}", DateTime.Now, ex.Message));
				}

				// If we're down here, the service did not respond to a ping succesfully
				if (!string.IsNullOrWhiteSpace(server.AppPoolName))
				{
					if (!string.IsNullOrWhiteSpace(server.Name))
					{
						throw new ConfigurationException("Cannot control app pools on remote servers");
					}
					AppPoolRecycle(server.AppPoolName);
					
				}
				if (!string.IsNullOrWhiteSpace(server.ServiceName))
				{
					SetState(server.ServiceName, server.Name, Stop);
					SetState(server.ServiceName, server.Name, Start);
				}
			}
		}

		private void AppPoolRecycle(string appPoolName)
		{
			using (var serverManager = new ServerManager())
			{
				var appPool =
					serverManager.ApplicationPools.SingleOrDefault(
						ap => ap.Name.Equals(appPoolName, StringComparison.InvariantCultureIgnoreCase));
				if (appPool == null)
					throw new ConfigurationException("App Pool " + appPoolName + " not found");
				
				SetAppPoolState(appPool, StopAppPool);
				SetAppPoolState(appPool, StartAppPool);
			}
		}

		private static void WaitForState(ApplicationPool appPool, ObjectState objectState, TimeSpan waitTimeout)
		{
			var giveUpTime = DateTime.UtcNow.Add(waitTimeout);
			while (appPool.State != objectState && DateTime.UtcNow < giveUpTime)
				Thread.Sleep(100);
		}

		private static void SetState(string serviceName, string computerName, ServiceControllerStatus state)
		{
			using (var controller = new ServiceController(serviceName, computerName))
				switch (state)
				{
					case Start:
						RunCommand(
							controller,
							controller.Start,
							ServiceControllerStatus.Stopped,
							ServiceControllerStatus.Running,
							new[] { ServiceControllerStatus.StartPending, ServiceControllerStatus.Running },
							new[] { ServiceControllerStatus.StopPending },
							"Starting",
							"Started");
						return;
					case Stop:
						RunCommand(
							controller,
							controller.Stop,
							ServiceControllerStatus.Running,
							ServiceControllerStatus.Stopped,
							new [] { ServiceControllerStatus.StopPending, ServiceControllerStatus.Stopped },
							new [] { ServiceControllerStatus.StartPending },
							"Stopping",
							"Stopped");
						return;
				}
		}

		private static void RunCommand(ServiceController controller, Action command, ServiceControllerStatus desiredInitialStatus, ServiceControllerStatus desiredResultStatus, IEnumerable<ServiceControllerStatus> alreadyThereStatuses, IEnumerable<ServiceControllerStatus> waitStatuses, string pendingString, string doneString)
		{
			try
			{
				var currentStatus = controller.Status;
				if (waitStatuses.Contains(currentStatus))
				{
					Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} Service {1} on {2} status is now {3}, waiting for {4}", DateTime.Now, controller.DisplayName,
					                              controller.MachineName, currentStatus, desiredInitialStatus));
					controller.WaitForStatus(desiredInitialStatus, new TimeSpan(0, 0, 1, 0));
				}
				currentStatus = controller.Status;
				if (currentStatus != desiredInitialStatus)
				{
					if (alreadyThereStatuses.Contains(currentStatus))
					{
						Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} Service {1} on {2} is in status {3}, nothing to do.", DateTime.Now, controller.DisplayName,
						                              controller.MachineName, currentStatus));
						return;
					}
					Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} Service {1} on {2} is not in a valid state ({3}) for action", DateTime.Now, controller.DisplayName,
					                              controller.MachineName, currentStatus));
					return;
				}
				Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} {1} {2} on {3}", DateTime.Now, pendingString, controller.DisplayName, controller.MachineName));
				command();
				controller.WaitForStatus(desiredResultStatus, new TimeSpan(0, 0, 1, 0));
				Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} {1} {2} on {3}", DateTime.Now, doneString, controller.DisplayName, controller.MachineName));
			}
			catch (Exception ex)
			{
				Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} An error occurred: {1}", DateTime.Now, ex));
			}
		}

	    private static void SetAppPoolState(ApplicationPool appPool, ObjectState state)
	    {
		    switch (state)
		    {
			    case StartAppPool:
				    RunAppPoolCommand(
					    appPool,
					    () => appPool.Start(),
					    ObjectState.Stopped,
						ObjectState.Started,
					    new[] {ObjectState.Starting, ObjectState.Started },
					    new[] {ObjectState.Stopping},
					    "Starting",
					    "Started");
				    return;
			    case StopAppPool:
					RunAppPoolCommand(
					    appPool,
					    () => appPool.Stop(),
					    ObjectState.Started,
						ObjectState.Stopped,
						new[] { ObjectState.Stopping, ObjectState.Stopped },
						new[] { ObjectState.Starting },
					    "Stopping",
					    "Stopped");
				    return;
		    }
	    }

		private static void RunAppPoolCommand(ApplicationPool appPool, Action command, ObjectState desiredInitialStatus, ObjectState desiredResultStatus, IEnumerable<ObjectState> alreadyThereStatuses, IEnumerable<ObjectState> waitStatuses, string pendingString, string doneString)
		{
			try
			{
				var currentStatus = appPool.State;
				if (waitStatuses.Contains(currentStatus))
				{
					Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} App Pool {1} status is now {2}, waiting for {3}", DateTime.Now, appPool.Name,
												  currentStatus, desiredInitialStatus));
					WaitForState(appPool, desiredInitialStatus, new TimeSpan(0, 0, 1, 0));
				}
				currentStatus = appPool.State;
				if (currentStatus != desiredInitialStatus)
				{
					if (alreadyThereStatuses.Contains(currentStatus))
					{
						Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} App Pool {1} is in status {2}, nothing to do.", DateTime.Now, appPool.Name,
													  currentStatus));
						return;
					}
					Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} App Pool {1} is not in a valid state ({2}) for action", DateTime.Now, appPool.Name,
												  currentStatus));
					return;
				}
				Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} {1} App Pool {2}", DateTime.Now, pendingString, appPool.Name));
				command();
				WaitForState(appPool, desiredResultStatus, new TimeSpan(0, 0, 1, 0));
				Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} {1} App Pool {2}", DateTime.Now, doneString, appPool.Name));
			}
			catch (Exception ex)
			{
				Trace.WriteLine(string.Format("{0:yyyy-MM-dd HH:mm:ss} An error occurred: {1}", DateTime.Now, ex));
			}
		}
	}
}
