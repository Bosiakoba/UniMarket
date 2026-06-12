using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/users")]
public class UsersController(
    AppDbContext db,
    CurrentUserService currentUser,
    VerificationQueueService verificationQueue,
    AiReviewBackgroundDispatcher aiReviewDispatcher) : ControllerBase
{
    [HttpGet("me")]
    public async Task<ActionResult<UserProfileDto>> GetMe(CancellationToken ct)
    {
        var (user, error) = await RequireUserAsync(ct);
        if (error is not null) return error;
        return Ok(await ToProfileAsync(user!, ct));
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
        return Ok(await ToProfileAsync(user!, ct));
    }

    [HttpPost("seller-application")]
    public async Task<IActionResult> SellerApplication(
        [FromBody] SellerApplicationRequest request,
        CancellationToken ct)
    {
        var (user, error) = await RequireUserAsync(ct);
        if (error is not null) return error;

        if (user!.IsSeller)
        {
            return BadRequest(new { message = "You are already an approved seller." });
        }

        var pending = await verificationQueue.GetLatestAsync(
            user.Id,
            VerificationQueueService.TypeSellerApplication,
            ct);

        if (pending?.Status == "Pending")
        {
            return BadRequest(new { message = "Your seller application is already under review." });
        }

        var storeName = request.StoreName?.Trim();
        if (string.IsNullOrWhiteSpace(storeName))
        {
            return BadRequest(new { message = "Store name is required." });
        }

        if (string.IsNullOrWhiteSpace(request.IdDocumentUrl))
        {
            return BadRequest(new { message = "Upload your student ID before applying." });
        }

        var verificationRequest = new VerificationRequest
        {
            Id = Guid.NewGuid().ToString("N"),
            UserId = user.Id,
            RequestType = VerificationQueueService.TypeSellerApplication,
            Status = "Pending",
            StoreName = storeName,
            IdDocumentUrl = request.IdDocumentUrl?.Trim(),
        };

        db.VerificationRequests.Add(verificationRequest);

        await db.SaveChangesAsync(ct);
        aiReviewDispatcher.Enqueue(verificationRequest.Id);
        return Ok(new { status = "Pending", requestType = VerificationQueueService.TypeSellerApplication });
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

        if (user.IsVerified)
        {
            return BadRequest(new { message = "You already have the verified badge." });
        }

        var pending = await verificationQueue.GetLatestAsync(
            user.Id,
            VerificationQueueService.TypeVerifiedBadge,
            ct);

        if (pending?.Status == "Pending")
        {
            return BadRequest(new { message = "Your verification badge request is already under review." });
        }

        var activeListings = await db.Listings.CountAsync(
            l => l.UserId == user.Id && l.Status == "active", ct);

        if (activeListings < 3)
        {
            return BadRequest(new { message = "Need at least 3 active listings." });
        }

        var verificationRequest = new VerificationRequest
        {
            Id = Guid.NewGuid().ToString("N"),
            UserId = user.Id,
            RequestType = VerificationQueueService.TypeVerifiedBadge,
            Status = "Pending",
        };

        db.VerificationRequests.Add(verificationRequest);

        await db.SaveChangesAsync(ct);
        aiReviewDispatcher.Enqueue(verificationRequest.Id);
        return Ok(new { status = "Pending", requestType = VerificationQueueService.TypeVerifiedBadge });
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

    private async Task<UserProfileDto> ToProfileAsync(User user, CancellationToken ct)
    {
        var statuses = await verificationQueue.ResolveUserStatusesAsync(user, ct);
        return UserProfileMapper.ToDto(
            user,
            statuses.SellerApplication,
            statuses.VerificationBadge,
            statuses.StoreName);
    }
}
