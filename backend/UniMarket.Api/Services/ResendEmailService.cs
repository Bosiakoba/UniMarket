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

    public async Task SendCampusOtpAsync(string toEmail, string code, CancellationToken ct)
    {
        if (!IsConfigured)
        {
            throw new InvalidOperationException("Campus email verification is not configured on the server.");
        }

        var payload = new ResendEmailPayload(
            _settings.FromAddress,
            [toEmail],
            $"{code} is your UniMarket campus email code",
            $"""
            <div style="font-family:Segoe UI,system-ui,sans-serif;line-height:1.5;color:#122">
              <p>Enter this code in UniMarket to confirm your campus email:</p>
              <p style="font-size:28px;font-weight:700;letter-spacing:6px">{code}</p>
              <p style="color:#667">This code expires in 10 minutes. If you did not request it, you can ignore this email.</p>
            </div>
            """);

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
        logger.LogWarning("Resend OTP email failed ({StatusCode}): {Body}", response.StatusCode, body);
        throw new InvalidOperationException("Could not send the verification email. Try again shortly.");
    }

    private sealed record ResendEmailPayload(
        [property: JsonPropertyName("from")] string From,
        [property: JsonPropertyName("to")] IReadOnlyList<string> To,
        [property: JsonPropertyName("subject")] string Subject,
        [property: JsonPropertyName("html")] string Html);
}
