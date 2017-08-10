using Microsoft.Build.Framework;
using Microsoft.Build.Utilities;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace j6.BuildTools.MsBuildTasks
{
    public class FixLineEndings : Task
    {
        [Required]
        public string[] FileNames { get; set; }
        
        public override bool Execute()
        {
            foreach (var fileName in FileNames)
            {
		Console.Write("File {0}...", fileName);
		var file = new FileInfo(fileName);
                var inputBuffer = new byte[file.Length];
                var outputBuffer = new byte[file.Length];

                if (!file.Exists)
                    throw new ArgumentException(string.Format("File: {0} doesn't exist", fileName));

                int bytesRead;

                using (var input = file.OpenRead())
                    bytesRead = input.Read(inputBuffer, 0, inputBuffer.Length);

                var bytesWritten = 0;
                unsafe
                {
                    fixed (byte* inputCharArray = &inputBuffer[0])
                    fixed (byte* outputCharArray = &outputBuffer[0])
                    {
                        byte* inputByte = inputCharArray;
                        byte* outputByte = outputCharArray;
                        byte lastChar = (byte)'\0';
                        for (var index = 0; index < bytesRead; index++, inputByte++)
                        {
                            if (index == 0 && *inputByte == 255)
                                continue;

                            if (index == 1 && *inputByte == 254)
                                continue;

                            if (*inputByte == '\0')
                                continue;

                            if ('\n' == *inputByte)
                            {
                                if('\n' == lastChar)
                                    continue;

                                if ('\r' != lastChar)
                                {
                                    *outputByte = (byte)'\r';
                                    outputByte++;
                                    bytesWritten++;
                                }
                            }

                            lastChar = *outputByte = *inputByte;
                            outputByte++;
                            bytesWritten++;
                        }
                    }
                }

                using (var output = new FileStream(fileName, FileMode.Create, FileAccess.Write, FileShare.None))
                    output.Write(outputBuffer, 0, bytesWritten);
		Console.WriteLine("Done.");
            }
            return true;
        }
    }
}
