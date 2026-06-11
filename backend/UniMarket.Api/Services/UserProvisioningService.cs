using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;
using UniMarket.Api.Data;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public class UserProvisioningService(AppDbContext db)
{
    public async Task<User> UpsertFromFirebaseTokenAsync(
        FirebaseAdmin.Auth.FirebaseToken token,
        CancellationToken ct)
    {
        var uid = token.Uid;
        var email = token.Claims.TryGetValue("email", out var emailClaim)
            ? emailClaim?.ToString()?.Trim().ToLowerInvariant()
            : null;
        var name = token.Claims.TryGetValue("name", out var nameClaim)
            ? nameClaim?.ToString()?.Trim()
            : null;

        var user = await db.Users.FirstOrDefaultAsync(u => u.FirebaseUid == uid, ct);

        if (user is null && !string.IsNullOrWhiteSpace(email))
        {
            user = await db.Users
                .FirstOrDefaultAsync(u => u.Email.ToLower() == email, ct);
        }

        if (user is not null)
        {
            var changed = false;
            if (user.FirebaseUid != uid)
            {
                user.FirebaseUid = uid;
                changed = true;
            }

            if (!string.IsNullOrWhiteSpace(name) &&
                (string.IsNullOrWhiteSpace(user.FullName) || user.FullName == "Campus User"))
            {
                user.FullName = name;
                changed = true;
            }

            if (changed)
            {
                await db.SaveChangesAsync(ct);
            }

            return user;
        }

        user = new User
        {
            Id = Guid.NewGuid().ToString("N")[..12],
            FirebaseUid = uid,
            Email = email ?? $"{uid}@university.edu",
            FullName = string.IsNullOrWhiteSpace(name) ? "Campus User" : name,
        };

        db.Users.Add(user);
        await db.SaveChangesAsync(ct);
        return user;
    }
}
