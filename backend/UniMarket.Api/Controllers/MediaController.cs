using Microsoft.AspNetCore.Mvc;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("media")]
public class MediaController(R2StorageService storage) : ControllerBase
{
    [HttpGet("{**path}")]
    [ResponseCache(Duration = 86400)]
    public async Task<IActionResult> Get(string path, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return NotFound();
        }

        var result = await storage.TryOpenMediaAsync(path, ct);
        if (result is null)
        {
            return NotFound();
        }

        return File(result.Value.Stream, result.Value.ContentType);
    }
}
