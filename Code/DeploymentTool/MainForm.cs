using System.IO;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using DeploymentMsBuildTasks;
using j6.BuildTools.MsBuildTasks;

namespace DeploymentTool
{
	public partial class MainForm : Form
	{
		private readonly Configuration _configuration;
		private readonly string _configurationFileName;

		public MainForm()
		{
			InitializeComponent();
			var profilePath = System.Environment.GetFolderPath(System.Environment.SpecialFolder.UserProfile);
			_configurationFileName = Path.Combine(profilePath, "deploymentToolConfig.xml");
			_configuration = Configuration.LoadOrCreate(_configurationFileName);
		}

		private void MainForm_Load(object sender, EventArgs e)
		{
			Rebind();
		}

		private void exitToolStripMenuItem_Click(object sender, EventArgs e)
		{
			Close();
		}

		private void btnBrowseSqlSettings_Click(object sender, EventArgs e)
		{
			if (ofdReleasePackage.ShowDialog() != DialogResult.OK)
				return;

			txtReleasePackage.Text = ofdReleasePackage.FileName;
		}

		private void environmentsToolStripMenuItem_Click(object sender, EventArgs e)
		{
			var optionsDialog = new EditDialog<Environment>(true, "Environment")
				{
					ItemList = _configuration.Environments
				};

			if (optionsDialog.ShowDialog() != DialogResult.OK)
				return;

			_configuration.Environments = optionsDialog.ItemList;
			_configuration.Save(_configurationFileName);
			Rebind();
		}

		private void Rebind()
		{
			var selected = cboTargetEnvironment.SelectedItem;
			cboTargetEnvironment.DataSource = null;
			cboTargetEnvironment.Refresh();
			cboTargetEnvironment.DataSource = _configuration.Environments;
			if (selected != null && _configuration.Environments.Any(e => e == selected))
				cboTargetEnvironment.SelectedItem = selected;
		}

		private void btnRunCheckedItems_Click(object sender, EventArgs e)
		{
			rtbPatchLog.Clear();
			rtbErrors.Clear();
			var selectedItem = (Environment)cboTargetEnvironment.SelectedItem;
			Task.Run(() =>
				{
					var msbuild = new MsBuild();
					try
					{
						msbuild.Run(ProcessTextReceived, "Main", selectedItem);
					}
					catch (Exception ex)
					{
						var message = string.Format("Error when running MyTarget: {0}{1}", ex, System.Environment.NewLine);
						rtbErrors.AppendText(message);
						MessageBox.Show(message, "Error Occurred", MessageBoxButtons.OK, MessageBoxIcon.Error);
					}
				});
		}

		private void ProcessTextReceived(object sender, ProcessTextReceivedEventArgs args)
		{
			if (rtbPatchLog.InvokeRequired)
			{
				var d = new BuildSystem.ProcessTextReceivedDelegate(ProcessTextReceived);
				BeginInvoke(d, new[] {sender, args});
			}
			else
			{
				var text = string.Format("{0}{1}{2}", args.IsError ? "Error: " : string.Empty, args.Text, System.Environment.NewLine);
				rtbPatchLog.AppendText(text);
				rtbPatchLog.SelectionStart = rtbPatchLog.TextLength;
				rtbPatchLog.ScrollToCaret();
				if (args.IsError)
				{
					rtbErrors.AppendText(string.Format("{0}{1}", args.Text, System.Environment.NewLine));
					rtbErrors.SelectionStart = rtbErrors.TextLength;
					rtbErrors.ScrollToCaret();
				}

			}
		}
	}
}
