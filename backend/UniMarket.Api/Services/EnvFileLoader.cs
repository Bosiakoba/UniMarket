namespace UniMarket.Api.Services;

/// <summary>
/// Loads KEY=VALUE pairs from a local .env file into process environment variables.
/// ASP.NET Core maps Cloudflare__AccountId → Cloudflare:AccountId automatically.
/// </summary>
public static class EnvFileLoader
{
    public static void Load(string path)
    {
        if (!File.Exists(path)) return;

        foreach (var rawLine in File.ReadAllLines(path))
        {
            var line = rawLine.Trim();
            if (line.Length == 0 || line.StartsWith('#')) continue;

            var separator = line.IndexOf('=');
            if (separator <= 0) continue;

            var key = line[..separator].Trim();
            var value = line[(separator + 1)..].Trim().Trim('"');
            if (key.Length == 0) continue;

            Environment.SetEnvironmentVariable(key, value);
        }
    }

    public static void LoadFromContentRoot(string contentRootPath)
    {
        Load(Path.Combine(contentRootPath, ".env"));
    }
}
