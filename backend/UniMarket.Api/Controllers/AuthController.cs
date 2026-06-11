using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(
    AppDbContext db,
    FirebaseAuthService firebaseAuth,
    UserProvisioningService userProvisioning) : ControllerBase
{
    [HttpPost("session")]
    public async Task<ActionResult<UserProfileDto>> Session(
        [FromBody] SessionRequest request,
        CancellationToken ct)
    {
        User user;

        if (firebaseAuth.IsActive)
        {
            var idToken = request.FirebaseIdToken?.Trim();
            if (string.IsNullOrWhiteSpace(idToken))
            {
                return BadRequest(new { message = "FirebaseIdToken is required." });
            }

            try
            {
                var decoded = await firebaseAuth.VerifyIdTokenAsync(idToken, ct);
                user = await userProvisioning.UpsertFromFirebaseTokenAsync(decoded, ct);
            }
            catch (Exception)
            {
                return Unauthorized(new { message = "Invalid or expired Firebase token." });
            }
        }
        else
        {
            var devUserId = request.DevUserId?.Trim();
            if (string.IsNullOrWhiteSpace(devUserId))
            {
                return BadRequest(new
                {
                    message = "DevUserId required while Firebase auth is disabled.",
                });
            }

            user = await db.Users.FirstOrDefaultAsync(u => u.Id == devUserId, ct)
                ?? new User
                {
                    Id = devUserId,
                    Email = $"{devUserId}@university.edu",
                    FullName = "Campus User",
                };

            if (user.Id == devUserId && !await db.Users.AnyAsync(u => u.Id == devUserId, ct))
            {
                db.Users.Add(user);
                await db.SaveChangesAsync(ct);
            }
        }

        HttpContext.Items["UserId"] = user.Id;
        return Ok(ToProfile(user));
    }

    private static UserProfileDto ToProfile(User user) =>
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
            user.CreatedAt);
}
