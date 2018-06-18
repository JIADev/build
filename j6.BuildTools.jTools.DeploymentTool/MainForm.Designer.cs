namespace DeploymentTool
{
	partial class MainForm
	{
		/// <summary>
		/// Required designer variable.
		/// </summary>
		private System.ComponentModel.IContainer components = null;

		/// <summary>
		/// Clean up any resources being used.
		/// </summary>
		/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
		protected override void Dispose(bool disposing)
		{
			if (disposing && (components != null))
			{
				components.Dispose();
			}
			base.Dispose(disposing);
		}

		#region Windows Form Designer generated code

		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{
			this.mainMenuStrip = new System.Windows.Forms.MenuStrip();
			this.fileToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
			this.exitToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
			this.optionsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
			this.environmentsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
			this.btnBrowseSqlSettings = new System.Windows.Forms.Button();
			this.txtReleasePackage = new System.Windows.Forms.TextBox();
			this.lblReleasePackage = new System.Windows.Forms.Label();
			this.ofdReleasePackage = new System.Windows.Forms.OpenFileDialog();
			this.lblTargetEnvironment = new System.Windows.Forms.Label();
			this.cboTargetEnvironment = new System.Windows.Forms.ComboBox();
			this.sltPreviewPanels = new System.Windows.Forms.SplitContainer();
			this.btnRunCheckedItems = new System.Windows.Forms.Button();
			this.lvPatchList = new System.Windows.Forms.ListView();
			this.colName = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
			this.colDescription = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
			this.tabsResults = new System.Windows.Forms.TabControl();
			this.tabPatchResults = new System.Windows.Forms.TabPage();
			this.tabPatchRun = new System.Windows.Forms.TabControl();
			this.tabLog = new System.Windows.Forms.TabPage();
			this.rtbPatchLog = new System.Windows.Forms.RichTextBox();
			this.tabErrors = new System.Windows.Forms.TabPage();
			this.rtbErrors = new System.Windows.Forms.RichTextBox();
			this.mainMenuStrip.SuspendLayout();
			((System.ComponentModel.ISupportInitialize)(this.sltPreviewPanels)).BeginInit();
			this.sltPreviewPanels.Panel1.SuspendLayout();
			this.sltPreviewPanels.Panel2.SuspendLayout();
			this.sltPreviewPanels.SuspendLayout();
			this.tabsResults.SuspendLayout();
			this.tabPatchResults.SuspendLayout();
			this.tabPatchRun.SuspendLayout();
			this.tabLog.SuspendLayout();
			this.tabErrors.SuspendLayout();
			this.SuspendLayout();
			// 
			// mainMenuStrip
			// 
			this.mainMenuStrip.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.fileToolStripMenuItem,
            this.optionsToolStripMenuItem});
			this.mainMenuStrip.Location = new System.Drawing.Point(0, 0);
			this.mainMenuStrip.Name = "mainMenuStrip";
			this.mainMenuStrip.Size = new System.Drawing.Size(721, 24);
			this.mainMenuStrip.TabIndex = 0;
			this.mainMenuStrip.Text = "menuStrip1";
			// 
			// fileToolStripMenuItem
			// 
			this.fileToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.exitToolStripMenuItem});
			this.fileToolStripMenuItem.Name = "fileToolStripMenuItem";
			this.fileToolStripMenuItem.Size = new System.Drawing.Size(37, 20);
			this.fileToolStripMenuItem.Text = "&File";
			// 
			// exitToolStripMenuItem
			// 
			this.exitToolStripMenuItem.Name = "exitToolStripMenuItem";
			this.exitToolStripMenuItem.Size = new System.Drawing.Size(92, 22);
			this.exitToolStripMenuItem.Text = "E&xit";
			this.exitToolStripMenuItem.Click += new System.EventHandler(this.exitToolStripMenuItem_Click);
			// 
			// optionsToolStripMenuItem
			// 
			this.optionsToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.environmentsToolStripMenuItem});
			this.optionsToolStripMenuItem.Name = "optionsToolStripMenuItem";
			this.optionsToolStripMenuItem.Size = new System.Drawing.Size(61, 20);
			this.optionsToolStripMenuItem.Text = "&Options";
			// 
			// environmentsToolStripMenuItem
			// 
			this.environmentsToolStripMenuItem.Name = "environmentsToolStripMenuItem";
			this.environmentsToolStripMenuItem.Size = new System.Drawing.Size(156, 22);
			this.environmentsToolStripMenuItem.Text = "&Environments...";
			this.environmentsToolStripMenuItem.Click += new System.EventHandler(this.environmentsToolStripMenuItem_Click);
			// 
			// btnBrowseSqlSettings
			// 
			this.btnBrowseSqlSettings.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
			this.btnBrowseSqlSettings.Location = new System.Drawing.Point(634, 32);
			this.btnBrowseSqlSettings.Name = "btnBrowseSqlSettings";
			this.btnBrowseSqlSettings.Size = new System.Drawing.Size(75, 23);
			this.btnBrowseSqlSettings.TabIndex = 5;
			this.btnBrowseSqlSettings.Text = "Browse...";
			this.btnBrowseSqlSettings.UseVisualStyleBackColor = true;
			this.btnBrowseSqlSettings.Click += new System.EventHandler(this.btnBrowseSqlSettings_Click);
			// 
			// txtReleasePackage
			// 
			this.txtReleasePackage.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
			this.txtReleasePackage.Location = new System.Drawing.Point(115, 34);
			this.txtReleasePackage.Name = "txtReleasePackage";
			this.txtReleasePackage.ReadOnly = true;
			this.txtReleasePackage.Size = new System.Drawing.Size(513, 20);
			this.txtReleasePackage.TabIndex = 4;
			this.txtReleasePackage.TextChanged += new System.EventHandler(this.txtReleasePackage_TextChanged);
			// 
			// lblReleasePackage
			// 
			this.lblReleasePackage.AutoSize = true;
			this.lblReleasePackage.Location = new System.Drawing.Point(12, 37);
			this.lblReleasePackage.Name = "lblReleasePackage";
			this.lblReleasePackage.Size = new System.Drawing.Size(92, 13);
			this.lblReleasePackage.TabIndex = 3;
			this.lblReleasePackage.Text = "Release Package";
			// 
			// ofdReleasePackage
			// 
			this.ofdReleasePackage.Filter = "Release Packages (*.zip)|*.zip";
			// 
			// lblTargetEnvironment
			// 
			this.lblTargetEnvironment.AutoSize = true;
			this.lblTargetEnvironment.Location = new System.Drawing.Point(12, 63);
			this.lblTargetEnvironment.Name = "lblTargetEnvironment";
			this.lblTargetEnvironment.Size = new System.Drawing.Size(100, 13);
			this.lblTargetEnvironment.TabIndex = 6;
			this.lblTargetEnvironment.Text = "Target Environment";
			// 
			// cboTargetEnvironment
			// 
			this.cboTargetEnvironment.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
			this.cboTargetEnvironment.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
			this.cboTargetEnvironment.FormattingEnabled = true;
			this.cboTargetEnvironment.Location = new System.Drawing.Point(118, 60);
			this.cboTargetEnvironment.Name = "cboTargetEnvironment";
			this.cboTargetEnvironment.Size = new System.Drawing.Size(591, 21);
			this.cboTargetEnvironment.TabIndex = 7;
			// 
			// sltPreviewPanels
			// 
			this.sltPreviewPanels.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
			this.sltPreviewPanels.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
			this.sltPreviewPanels.Location = new System.Drawing.Point(15, 87);
			this.sltPreviewPanels.Name = "sltPreviewPanels";
			this.sltPreviewPanels.Orientation = System.Windows.Forms.Orientation.Horizontal;
			// 
			// sltPreviewPanels.Panel1
			// 
			this.sltPreviewPanels.Panel1.Controls.Add(this.btnRunCheckedItems);
			this.sltPreviewPanels.Panel1.Controls.Add(this.lvPatchList);
			// 
			// sltPreviewPanels.Panel2
			// 
			this.sltPreviewPanels.Panel2.Controls.Add(this.tabsResults);
			this.sltPreviewPanels.Size = new System.Drawing.Size(694, 489);
			this.sltPreviewPanels.SplitterDistance = 249;
			this.sltPreviewPanels.TabIndex = 8;
			// 
			// btnRunCheckedItems
			// 
			this.btnRunCheckedItems.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
			this.btnRunCheckedItems.Location = new System.Drawing.Point(593, 209);
			this.btnRunCheckedItems.Name = "btnRunCheckedItems";
			this.btnRunCheckedItems.Size = new System.Drawing.Size(95, 23);
			this.btnRunCheckedItems.TabIndex = 1;
			this.btnRunCheckedItems.Text = "Run Checked";
			this.btnRunCheckedItems.UseVisualStyleBackColor = true;
			this.btnRunCheckedItems.Click += new System.EventHandler(this.btnRunCheckedItems_Click);
			// 
			// lvPatchList
			// 
			this.lvPatchList.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
			this.lvPatchList.CheckBoxes = true;
			this.lvPatchList.Columns.AddRange(new System.Windows.Forms.ColumnHeader[] {
            this.colName,
            this.colDescription});
			this.lvPatchList.FullRowSelect = true;
			this.lvPatchList.Location = new System.Drawing.Point(0, 3);
			this.lvPatchList.MultiSelect = false;
			this.lvPatchList.Name = "lvPatchList";
			this.lvPatchList.Size = new System.Drawing.Size(690, 200);
			this.lvPatchList.TabIndex = 0;
			this.lvPatchList.UseCompatibleStateImageBehavior = false;
			this.lvPatchList.View = System.Windows.Forms.View.Details;
			// 
			// colName
			// 
			this.colName.Text = "Name";
			this.colName.Width = 200;
			// 
			// colDescription
			// 
			this.colDescription.Text = "Description";
			this.colDescription.Width = 482;
			// 
			// tabsResults
			// 
			this.tabsResults.Controls.Add(this.tabPatchResults);
			this.tabsResults.Dock = System.Windows.Forms.DockStyle.Fill;
			this.tabsResults.Location = new System.Drawing.Point(0, 0);
			this.tabsResults.Name = "tabsResults";
			this.tabsResults.SelectedIndex = 0;
			this.tabsResults.Size = new System.Drawing.Size(692, 234);
			this.tabsResults.TabIndex = 0;
			// 
			// tabPatchResults
			// 
			this.tabPatchResults.Controls.Add(this.tabPatchRun);
			this.tabPatchResults.Location = new System.Drawing.Point(4, 22);
			this.tabPatchResults.Name = "tabPatchResults";
			this.tabPatchResults.Padding = new System.Windows.Forms.Padding(3);
			this.tabPatchResults.Size = new System.Drawing.Size(684, 208);
			this.tabPatchResults.TabIndex = 1;
			this.tabPatchResults.Text = "Results";
			this.tabPatchResults.UseVisualStyleBackColor = true;
			// 
			// tabPatchRun
			// 
			this.tabPatchRun.Controls.Add(this.tabLog);
			this.tabPatchRun.Controls.Add(this.tabErrors);
			this.tabPatchRun.Dock = System.Windows.Forms.DockStyle.Fill;
			this.tabPatchRun.Location = new System.Drawing.Point(3, 3);
			this.tabPatchRun.Name = "tabPatchRun";
			this.tabPatchRun.SelectedIndex = 0;
			this.tabPatchRun.Size = new System.Drawing.Size(678, 202);
			this.tabPatchRun.TabIndex = 0;
			// 
			// tabLog
			// 
			this.tabLog.Controls.Add(this.rtbPatchLog);
			this.tabLog.Location = new System.Drawing.Point(4, 22);
			this.tabLog.Name = "tabLog";
			this.tabLog.Size = new System.Drawing.Size(670, 176);
			this.tabLog.TabIndex = 2;
			this.tabLog.Text = "Log";
			this.tabLog.UseVisualStyleBackColor = true;
			// 
			// rtbPatchLog
			// 
			this.rtbPatchLog.Dock = System.Windows.Forms.DockStyle.Fill;
			this.rtbPatchLog.Location = new System.Drawing.Point(0, 0);
			this.rtbPatchLog.Name = "rtbPatchLog";
			this.rtbPatchLog.ReadOnly = true;
			this.rtbPatchLog.Size = new System.Drawing.Size(670, 176);
			this.rtbPatchLog.TabIndex = 1;
			this.rtbPatchLog.Text = "";
			// 
			// tabErrors
			// 
			this.tabErrors.Controls.Add(this.rtbErrors);
			this.tabErrors.Location = new System.Drawing.Point(4, 22);
			this.tabErrors.Name = "tabErrors";
			this.tabErrors.Padding = new System.Windows.Forms.Padding(3);
			this.tabErrors.Size = new System.Drawing.Size(670, 176);
			this.tabErrors.TabIndex = 1;
			this.tabErrors.Text = "Errors";
			this.tabErrors.UseVisualStyleBackColor = true;
			// 
			// rtbErrors
			// 
			this.rtbErrors.Dock = System.Windows.Forms.DockStyle.Fill;
			this.rtbErrors.Location = new System.Drawing.Point(3, 3);
			this.rtbErrors.Name = "rtbErrors";
			this.rtbErrors.ReadOnly = true;
			this.rtbErrors.Size = new System.Drawing.Size(664, 170);
			this.rtbErrors.TabIndex = 1;
			this.rtbErrors.Text = "";
			// 
			// MainForm
			// 
			this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
			this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
			this.ClientSize = new System.Drawing.Size(721, 588);
			this.Controls.Add(this.sltPreviewPanels);
			this.Controls.Add(this.cboTargetEnvironment);
			this.Controls.Add(this.lblTargetEnvironment);
			this.Controls.Add(this.btnBrowseSqlSettings);
			this.Controls.Add(this.txtReleasePackage);
			this.Controls.Add(this.lblReleasePackage);
			this.Controls.Add(this.mainMenuStrip);
			this.MainMenuStrip = this.mainMenuStrip;
			this.Name = "MainForm";
			this.Text = "j6 Deployment Tool";
			this.Load += new System.EventHandler(this.MainForm_Load);
			this.mainMenuStrip.ResumeLayout(false);
			this.mainMenuStrip.PerformLayout();
			this.sltPreviewPanels.Panel1.ResumeLayout(false);
			this.sltPreviewPanels.Panel2.ResumeLayout(false);
			((System.ComponentModel.ISupportInitialize)(this.sltPreviewPanels)).EndInit();
			this.sltPreviewPanels.ResumeLayout(false);
			this.tabsResults.ResumeLayout(false);
			this.tabPatchResults.ResumeLayout(false);
			this.tabPatchRun.ResumeLayout(false);
			this.tabLog.ResumeLayout(false);
			this.tabErrors.ResumeLayout(false);
			this.ResumeLayout(false);
			this.PerformLayout();

		}

		#endregion

		private System.Windows.Forms.MenuStrip mainMenuStrip;
		private System.Windows.Forms.ToolStripMenuItem fileToolStripMenuItem;
		private System.Windows.Forms.ToolStripMenuItem exitToolStripMenuItem;
		private System.Windows.Forms.Button btnBrowseSqlSettings;
		private System.Windows.Forms.TextBox txtReleasePackage;
		private System.Windows.Forms.Label lblReleasePackage;
		private System.Windows.Forms.OpenFileDialog ofdReleasePackage;
		private System.Windows.Forms.Label lblTargetEnvironment;
		private System.Windows.Forms.ComboBox cboTargetEnvironment;
		private System.Windows.Forms.SplitContainer sltPreviewPanels;
		private System.Windows.Forms.ListView lvPatchList;
		private System.Windows.Forms.ColumnHeader colName;
		private System.Windows.Forms.ColumnHeader colDescription;
		private System.Windows.Forms.TabControl tabsResults;
		private System.Windows.Forms.TabPage tabPatchResults;
		private System.Windows.Forms.TabControl tabPatchRun;
		private System.Windows.Forms.TabPage tabLog;
		private System.Windows.Forms.RichTextBox rtbPatchLog;
		private System.Windows.Forms.TabPage tabErrors;
		private System.Windows.Forms.RichTextBox rtbErrors;
		private System.Windows.Forms.ToolStripMenuItem optionsToolStripMenuItem;
		private System.Windows.Forms.ToolStripMenuItem environmentsToolStripMenuItem;
		private System.Windows.Forms.Button btnRunCheckedItems;
	}
}

