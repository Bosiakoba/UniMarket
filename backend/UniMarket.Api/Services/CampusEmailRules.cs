namespace UniMarket.Api.Services;

public static class CampusEmailRules
{
    private static readonly HashSet<string> PersonalDomains = new(StringComparer.OrdinalIgnoreCase)
    {
        "gmail.com",
        "googlemail.com",
        "yahoo.com",
        "hotmail.com",
        "outlook.com",
        "live.com",
        "icloud.com",
        "me.com",
        "proton.me",
        "protonmail.com",
        "aol.com",
    };

    private static readonly string[] CampusDomainMarkers =
    [
        ".edu",
        ".ac.uk",
        ".edu.gh",
        ".edu.ng",
        ".ac.za",
        ".edu.au",
    ];

    public static bool TryNormalize(string? email, out string normalized, out string? error)
    {
        normalized = string.Empty;
        error = null;

        if (string.IsNullOrWhiteSpace(email))
        {
            error = "Enter your student email.";
            return false;
        }

        normalized = email.Trim().ToLowerInvariant();
        var at = normalized.LastIndexOf('@');
        if (at <= 0 || at == normalized.Length - 1)
        {
            error = "Enter a valid student email.";
            return false;
        }

        var domain = normalized[(at + 1)..];
        if (PersonalDomains.Contains(domain))
        {
            error = "Use your official campus email, not a personal inbox.";
            return false;
        }

        if (!CampusDomainMarkers.Any(marker => domain.EndsWith(marker, StringComparison.OrdinalIgnoreCase)))
        {
            error = "Student email must use your school's campus domain (for example .edu).";
            return false;
        }

        return true;
    }

    public static bool DomainMatchesUniversity(string email, string? university)
    {
        if (string.IsNullOrWhiteSpace(university))
        {
            return false;
        }

        var at = email.LastIndexOf('@');
        if (at < 0)
        {
            return false;
        }

        var domain = email[(at + 1)..];
        var tokens = university
            .ToLowerInvariant()
            .Replace(".", " ")
            .Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(token => token.Length > 2)
            .Where(token => token is not ("the" or "and" or "of" or "for" or "university" or "college"))
            .ToList();

        return tokens.Any(token => domain.Contains(token, StringComparison.OrdinalIgnoreCase));
    }
}
