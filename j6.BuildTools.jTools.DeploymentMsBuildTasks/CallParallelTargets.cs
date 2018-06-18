using System.Linq;
using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using Microsoft.Build.Tasks;

namespace DeploymentMsBuildTasks
{
	public class CallParallelTargets : Task
	{
		[Required]
		public string[] Targets { get; set; }

		public override bool Execute()
		{
			var allSucceeded = true;
			Targets.AsParallel().Where(target => !string.IsNullOrWhiteSpace(target)).ForAll(target =>
				{
					var callTarget = new CallTarget
						{
							Targets = new [] { target },
							BuildEngine =  BuildEngine,
							HostObject =  HostObject,
							RunEachTargetSeparately = true,
							UseResultsCache =  false
						};
					var success = callTarget.Execute();
					allSucceeded = allSucceeded && success;
				});
			return allSucceeded;
		}
	}
}
