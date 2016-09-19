using System;
using System.Collections.Generic;
using System.Drawing.Design;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Windows.Forms.Design;

namespace DeploymentTool
{
	public class UIEditor<T> : UITypeEditor where T : class, ICloneable, new()
	{
		public override UITypeEditorEditStyle GetEditStyle(System.ComponentModel.ITypeDescriptorContext context)
		{
			return UITypeEditorEditStyle.Modal;
		}

		public override object EditValue(System.ComponentModel.ITypeDescriptorContext context, IServiceProvider provider, object value)
		{
			var svc = provider.GetService(typeof(IWindowsFormsEditorService)) as IWindowsFormsEditorService;
			var val = value == null ? new T() : (T)((T)value).Clone();
			
			if (svc == null)
				return null;

			using (var dialog = new EditDialog<T>(false, typeof(T).Name))
			{
				dialog.SelectedItem = val;
				if (svc.ShowDialog(dialog) == DialogResult.OK)
					return dialog.SelectedItem.Clone();

			}
			return value;
		}
	}
}
