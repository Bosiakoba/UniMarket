using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;
using UniMarket.Api.Data;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public class CampusEmailOtpService(
    AppDbContext db,
    ResendEmailService resend,
    IOptions<AdminSettings> adminSettings,
    ILogger<CampusEmailOtpService> logger)
{
    private static readonly TimeSpan OtpLifetime = TimeSpan.FromMinutes(10);
    private static readonly TimeSpan VerifiedLifetime = TimeSpan.FromHours(24);
    private const int MaxSendsPerWindow = 5;
    private static readonly TimeSpan SendWindow = TimeSpan.FromMinutes(15);

    public async Task SendOtpAsync(User user, string email, CancellationToken ct)
    {
        if (!resend.IsConfigured)
        {
            throw new InvalidOperationException(
                "Campus email verification is not configured. Set Resend__ApiKey on the server.");
        }

        var windowStart = DateTime.UtcNow.Subtract(SendWindow);
        var recentSends = await db.CampusEmailOtps.CountAsync(
            o => o.UserId == user.Id && o.CreatedAt >= windowStart,
            ct);
        if (recentSends >= MaxSendsPerWindow)
        {
            throw new InvalidOperationException("Too many codes requested. Wait a few minutes and try again.");
        }

        var code = Random.Shared.Next(0, 10_000).ToString("D4");
        var row = new CampusEmailOtp
        {
            Id = Guid.NewGuid().ToString("N"),
            UserId = user.Id,
            Email = email,
            CodeHash = HashCode(user.Id, email, code, adminSettings.Value.ApiKey),
            ExpiresAt = DateTime.UtcNow.Add(OtpLifetime),
            CreatedAt = DateTime.UtcNow,
        };

        db.CampusEmailOtps.Add(row);
        await db.SaveChangesAsync(ct);

        try
        {
            await resend.SendCampusOtpAsync(email, code, ct);
        }
        catch
        {
            db.CampusEmailOtps.Remove(row);
            await db.SaveChangesAsync(ct);
            throw;
        }

        logger.LogInformation("Campus OTP sent for user {UserId} to {Email}.", user.Id, email);
    }

    public async Task VerifyOtpAsync(User user, string email, string code, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(code) || code.Trim().Length != 4 || !code.Trim().All(char.IsDigit))
        {
            throw new InvalidOperationException("Enter the 4-digit code from your email.");
        }

        var normalizedCode = code.Trim();
        var row = await db.CampusEmailOtps
            .Where(o => o.UserId == user.Id && o.Email == email && o.VerifiedAt == null)
            .OrderByDescending(o => o.CreatedAt)
            .FirstOrDefaultAsync(ct);

        if (row is null)
        {
            throw new InvalidOperationException("Request a new verification code first.");
        }

        if (row.ExpiresAt < DateTime.UtcNow)
        {
            throw new InvalidOperationException("That code expired. Request a new one.");
        }

        var expected = HashCode(user.Id, email, normalizedCode, adminSettings.Value.ApiKey);
        if (!CryptographicOperations.FixedTimeEquals(
                Encoding.UTF8.GetBytes(expected),
                Encoding.UTF8.GetBytes(row.CodeHash)))
        {
            throw new InvalidOperationException("That code is incorrect. Try again.");
        }

        row.VerifiedAt = DateTime.UtcNow;
        user.VerifiedStudentEmail = email;
        user.VerifiedStudentEmailAt = row.VerifiedAt;
        await db.SaveChangesAsync(ct);
    }

    public bool IsEmailVerifiedForApplication(User user, string email)
    {
        if (!string.Equals(user.VerifiedStudentEmail, email, StringComparison.OrdinalIgnoreCase) ||
            user.VerifiedStudentEmailAt is null)
        {
            return false;
        }

        return user.VerifiedStudentEmailAt.Value >= DateTime.UtcNow.Subtract(VerifiedLifetime);
    }

    private static string HashCode(string userId, string email, string code, string secret)
    {
        var payload = $"{userId}:{email}:{code}:{secret}";
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(payload));
        return Convert.ToHexString(hash);
    }
}
