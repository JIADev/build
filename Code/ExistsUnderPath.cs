using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace j6.BuildTools.MsBuildTasks
{
    internal class ExistsUnderPath : IEqualityComparer<string>
    {
        public bool Equals(string x, string y)
        {
            return x.Equals(y, StringComparison.InvariantCultureIgnoreCase);
        }

        public int GetHashCode(string obj)
        {
            return obj.GetHashCode();
        }
    }
}
