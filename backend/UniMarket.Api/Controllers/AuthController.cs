using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(AppDbContext db) : ControllerBase
{
    [HttpPost("session")]
    public async Task<ActionResult<UserProfileDto>> Session(
        [FromBody] SessionRequest request,
        CancellationToken ct)
    {
        // TODO: Verify FirebaseIdToken via Firebase Admin SDK when enabled.
        var devUserId = request.DevUserId?.Trim();
        if (string.IsNullOrWhiteSpace(devUserId))
        {
            return BadRequest(new { message = "DevUserId required until Firebase is configured." });
        }

        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == devUserId, ct);
        if (user is null)
        {
            user = new User
            {
                Id = devUserId,
                Email = $"{devUserId}@university.edu",
                FullName = "Campus User",
            };
            db.Users.Add(user);
            await db.SaveChangesAsync(ct);
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
