using Microsoft.AspNetCore.Mvc;
using UniMarket.Api.DTOs;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/notifications")]
public class NotificationsController(
    CurrentUserService currentUser,
    NotificationService notifications) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<NotificationDto>>> List(CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();
        return Ok(await notifications.ListAsync(currentUser.UserId!, ct));
    }

    [HttpPost("fcm-token")]
    public async Task<IActionResult> RegisterFcmToken(
        [FromBody] RegisterFcmTokenRequest request,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();
        if (string.IsNullOrWhiteSpace(request.Token))
        {
            return BadRequest(new { message = "FCM token is required." });
        }

        await notifications.RegisterDeviceAsync(
            currentUser.UserId!,
            request.Token,
            request.Platform,
            ct);

        return NoContent();
    }

    [HttpPost("{id}/read")]
    public async Task<IActionResult> MarkRead(string id, CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();
        await notifications.MarkReadAsync(currentUser.UserId!, id, ct);
        return NoContent();
    }

    [HttpPost("read-all")]
    public async Task<IActionResult> MarkAllRead(CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();
        await notifications.MarkAllReadAsync(currentUser.UserId!, ct);
        return NoContent();
    }
}
