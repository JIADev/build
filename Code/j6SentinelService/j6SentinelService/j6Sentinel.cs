using System.Diagnostics;
using System.ServiceProcess;
using j6SentinelEngine;
using System.Timers;

namespace j6SentinelService
{
	public partial class j6Sentinel : ServiceBase
	{
		readonly SentinelEngine engine = new SentinelEngine();
		private readonly Timer timer1 = new Timer(10000) {AutoReset = false};
		public j6Sentinel()
		{
#if DEBUG
			Debugger.Launch();
#endif
			InitializeComponent();
			timer1.Interval = engine.Config.PollingInterval*1000;
			Trace.AutoFlush = true;
			timer1.Elapsed += Timer1OnElapsed;
		}

		private void Timer1OnElapsed(object sender, ElapsedEventArgs elapsedEventArgs)
		{
			try
			{
				engine.CheckServers();
			}
			finally
			{
				timer1.Interval = engine.Config.PollingInterval*1000;
				timer1.Start();
			}
		}

		protected override void OnStart(string[] args)
		{
			timer1.Start();
		}

		protected override void OnStop()
		{
			timer1.Stop();
		}

	}
}
