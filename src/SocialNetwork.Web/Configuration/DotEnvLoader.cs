namespace SocialNetwork.Web.Configuration;

internal static class DotEnvLoader
{
    public static void Load(string fileName = ".env")
    {
        var envFilePath = FindEnvFile(fileName);
        if (envFilePath is null)
        {
            return;
        }

        foreach (var rawLine in File.ReadLines(envFilePath))
        {
            var line = rawLine.Trim();
            if (string.IsNullOrWhiteSpace(line) || line.StartsWith('#'))
            {
                continue;
            }

            var separatorIndex = line.IndexOf('=');
            if (separatorIndex <= 0)
            {
                continue;
            }

            var key = line[..separatorIndex].Trim();
            if (string.IsNullOrWhiteSpace(key) || !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable(key)))
            {
                continue;
            }

            var value = line[(separatorIndex + 1)..].Trim();
            if ((value.StartsWith('"') && value.EndsWith('"')) || (value.StartsWith('\'') && value.EndsWith('\'')))
            {
                value = value[1..^1];
            }

            Environment.SetEnvironmentVariable(key, value);
        }
    }

    private static string? FindEnvFile(string fileName)
    {
        foreach (var root in GetCandidateRoots())
        {
            var directory = new DirectoryInfo(root);
            while (directory is not null)
            {
                var candidate = Path.Combine(directory.FullName, fileName);
                if (File.Exists(candidate))
                {
                    return candidate;
                }

                directory = directory.Parent;
            }
        }

        return null;
    }

    private static IEnumerable<string> GetCandidateRoots()
    {
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var currentDirectory = Directory.GetCurrentDirectory();
        var baseDirectory = AppContext.BaseDirectory;

        if (seen.Add(currentDirectory))
        {
            yield return currentDirectory;
        }

        if (seen.Add(baseDirectory))
        {
            yield return baseDirectory;
        }
    }
}
