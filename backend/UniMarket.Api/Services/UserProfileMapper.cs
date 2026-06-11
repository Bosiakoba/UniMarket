using System.Text.Json;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public static class UserProfileMapper
{
    public static UserProfileDto ToDto(User user) =>
        new(
            user.Id,
            user.FirebaseUid,
            user.FullName,
            user.Email,
            user.Role,
            user.IsSeller,
            user.IsVerified,
            user.AvatarUrl,
            user.University,
            user.Campus,
            user.Phone,
            user.ProfileComplete,
            ParseCategories(user.InterestCategoriesJson),
            user.CreatedAt);

    public static IReadOnlyList<string> ParseCategories(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return Array.Empty<string>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<string>>(json) ?? [];
        }
        catch (JsonException)
        {
            return Array.Empty<string>();
        }
    }

    public static string SerializeCategories(IEnumerable<string> categories) =>
        JsonSerializer.Serialize(categories.Where(c => !string.IsNullOrWhiteSpace(c)).Distinct());
}
