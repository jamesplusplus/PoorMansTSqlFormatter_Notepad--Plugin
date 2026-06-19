using System;
using System.IO;
using System.Text;
using PoorMansTSqlFormatterLib;
using PoorMansTSqlFormatterLib.Formatters;

namespace PoorMansTSqlFormatterFmtCli
{
    /// <summary>
    /// stdin/stdout formatter for Notepad-- plugin (scheme A).
    /// Exit: 0 ok, 1 usage/runtime error, 2 parse warnings (unless --force).
    /// </summary>
    internal static class Program
    {
        private const int ExitOk = 0;
        private const int ExitError = 1;
        private const int ExitParseWarning = 2;

        private static int Main(string[] args)
        {
            string configPath = null;
            bool force = false;

            for (int i = 0; i < args.Length; i++)
            {
                switch (args[i])
                {
                    case "--config":
                        if (i + 1 >= args.Length)
                        {
                            WriteError("Missing path after --config");
                            return ExitError;
                        }
                        configPath = args[++i];
                        break;
                    case "--force":
                        force = true;
                        break;
                    case "--help":
                    case "-h":
                    case "/?":
                        WriteHelp();
                        return ExitOk;
                    default:
                        WriteError("Unknown argument: " + args[i]);
                        WriteHelp();
                        return ExitError;
                }
            }

            try
            {
                string input = ReadStdin();
                var options = LoadOptions(configPath);
                var formatter = new TSqlStandardFormatter(options);
                var manager = new SqlFormattingManager(formatter);

                bool errorsEncountered = false;
                string output = manager.Format(input, ref errorsEncountered);

                if (errorsEncountered && !force)
                {
                    Console.Error.WriteLine("Parse/format warnings were encountered. Use --force to emit output anyway.");
                    return ExitParseWarning;
                }

                Console.OutputEncoding = Encoding.UTF8;
                Console.Write(output);
                return ExitOk;
            }
            catch (Exception ex)
            {
                WriteError(ex.Message);
                return ExitError;
            }
        }

        private static string ReadStdin()
        {
            Console.InputEncoding = Encoding.UTF8;
            using (var reader = new StreamReader(Console.OpenStandardInput(), Encoding.UTF8))
            {
                return reader.ReadToEnd();
            }
        }

        private static TSqlStandardFormatterOptions LoadOptions(string configPath)
        {
            if (string.IsNullOrEmpty(configPath))
                return new TSqlStandardFormatterOptions();

            if (!File.Exists(configPath))
                throw new FileNotFoundException("Config file not found.", configPath);

            string serialized = null;
            foreach (string line in File.ReadAllLines(configPath, Encoding.UTF8))
            {
                string trimmed = line.Trim();
                if (trimmed.Length == 0 || trimmed.StartsWith("#") || trimmed.StartsWith(";"))
                    continue;

                if (trimmed.StartsWith("OptionsSerialized=", StringComparison.OrdinalIgnoreCase))
                {
                    serialized = trimmed.Substring("OptionsSerialized=".Length);
                    break;
                }

                if (!trimmed.Contains("="))
                {
                    serialized = trimmed;
                    break;
                }
            }

            if (string.IsNullOrEmpty(serialized))
                return new TSqlStandardFormatterOptions();

            return new TSqlStandardFormatterOptions(serialized);
        }

        private static void WriteError(string message)
        {
            Console.Error.WriteLine(message);
        }

        private static void WriteHelp()
        {
            Console.Error.WriteLine("PoorMansTSqlFormatterFmtCli — T-SQL formatter (stdin → stdout)");
            Console.Error.WriteLine();
            Console.Error.WriteLine("Usage:");
            Console.Error.WriteLine("  PoorMansTSqlFormatterFmtCli [--config <file>] [--force]");
            Console.Error.WriteLine();
            Console.Error.WriteLine("  --config   INI/text file with OptionsSerialized=... (optional)");
            Console.Error.WriteLine("  --force    Write formatted SQL even when parse warnings occur");
            Console.Error.WriteLine("  --help     Show this help");
            Console.Error.WriteLine();
            Console.Error.WriteLine("Exit codes: 0 success, 1 error, 2 parse warnings (no output unless --force)");
        }
    }
}
