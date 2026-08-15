using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

public class ResendEmailService(
    HttpClient http,
    IOptions<ResendSettings> settings,
    ILogger<ResendEmailService> logger)
{
    private readonly ResendSettings _settings = settings.Value;

    public bool IsConfigured => _settings.IsConfigured;

    private async Task SendEmailInternalAsync(string toEmail, string subject, string html, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(toEmail) || toEmail.EndsWith("@university.edu", StringComparison.OrdinalIgnoreCase))
        {
            logger.LogInformation("Skipping email delivery to placeholder/anonymous address: {Email}", toEmail);
            return;
        }

        if (!IsConfigured)
        {
            logger.LogWarning("Resend email service is not configured. Skipping email to {Email}", toEmail);
            return;
        }

        var payload = new ResendEmailPayload(
            _settings.FromAddress,
            [toEmail],
            subject,
            html);

        using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.resend.com/emails")
        {
            Content = JsonContent.Create(payload),
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _settings.ApiKey);

        var response = await http.SendAsync(request, ct);
        if (response.IsSuccessStatusCode)
        {
            return;
        }

        var body = await response.Content.ReadAsStringAsync(ct);
        logger.LogWarning("Resend email failed ({StatusCode}) to {Email}: {Body}", response.StatusCode, toEmail, body);
        throw new InvalidOperationException("Could not send the email. Try again shortly.");
    }

    public async Task SendCampusOtpAsync(string toEmail, string code, CancellationToken ct)
    {
        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <h2 style="color:#1f6b4a;font-weight:600;margin-bottom:24px;">Confirm Your Email</h2>
          <p>Enter this code in UniMarket to confirm your campus email:</p>
          <p style="font-size:28px;font-weight:700;letter-spacing:6px;margin:24px 0;color:#1f6b4a;">{code}</p>
          <p style="color:#667;font-size:13px;">This code expires in 10 minutes. If you did not request it, you can ignore this email.</p>
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, $"{code} is your UniMarket campus email code", html, ct);
    }

    public async Task SendOnboardingSuccessEmailAsync(string toEmail, string fullName, CancellationToken ct)
    {
        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <h2 style="color:#1f6b4a;font-weight:600;margin-bottom:24px;">Welcome to UniMarket!</h2>
          <p>Hi {fullName},</p>
          <p>Your profile is now complete. You've successfully onboarded to UniMarket, your campus-exclusive marketplace.</p>
          <p>Here are a few things you can do next:</p>
          <ul style="padding-left:20px;margin-bottom:24px;">
            <li>Browse listings from verified students on your campus.</li>
            <li>Add items to your wishlist to get notified of price drops.</li>
            <li>Apply to become a seller to list your own items or services.</li>
          </ul>
          <p>If you have any questions or feedback, simply reply to this email.</p>
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, $"Welcome to UniMarket, {fullName}!", html, ct);
    }

    public async Task SendSellerApprovalEmailAsync(string toEmail, string fullName, CancellationToken ct)
    {
        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <h2 style="color:#1f6b4a;font-weight:600;margin-bottom:24px;">Seller Application Approved</h2>
          <p>Hi {fullName},</p>
          <p>Great news! Your application to become a seller on UniMarket has been approved.</p>
          <p>You can now start listing your products, textbooks, or services for other students on campus to buy.</p>
          <div style="margin:32px 0;">
            <a href="https://unimarket-alpha-vert.vercel.app/#/sell" style="background-color:#1f6b4a;color:#fff;text-decoration:none;padding:12px 24px;border-radius:6px;font-weight:600;display:inline-block;">Start Listing Items</a>
          </div>
          <p>Make sure to keep your listings accurate and arrange safe meetups on campus.</p>
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, "Your seller application has been approved!", html, ct);
    }

    public async Task SendSellerRejectionEmailAsync(string toEmail, string fullName, string? adminNotes, CancellationToken ct)
    {
        var reasonText = string.IsNullOrWhiteSpace(adminNotes)
            ? "Review the requirements and submit again when ready."
            : adminNotes.Trim();

        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <h2 style="color:#b42318;font-weight:600;margin-bottom:24px;">Seller Application Status Update</h2>
          <p>Hi {fullName},</p>
          <p>Thank you for applying to sell on UniMarket. We reviewed your application and unfortunately, we cannot approve it at this time.</p>
          <p><strong>Reason for decision:</strong></p>
          <blockquote style="border-left:4px solid #b42318;padding-left:16px;margin:20px 0;color:#555;font-style:italic;">
            {reasonText}
          </blockquote>
          <p>You can make the necessary changes and submit a new application through the app at any time.</p>
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, "Update regarding your seller application", html, ct);
    }

    public async Task SendUnreadMessageAlertEmailAsync(string toEmail, string fullName, string senderName, string content, string chatId, CancellationToken ct)
    {
        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <h2 style="color:#1f6b4a;font-weight:600;margin-bottom:24px;">New Message</h2>
          <p>Hi {fullName},</p>
          <p>You have a new unread message from <strong>{senderName}</strong>:</p>
          <blockquote style="border-left:4px solid #1f6b4a;padding-left:16px;margin:20px 0;color:#333;font-style:italic;">
            {content}
          </blockquote>
          <div style="margin:32px 0;">
            <a href="https://unimarket-alpha-vert.vercel.app/#/messages" style="background-color:#1f6b4a;color:#fff;text-decoration:none;padding:12px 24px;border-radius:6px;font-weight:600;display:inline-block;">Reply to Message</a>
          </div>
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, $"New message from {senderName} on UniMarket", html, ct);
    }

    public async Task SendCampaignEmailAsync(string toEmail, string fullName, string subject, string htmlBody, CancellationToken ct)
    {
        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <p>Hi {fullName},</p>
          {htmlBody}
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, subject, html, ct);
    }

    public async Task SendListingSuspendedEmailAsync(string toEmail, string fullName, string listingTitle, string? reason, CancellationToken ct)
    {
        var reasonText = string.IsNullOrWhiteSpace(reason)
            ? "Your listing violated our community guidelines."
            : reason.Trim();

        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <h2 style="color:#b42318;font-weight:600;margin-bottom:24px;">Listing Suspended</h2>
          <p>Hi {fullName},</p>
          <p>Your listing "<strong>{listingTitle}</strong>" has been suspended by our administration team.</p>
          <p><strong>Reason for suspension:</strong></p>
          <blockquote style="border-left:4px solid #b42318;padding-left:16px;margin:20px 0;color:#555;font-style:italic;">
            {reasonText}
          </blockquote>
          <p>If you believe this was in error, please reply to this email to contact support.</p>
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, $"Your listing '{listingTitle}' has been suspended", html, ct);
    }

    public async Task SendAccountSuspendedEmailAsync(string toEmail, string fullName, string? reason, CancellationToken ct)
    {
        var reasonText = string.IsNullOrWhiteSpace(reason)
            ? "Multiple reports or violations of our campus community guidelines."
            : reason.Trim();

        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <h2 style="color:#b42318;font-weight:600;margin-bottom:24px;">Account Suspended</h2>
          <p>Hi {fullName},</p>
          <p>Your UniMarket account has been suspended by our moderation team.</p>
          <p><strong>Reason for suspension:</strong></p>
          <blockquote style="border-left:4px solid #b42318;padding-left:16px;margin:20px 0;color:#555;font-style:italic;">
            {reasonText}
          </blockquote>
          <p>While suspended, you will not be able to log in or list items. If you believe this was in error, you may email support at <strong>support@youngfuturetechnology.xyz</strong> to appeal.</p>
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, "Your UniMarket account has been suspended", html, ct);
    }

    public async Task SendListingUnsuspendedEmailAsync(string toEmail, string fullName, string listingTitle, CancellationToken ct)
    {
        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <h2 style="color:#1f6b4a;font-weight:600;margin-bottom:24px;">Listing Reinstated</h2>
          <p>Hi {fullName},</p>
          <p>Good news! Your listing "<strong>{listingTitle}</strong>" has been unsuspended and is now active and visible to buyers on campus again.</p>
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, $"Your listing '{listingTitle}' has been reinstated", html, ct);
    }

    public async Task SendAccountUnsuspendedEmailAsync(string toEmail, string fullName, CancellationToken ct)
    {
        var html = $"""
        <div style="font-family:'Segoe UI',system-ui,sans-serif;line-height:1.6;color:#111;max-width:600px;margin:0 auto;padding:20px;">
          <h2 style="color:#1f6b4a;font-weight:600;margin-bottom:24px;">Account Reinstated</h2>
          <p>Hi {fullName},</p>
          <p>Good news! Your UniMarket account has been unsuspended. You can now log back in and continue browsing or selling on campus.</p>
          <hr style="border:none;border-top:1px solid #eee;margin:32px 0;" />
          <p style="font-size:12px;color:#666;">&copy; {DateTime.UtcNow.Year} UniMarket. Campus-exclusive marketplace.</p>
        </div>
        """;

        await SendEmailInternalAsync(toEmail, "Your UniMarket account has been reinstated", html, ct);
    }

    private sealed record ResendEmailPayload(
        [property: JsonPropertyName("from")] string From,
        [property: JsonPropertyName("to")] IReadOnlyList<string> To,
        [property: JsonPropertyName("subject")] string Subject,
        [property: JsonPropertyName("html")] string Html);
}
