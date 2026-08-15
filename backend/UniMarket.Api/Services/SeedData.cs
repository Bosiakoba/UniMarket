using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public static class SeedData
{
    public static async Task InitializeAsync(AppDbContext db)
    {
        // Seeding is disabled to keep the database free from mock users/data (Alex Morgan, Jordan K.)
        await Task.CompletedTask;
    }
}
