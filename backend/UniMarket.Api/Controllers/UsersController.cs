using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/users")]
public class UsersController(AppDbContext db, CurrentUserService currentUser) : ControllerBase
{
    [HttpGet("me")]
    public async Task<ActionResult<UserProfileDto>> GetMe(CancellationToken ct)
    {
        var (user, error) = await RequireUserAsync(ct);
        if (error is not null) return error;
        return Ok(UserProfileMapper.ToDto(user!));
    }

    [HttpPut("me")]
    public async Task<ActionResult<UserProfileDto>> UpdateMe(
        [FromBody] UpdateProfileRequest request,
        CancellationToken ct)
    {
        var (user, error) = await RequireUserAsync(ct);
        if (error is not null) return error;

        if (!string.IsNullOrWhiteSpace(request.FullName)) user!.FullName = request.FullName.Trim();
        if (!string.IsNullOrWhiteSpace(request.University)) user!.University = request.University.Trim();
        if (!string.IsNullOrWhiteSpace(request.Campus)) user!.Campus = request.Campus.Trim();
        if (request.Phone is not null) user!.Phone = request.Phone.Trim();
        if (request.AvatarUrl is not null) user!.AvatarUrl = request.AvatarUrl.Trim();
        if (request.MarkProfileComplete == true) user!.ProfileComplete = true;
        if (request.InterestCategories is not null)
        {
            user!.InterestCategoriesJson =
                UserProfileMapper.SerializeCategories(request.InterestCategories);
        }

        await db.SaveChangesAsync(ct);
        return Ok(UserProfileMapper.ToDto(user!));
    }

    [HttpPost("seller-application")]
    public async Task<IActionResult> SellerApplication(
        [FromBody] SellerApplicationRequest request,
        CancellationToken ct)
    {
        var (user, error) = await RequireUserAsync(ct);
        if (error is not null) return error;

        db.VerificationRequests.Add(new VerificationRequest
        {
            Id = Guid.NewGuid().ToString("N"),
            UserId = user!.Id,
            Status = "Pending",
            IdDocumentUrl = request.IdDocumentUrl,
        });

        await db.SaveChangesAsync(ct);
        return Ok(new { status = "Pending" });
    }

    [HttpPost("verify-badge")]
    public async Task<IActionResult> VerifyBadge(CancellationToken ct)
    {
        var (user, error) = await RequireUserAsync(ct);
        if (error is not null) return error;

        if (!user!.IsSeller)
        {
            return BadRequest(new { message = "Apply to sell first." });
        }

        var activeListings = await db.Listings.CountAsync(
            l => l.UserId == user.Id && l.Status == "active", ct);

        if (activeListings < 3)
        {
            return BadRequest(new { message = "Need at least 3 active listings." });
        }

        user.IsVerified = true;
        await db.SaveChangesAsync(ct);
        return Ok(new { isVerified = true });
    }

    private async Task<(User? User, ActionResult? Error)> RequireUserAsync(CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated)
        {
            return (null, Unauthorized());
        }

        var user = await db.Users.FindAsync([currentUser.UserId!], ct);
        return user is null ? (null, NotFound()) : (user, null);
    }
}
