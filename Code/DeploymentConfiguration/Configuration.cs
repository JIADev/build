namespace DeploymentTool
{
	public class Configuration : Serializable<Configuration>
	{
		public Environment[] Environments { get; set; }
	}
}