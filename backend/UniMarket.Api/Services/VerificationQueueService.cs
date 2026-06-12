using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public class VerificationQueueService(AppDbContext db, NotificationService notifications)
{
    public const string TypeSellerApplication = "seller_application";
    public const string TypeVerifiedBadge = "verified_badge";

    public static readonly HashSet<string> AllowedTypes =
    [
        TypeSellerApplication,
        TypeVerifiedBadge,
    ];

    public async Task<VerificationRequest?> GetLatestAsync(
        string userId,
        string requestType,
        CancellationToken ct) =>
        await db.VerificationRequests
            .Where(r => r.UserId == userId && r.RequestType == requestType)
            .OrderByDescending(r => r.SubmittedAt)
            .FirstOrDefaultAsync(ct);

    public async Task<(string SellerApplication, string VerificationBadge, string? StoreName)>
        ResolveUserStatusesAsync(User user, CancellationToken ct)
    {
        var sellerRequest = await GetLatestAsync(user.Id, TypeSellerApplication, ct);
        var badgeRequest = await GetLatestAsync(user.Id, TypeVerifiedBadge, ct);

        return (
            ResolveSellerApplicationStatus(user, sellerRequest),
            ResolveBadgeStatus(user, badgeRequest),
            sellerRequest?.StoreName);
    }

    public static string ResolveSellerApplicationStatus(User user, VerificationRequest? request) =>
        request?.Status switch
        {
            "Pending" => "pending",
            "Rejected" => "rejected",
            "Approved" => "approved",
            _ => user.IsSeller ? "approved" : "none",
        };

    public static string ResolveBadgeStatus(User user, VerificationRequest? request) =>
        request?.Status switch
        {
            "Pending" => "pending",
            "Rejected" => "rejected",
            "Approved" => "approved",
            _ => user.IsVerified ? "approved" : "none",
        };

    public async Task<List<VerificationRequestDto>> ListQueueAsync(
        string? status,
        string? requestType,
        CancellationToken ct)
    {
        var query = db.VerificationRequests
            .Include(r => r.User)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(r => r.Status == status);
        }

        if (!string.IsNullOrWhiteSpace(requestType))
        {
            query = query.Where(r => r.RequestType == requestType);
        }

        var rows = await query
            .OrderByDescending(r => r.SubmittedAt)
            .Take(100)
            .ToListAsync(ct);

        return rows.Select(ToDto).ToList();
    }

    public async Task<VerificationRequestDto?> GetAsync(string id, CancellationToken ct)
    {
        var row = await db.VerificationRequests
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == id, ct);

        return row is null ? null : ToDto(row);
    }

    public async Task<VerificationRequestDto> ApproveAsync(string id, CancellationToken ct)
    {
        var row = await db.VerificationRequests
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == id, ct)
            ?? throw new InvalidOperationException("Request not found.");

        if (row.Status != "Pending")
        {
            throw new InvalidOperationException("Only pending requests can be approved.");
        }

        var user = row.User ?? await db.Users.FindAsync([row.UserId], ct)
            ?? throw new InvalidOperationException("User not found.");

        switch (row.RequestType)
        {
            case TypeSellerApplication:
                user.IsSeller = true;
                break;
            case TypeVerifiedBadge:
                if (!user.IsSeller)
                {
                    throw new InvalidOperationException("User must be an approved seller first.");
                }
                user.IsVerified = true;
                break;
            default:
                throw new InvalidOperationException("Unsupported request type.");
        }

        row.Status = "Approved";
        row.ProcessedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        if (row.RequestType == TypeSellerApplication)
        {
            await notifications.CreateAsync(
                user.Id,
                "Seller application approved",
                "You can now post listings on UniMarket.",
                "sellerApplication",
                row.Id,
                "Start selling",
                ct);
        }
        else if (row.RequestType == TypeVerifiedBadge)
        {
            await notifications.CreateAsync(
                user.Id,
                "Verified badge approved",
                "Your seller profile now shows the verified badge.",
                "verification",
                "verified",
                "View badge",
                ct);
        }

        return ToDto(row);
    }

    public async Task<VerificationRequestDto> RejectAsync(
        string id,
        string? notes,
        CancellationToken ct)
    {
        var row = await db.VerificationRequests
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == id, ct)
            ?? throw new InvalidOperationException("Request not found.");

        if (row.Status != "Pending")
        {
            throw new InvalidOperationException("Only pending requests can be rejected.");
        }

        row.Status = "Rejected";
        row.AdminNotes = string.IsNullOrWhiteSpace(notes) ? row.AdminNotes : notes.Trim();
        row.ProcessedAt = DateTime.UtcNow;
        var user = row.User ?? await db.Users.FindAsync([row.UserId], ct);
        await db.SaveChangesAsync(ct);

        if (user is not null)
        {
            await notifications.CreateAsync(
                user.Id,
                row.RequestType == TypeSellerApplication
                    ? "Seller application needs changes"
                    : "Verification request needs changes",
                row.AdminNotes ?? "Review the requirements and submit again when ready.",
                row.RequestType == TypeSellerApplication ? "sellerApplication" : "verification",
                row.Id,
                "Review",
                ct);
        }

        return ToDto(row);
    }

    public async Task<VerificationRequestDto> SaveAiReviewAsync(
        string id,
        string summary,
        string? recommendation,
        CancellationToken ct)
    {
        var row = await db.VerificationRequests
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Id == id, ct)
            ?? throw new InvalidOperationException("Request not found.");

        row.AiReviewSummary = summary.Trim();
        row.AiRecommendation = string.IsNullOrWhiteSpace(recommendation)
            ? null
            : recommendation.Trim();
        await db.SaveChangesAsync(ct);
        return ToDto(row);
    }

    private static VerificationRequestDto ToDto(VerificationRequest row)
    {
        var user = row.User;
        return new VerificationRequestDto(
            row.Id,
            row.UserId,
            row.RequestType,
            row.Status,
            row.StoreName,
            row.StudentEmail,
            row.IdDocumentUrl,
            row.AiReviewSummary,
            row.AiRecommendation,
            row.AdminNotes,
            row.SubmittedAt,
            row.ProcessedAt,
            user?.FullName,
            user?.Email,
            user?.University,
            user?.Campus,
            user?.IsSeller ?? false,
            user?.IsVerified ?? false);
    }
}
