using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using Microsoft.Build.Utilities;

namespace DeploymentMsBuildTasks
{
	public class ConfirmNextStep : Task
	{
		public string Text { get; set; }
		
		public override bool Execute()
		{
			var message = string.IsNullOrWhiteSpace(Text)
				              ? "Proceed with next step?"
				              : string.Format("Proceed with next step: {0}?", Text);
			var dialogResult = MessageBox.Show(message, "Confirmation Required", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
			if (dialogResult != DialogResult.Yes)
			{
				Console.ForegroundColor = ConsoleColor.Red;
				Console.Error.WriteLine("User cancelled deployment");
				Console.ResetColor();
				return false;
			}
			return true;
		}
	}
}
