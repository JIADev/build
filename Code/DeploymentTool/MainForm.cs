using System.IO;
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

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
	}
}
