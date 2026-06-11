using UniMarket.Api.DTOs;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public static class UserProfileMapper
{
    public static UserProfileDto ToDto(
        User user,
        string sellerApplicationStatus,
        string verificationBadgeStatus) =>
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
            sellerApplicationStatus,
            verificationBadgeStatus,
            user.CreatedAt);

    public static IReadOnlyList<string> ParseCategories(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return Array.Empty<string>();
        }

        try
        {
            return System.Text.Json.JsonSerializer.Deserialize<List<string>>(json) ?? [];
        }
        catch (System.Text.Json.JsonException)
        {
            return Array.Empty<string>();
        }
    }

    public static string SerializeCategories(IEnumerable<string> categories) =>
        System.Text.Json.JsonSerializer.Serialize(
            categories.Where(c => !string.IsNullOrWhiteSpace(c)).Distinct());
}
