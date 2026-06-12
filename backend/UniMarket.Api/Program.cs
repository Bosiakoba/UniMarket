using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
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
builder.Services.Configure<ApiSettings>(
    builder.Configuration.GetSection(ApiSettings.SectionName));

var connectionString = builder.Configuration.GetConnectionString("Default")
    ?? "Data Source=data/unimarket.db";
var dbFilePath = connectionString.Replace("Data Source=", "", StringComparison.OrdinalIgnoreCase)
    .Trim();
if (!Path.IsPathRooted(dbFilePath))
{
    dbFilePath = Path.Combine(builder.Environment.ContentRootPath, dbFilePath);
}

var dbDirectory = Path.GetDirectoryName(dbFilePath);
if (!string.IsNullOrWhiteSpace(dbDirectory))
{
    Directory.CreateDirectory(dbDirectory);
}

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite($"Data Source={dbFilePath}"));

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new() { Title = "UniMarket API", Version = "v1" });
});

builder.Services.AddHttpContextAccessor();
builder.Services.AddHttpClient();
builder.Services.AddHttpClient(nameof(D1SchemaInitializer));
builder.Services.AddScoped<CurrentUserService>();
builder.Services.AddScoped<ListingMapper>();
builder.Services.AddScoped<FirebaseAuthService>();
builder.Services.AddScoped<UserProvisioningService>();
builder.Services.AddScoped<VerificationQueueService>();
builder.Services.AddScoped<R2StorageService>();
builder.Services.AddScoped<SaleConfirmationService>();
builder.Services.AddScoped<FirebaseNotificationService>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddHttpClient<CloudflareAiReviewService>();
builder.Services.AddSingleton<D1SchemaInitializer>();

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

var localUploadRoot = Path.Combine(app.Environment.ContentRootPath, "data", "uploads");
Directory.CreateDirectory(localUploadRoot);
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(localUploadRoot),
    RequestPath = "/media",
});

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.EnsureCreatedAsync();

    var d1Initializer = scope.ServiceProvider.GetRequiredService<D1SchemaInitializer>();
    await d1Initializer.EnsureSchemaAsync();

    await SeedData.InitializeAsync(db);
}

app.UseSwagger();
app.UseSwaggerUI();

app.UseCors();
app.UseMiddleware<AuthMiddleware>();
app.MapControllers();
app.MapGet("/health", (
    IOptions<FirebaseSettings> firebase,
    IOptions<CloudflareSettings> cloudflare,
    IConfiguration configuration) =>
{
    var fb = firebase.Value;
    var cf = cloudflare.Value;
    var dbPath = configuration.GetConnectionString("Default") ?? "Data Source=data/unimarket.db";
    return Results.Ok(new
    {
        status = "ok",
        time = DateTime.UtcNow,
        database = new
        {
            provider = "sqlite",
            path = dbPath,
            persistent = true,
        },
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
                r2 = new
                {
                    enabled = cf.R2Enabled,
                    configured = cf.IsR2Configured,
                    localUploadFallback = cf.AllowLocalUploadFallback && !cf.IsR2Configured,
                },
            },
        },
    });
});

app.Run();
