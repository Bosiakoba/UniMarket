using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;
using UniMarket.Api.Data;
using UniMarket.Api.Middleware;
using UniMarket.Api.Services;

EnvFileLoader.LoadFromContentRoot(Directory.GetCurrentDirectory());

var builder = WebApplication.CreateBuilder(args);

builder.Services.Configure<FirebaseSettings>(
    builder.Configuration.GetSection(FirebaseSettings.SectionName));
builder.Services.Configure<CloudflareSettings>(
    builder.Configuration.GetSection(CloudflareSettings.SectionName));
builder.Services.Configure<AdminSettings>(
    builder.Configuration.GetSection(AdminSettings.SectionName));

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
builder.Services.AddScoped<FirebaseAuthService>();
builder.Services.AddScoped<UserProvisioningService>();
builder.Services.AddScoped<VerificationQueueService>();
builder.Services.AddScoped<R2StorageService>();
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
app.UseMiddleware<AuthMiddleware>();
app.MapControllers();
app.MapGet("/health", (
    IOptions<FirebaseSettings> firebase,
    IOptions<CloudflareSettings> cloudflare) =>
{
    var fb = firebase.Value;
    var cf = cloudflare.Value;
    return Results.Ok(new
    {
        status = "ok",
        time = DateTime.UtcNow,
        integrations = new
        {
            firebase = new
            {
                enabled = fb.Enabled,
                configured = fb.IsConfigured,
                projectId = string.IsNullOrWhiteSpace(fb.ProjectId) ? null : fb.ProjectId,
            },
            cloudflare = new
            {
                d1 = new { enabled = cf.D1Enabled, configured = cf.IsD1Configured },
                r2 = new { enabled = cf.R2Enabled, configured = cf.IsR2Configured },
            },
        },
    });
});

app.Run();
