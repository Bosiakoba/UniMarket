using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.Middleware;
using UniMarket.Api.Services;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new() { Title = "UniMarket API", Version = "v1" });
});

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseInMemoryDatabase("UniMarket"));

builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<CurrentUserService>();
builder.Services.AddScoped<ListingMapper>();
builder.Services.AddScoped<SaleConfirmationService>();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await SeedData.InitializeAsync(db);
}

app.UseSwagger();
app.UseSwaggerUI();

app.UseCors();
app.UseMiddleware<DevAuthMiddleware>();
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "ok", time = DateTime.UtcNow }));

app.Run();
