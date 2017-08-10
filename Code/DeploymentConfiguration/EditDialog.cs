using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Instrumentation;
using System.Windows.Forms;

namespace DeploymentTool
{
	public partial class EditDialog<T> : Form where T : class, new()
	{
		private readonly List<T> _itemList = new List<T>();

		public T[] ItemList
		{
			get { return _itemList.ToArray(); }
			set
			{
				_itemList.Clear();
				if(value != null)
					_itemList.AddRange(value);
			}
		}

		public T SelectedItem
		{
			get { return propertyGrid1.SelectedObject as T; }
			set
			{
				propertyGrid1.SelectedObject = value;
				cboEnvironment.SelectedItem = value;
			}
		}

		public string ItemTypeName { get { return lblEnvironment.Text; } set { Text = string.Format("{0} Options", lblEnvironment.Text = value);  } }
		public EditDialog()
			: this(false, string.Empty)
		{
		}

		public EditDialog(bool isArray, string itemTypeName)
		{
			InitializeComponent();
			lblEnvironment.Visible = btnAdd.Visible = btnRemove.Visible = cboEnvironment.Visible = isArray;
			ItemTypeName = itemTypeName;
		}

		private void EditDialog_Load(object sender, EventArgs e)
		{
			Rebind();
		}

		private void Rebind()
		{
			cboEnvironment.DataSource = null;
			cboEnvironment.Refresh();
			cboEnvironment.DataSource = _itemList;
			if (SelectedItem == null && ItemList.Any())
				SelectedItem = ItemList.First();
		}

		private void btnRemove_Click(object sender, EventArgs e)
		{
			_itemList.Remove(SelectedItem);
			SelectedItem = null;
			Rebind();
		}

		private void btnAdd_Click(object sender, EventArgs e)
		{
			var newItem = new T();
			_itemList.Add(newItem);
			Rebind();
			SelectedItem = newItem;
		}

		private void propertyGrid1_PropertyValueChanged(object s, PropertyValueChangedEventArgs e)
		{
			Rebind();
		}

		private void cboEnvironment_SelectedIndexChanged(object sender, EventArgs e)
		{
			SelectedItem = cboEnvironment.SelectedItem as T;
		}
	}
}
