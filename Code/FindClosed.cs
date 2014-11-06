using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;

namespace j6.BuildTools
{
	class Program
	{
		private static int Main(string[] args)
		{
		    if (args.Length < 3)
		    {
                Console.WriteLine("Need 3 arguments, got " + args.Length);
		        return -2;
		    }

		    var searchBranch = args[0];
		    var inputFile = args[1];
		    var outputFile = args[2];
            
            if(File.Exists(outputFile))
                File.Delete(outputFile);

            using (var reader = new StreamReader(File.Open(inputFile, FileMode.Open, FileAccess.Read, FileShare.Read)))
            {
                while (!reader.EndOfStream)
                {
                    var line = reader.ReadLine();
                    
                    if (line == null)
                        return 0;
                    
                    var parts = line.Split(new [] {" ", "\t", "\n", "\r"}, StringSplitOptions.RemoveEmptyEntries);
                    
                    if (parts.Length < 2)
                        return 0;

                    if (!parts[0].Trim().Equals(searchBranch, StringComparison.InvariantCulture)) continue;
                   
                    if (parts.Last().Equals("(closed)", StringComparison.InvariantCulture))
                        return 0;
                    
                    using (var writer =new StreamWriter(File.Open(outputFile, FileMode.Create, FileAccess.Write, FileShare.Read)))
                    {
                        writer.WriteLine(line);
                        writer.Flush();
                    }

                }
            }
            return 0;
		}
	}
}
