using System;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System.Threading;

// ReSharper disable RedundantStringFormatCall
namespace DeploymentMsBuildTasks
{
	public class Sleep : Task
	{
		[Required]
		public int Seconds { get; set; }

		public override bool Execute()
		{
			Console.WriteLine("Sleeping {0} seconds", Seconds);
			Thread.Sleep(Seconds*1000);
			return true;
		}
	}
}
