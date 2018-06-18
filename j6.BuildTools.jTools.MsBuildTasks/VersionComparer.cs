using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace j6.BuildTools.MsBuildTasks
{
    public class VersionComparer : IComparer<string>
    {
        public int Compare(string x, string y)
        {
            var versionX = x.Split(new[] {'.'}).Select(int.Parse).ToArray();
            var versionY = y.Split(new[] {'.'}).Select(int.Parse).ToArray();
            var returnValue = 0;
            for (var i = 0; i < versionX.Length && i < versionY.Length; i++)
            {
                var result = versionX[i] - versionY[i];
                returnValue *= 1000;
                returnValue += result;
            }
            return returnValue;
        }
    }
}
