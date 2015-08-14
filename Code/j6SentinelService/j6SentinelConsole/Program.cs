using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using j6SentinelEngine;
using System.Diagnostics;

namespace j6SentinelConsole
{
	class Program
	{
		static void Main(string[] args)
		{
			var traceListener = new ConsoleTraceListener();
			Trace.Listeners.Add(traceListener);
			Trace.AutoFlush = true;
			var engine = new SentinelEngine();
			engine.CheckServers();
		}
	}
}
