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
    AiReviewBackgroundDispatcher aiReviewDispatcher,
    CampusEmailOtpService campusEmailOtp,
    ResendEmailService emailService) : ControllerBase
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

        var wasComplete = user!.ProfileComplete;

        if (!string.IsNullOrWhiteSpace(request.FullName)) user.FullName = request.FullName.Trim();
        if (!string.IsNullOrWhiteSpace(request.University)) user.University = request.University.Trim();
        if (!string.IsNullOrWhiteSpace(request.Campus)) user.Campus = request.Campus.Trim();
        if (request.Phone is not null) user.Phone = request.Phone.Trim();
        if (request.AvatarUrl is not null) user.AvatarUrl = request.AvatarUrl.Trim();
        if (request.MarkProfileComplete == true) user.ProfileComplete = true;
        if (request.InterestCategories is not null)
        {
            user.InterestCategoriesJson =
                UserProfileMapper.SerializeCategories(request.InterestCategories);
        }
        if (request.StoreName is not null) user.StoreName = request.StoreName.Trim();
        if (request.StoreDescription is not null) user.StoreDescription = request.StoreDescription.Trim();
        if (request.HasPhysicalStore.HasValue) user.HasPhysicalStore = request.HasPhysicalStore.Value;
        if (request.StoreAddress is not null) user.StoreAddress = request.StoreAddress.Trim();

        await db.SaveChangesAsync(ct);

        if (!wasComplete && user.ProfileComplete)
        {
            try
            {
                await emailService.SendOnboardingSuccessEmailAsync(user.Email, user.FullName, ct);
            }
            catch
            {
                // Non-blocking email trigger
            }
        }

        return Ok(await ToProfileAsync(user, ct));
    }

    [HttpPost("seller-email/send-otp")]
    public async Task<IActionResult> SendSellerEmailOtp(
        [FromBody] CampusEmailOtpRequest request,
        CancellationToken ct)
    {
        var (user, error) = await RequireUserAsync(ct);
        if (error is not null) return error;

        if (!CampusEmailRules.TryNormalize(request.Email, out var email, out var emailError))
        {
            return BadRequest(new { message = emailError });
        }

        try
        {
            await campusEmailOtp.SendOtpAsync(user!, email, ct);
            return Ok(new CampusEmailOtpResponse(
                "Verification code sent. Check your student inbox.",
                false));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("seller-email/verify-otp")]
    public async Task<IActionResult> VerifySellerEmailOtp(
        [FromBody] CampusEmailVerifyRequest request,
        CancellationToken ct)
    {
        var (user, error) = await RequireUserAsync(ct);
        if (error is not null) return error;

        if (!CampusEmailRules.TryNormalize(request.Email, out var email, out var emailError))
        {
            return BadRequest(new { message = emailError });
        }

        try
        {
            await campusEmailOtp.VerifyOtpAsync(user!, email, request.Code, ct);
            return Ok(new CampusEmailOtpResponse("Student email confirmed.", true));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
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

        if (!CampusEmailRules.TryNormalize(
                request.StudentEmail,
                out var studentEmail,
                out var studentEmailError))
        {
            return BadRequest(new { message = studentEmailError });
        }

        if (!campusEmailOtp.IsEmailVerifiedForApplication(user, studentEmail))
        {
            return BadRequest(new { message = "Confirm your student email before submitting." });
        }

        var verificationRequest = new VerificationRequest
        {
            Id = Guid.NewGuid().ToString("N"),
            UserId = user.Id,
            RequestType = VerificationQueueService.TypeSellerApplication,
            Status = "Pending",
            StoreName = storeName,
            StudentEmail = studentEmail,
            IdDocumentUrl = request.IdDocumentUrl?.Trim(),
        };

        db.VerificationRequests.Add(verificationRequest);

        await db.SaveChangesAsync(ct);
        aiReviewDispatcher.Enqueue(verificationRequest.Id);

        return Ok(new
        {
            status = "pending",
            requestType = VerificationQueueService.TypeSellerApplication,
            requestId = verificationRequest.Id,
            aiReviewQueued = true,
        });
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

        var followersCount = await db.UserFollows.CountAsync(f => f.FolloweeId == user.Id, ct);
        if (followersCount < 500)
        {
            return BadRequest(new { message = "Need at least 500 followers." });
        }

        var sellerApp = await verificationQueue.GetLatestAsync(
            user.Id,
            VerificationQueueService.TypeSellerApplication,
            ct);

        var daysAsSeller = sellerApp?.ProcessedAt != null
            ? (DateTime.UtcNow - sellerApp.ProcessedAt.Value).TotalDays
            : (DateTime.UtcNow - user.CreatedAt).TotalDays;

        if (daysAsSeller < 90)
        {
            return BadRequest(new { message = "Need to be a seller for at least 90 days." });
        }

        var listingsWithReviews = await db.Listings
            .Include(l => l.Images) // just in case
            .Where(l => l.UserId == user.Id)
            .ToListAsync(ct);

        // Fetch sales with confirmations to compute rating, but since we don't have direct access
        // to a 'rating' field on user, let's look for how rating is computed.
        // Wait, ListingReview table is used. Let's query ListingReview.
        var reviews = await db.ListingReviews
            .Where(r => listingsWithReviews.Select(l => l.Id).Contains(r.ListingId))
            .ToListAsync(ct);

        int ratingCount = reviews.Count;
        double averageRating = ratingCount > 0 ? reviews.Average(r => r.Score) : 0;

        if (ratingCount < 15)
        {
            return BadRequest(new { message = "Need at least 15 ratings." });
        }

        if (averageRating < 4.5)
        {
            return BadRequest(new { message = "Need an average rating of at least 4.5." });
        }

        var statsJson = System.Text.Json.JsonSerializer.Serialize(new
        {
            followers = followersCount,
            activeListings = activeListings,
            daysAsSeller = (int)daysAsSeller,
            rating = averageRating,
            ratingCount = ratingCount
        });

        var verificationRequest = new VerificationRequest
        {
            Id = Guid.NewGuid().ToString("N"),
            UserId = user.Id,
            RequestType = VerificationQueueService.TypeVerifiedBadge,
            Status = "Pending",
            AdminNotes = statsJson
        };

        db.VerificationRequests.Add(verificationRequest);

        await db.SaveChangesAsync(ct);
        aiReviewDispatcher.Enqueue(verificationRequest.Id);

        return Ok(new
        {
            status = "pending",
            requestType = VerificationQueueService.TypeVerifiedBadge,
            requestId = verificationRequest.Id,
            aiReviewQueued = true,
        });
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
        
        var followersCount = await db.UserFollows.CountAsync(f => f.FolloweeId == user.Id, ct);
        var followingCount = await db.UserFollows.CountAsync(f => f.FollowerId == user.Id, ct);
        var isFollowing = false;
        
        if (currentUser.IsAuthenticated && currentUser.UserId != user.Id)
        {
            isFollowing = await db.UserFollows.AnyAsync(f => f.FollowerId == currentUser.UserId && f.FolloweeId == user.Id, ct);
        }

        return UserProfileMapper.ToDto(
            user,
            statuses.SellerApplication,
            statuses.VerificationBadge,
            statuses.StoreName,
            followersCount,
            followingCount,
            isFollowing);
    }

    [HttpPost("{id}/follow")]
    public async Task<IActionResult> Follow(string id, CancellationToken ct)
    {
        var (currentUserEntity, error) = await RequireUserAsync(ct);
        if (error is not null) return error;

        if (currentUserEntity!.Id == id) return BadRequest(new { message = "Cannot follow yourself." });

        var targetUser = await db.Users.FindAsync([id], ct);
        if (targetUser is null) return NotFound();

        var exists = await db.UserFollows.AnyAsync(f => f.FollowerId == currentUserEntity.Id && f.FolloweeId == id, ct);
        if (!exists)
        {
            db.UserFollows.Add(new UserFollow
            {
                FollowerId = currentUserEntity.Id,
                FolloweeId = id
            });
            await db.SaveChangesAsync(ct);
        }

        return Ok();
    }

    [HttpDelete("{id}/follow")]
    public async Task<IActionResult> Unfollow(string id, CancellationToken ct)
    {
        var (currentUserEntity, error) = await RequireUserAsync(ct);
        if (error is not null) return error;

        var follow = await db.UserFollows.FirstOrDefaultAsync(f => f.FollowerId == currentUserEntity!.Id && f.FolloweeId == id, ct);
        if (follow is not null)
        {
            db.UserFollows.Remove(follow);
            await db.SaveChangesAsync(ct);
        }

        return Ok();
    }

    [HttpGet("{id}/followers")]
    public async Task<ActionResult<IEnumerable<UserProfileDto>>> GetFollowers(string id, CancellationToken ct)
    {
        var followerIds = await db.UserFollows.Where(f => f.FolloweeId == id).Select(f => f.FollowerId).ToListAsync(ct);
        var users = await db.Users.Where(u => followerIds.Contains(u.Id)).ToListAsync(ct);
        
        var dtos = new List<UserProfileDto>();
        foreach (var user in users)
        {
            dtos.Add(await ToProfileAsync(user, ct));
        }
        return Ok(dtos);
    }

    [HttpGet("{id}/following")]
    public async Task<ActionResult<IEnumerable<UserProfileDto>>> GetFollowing(string id, CancellationToken ct)
    {
        var followingIds = await db.UserFollows.Where(f => f.FollowerId == id).Select(f => f.FolloweeId).ToListAsync(ct);
        var users = await db.Users.Where(u => followingIds.Contains(u.Id)).ToListAsync(ct);

        var dtos = new List<UserProfileDto>();
        foreach (var user in users)
        {
            dtos.Add(await ToProfileAsync(user, ct));
        }
        return Ok(dtos);
    }
}
