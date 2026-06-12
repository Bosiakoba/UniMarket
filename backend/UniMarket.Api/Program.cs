using Microsoft.Data.Sqlite;
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
builder.Services.Configure<ResendSettings>(
    builder.Configuration.GetSection(ResendSettings.SectionName));
builder.Services.Configure<ApiSettings>(
    builder.Configuration.GetSection(ApiSettings.SectionName));

var cloudflareSettings = builder.Configuration
    .GetSection(CloudflareSettings.SectionName)
    .Get<CloudflareSettings>() ?? new CloudflareSettings();
var useD1Primary = cloudflareSettings.IsD1Configured;

if (useD1Primary)
{
    builder.Services.AddHttpClient(nameof(D1Client));
    builder.Services.AddSingleton<D1Client>();
    builder.Services.AddSingleton<D1EntitySqlBuilder>();
    builder.Services.AddSingleton<D1SchemaInitializer>();
    builder.Services.AddSingleton<D1SchemaPatcher>();
    builder.Services.AddSingleton<D1SaveChangesInterceptor>();

    var sqliteConnection = new SqliteConnection("Data Source=:memory:;Cache=Shared");
    sqliteConnection.Open();
    builder.Services.AddSingleton(sqliteConnection);

    builder.Services.AddDbContext<AppDbContext>((sp, options) =>
    {
        options.UseSqlite(sp.GetRequiredService<SqliteConnection>());
        options.AddInterceptors(sp.GetRequiredService<D1SaveChangesInterceptor>());
    });
}
else
{
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
}

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new() { Title = "UniMarket API", Version = "v1" });
});

builder.Services.AddHttpContextAccessor();
builder.Services.AddHttpClient();
builder.Services.AddScoped<CurrentUserService>();
builder.Services.AddScoped<ListingMapper>();
builder.Services.AddScoped<FirebaseAuthService>();
builder.Services.AddScoped<UserProvisioningService>();
builder.Services.AddScoped<VerificationQueueService>();
builder.Services.AddScoped<R2StorageService>();
builder.Services.AddScoped<SaleConfirmationService>();
builder.Services.AddScoped<FirebaseNotificationService>();
builder.Services.AddScoped<NotificationService>();
builder.Services.AddHttpClient<CloudflareAiReviewService>(client =>
{
    client.Timeout = TimeSpan.FromMinutes(3);
});
builder.Services.AddHttpClient<ResendEmailService>();
builder.Services.AddScoped<CampusEmailOtpService>();
builder.Services.AddSingleton<AiReviewBackgroundDispatcher>();

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

var cloudflareAtRuntime = app.Services.GetRequiredService<IOptions<CloudflareSettings>>().Value;
if (cloudflareAtRuntime.AllowLocalUploadFallback && !cloudflareAtRuntime.IsR2Configured)
{
    var localUploadRoot = Path.Combine(app.Environment.ContentRootPath, "data", "uploads");
    Directory.CreateDirectory(localUploadRoot);
    app.UseStaticFiles(new StaticFileOptions
    {
        FileProvider = new PhysicalFileProvider(localUploadRoot),
        RequestPath = "/media",
    });
}

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.EnsureCreatedAsync();

    if (!useD1Primary)
    {
        await DatabaseSchemaPatcher.ApplyAsync(db);
    }

    if (useD1Primary)
    {
        var d1Initializer = scope.ServiceProvider.GetRequiredService<D1SchemaInitializer>();
        await d1Initializer.EnsureSchemaAsync();
        var d1Patcher = scope.ServiceProvider.GetRequiredService<D1SchemaPatcher>();
        await d1Patcher.ApplyAsync();
    }

    if (useD1Primary)
    {
        var d1 = scope.ServiceProvider.GetRequiredService<D1Client>();
        var sqlBuilder = scope.ServiceProvider.GetRequiredService<D1EntitySqlBuilder>();
        var hasRemoteData = await d1.TableHasRowsAsync("Users");
        if (hasRemoteData)
        {
            await sqlBuilder.HydrateAsync(db);
        }
        else
        {
            await SeedData.InitializeAsync(db);
        }
    }
    else
    {
        await SeedData.InitializeAsync(db);
    }
}

app.UseSwagger();
app.UseSwaggerUI();

app.UseCors();
app.UseMiddleware<AuthMiddleware>();
app.MapControllers();
app.MapGet("/health", (
    IOptions<FirebaseSettings> firebase,
    IOptions<CloudflareSettings> cloudflare,
    IOptions<AdminSettings> admin,
    IConfiguration configuration) =>
{
    var fb = firebase.Value;
    var cf = cloudflare.Value;
    var adminSettings = admin.Value;
    var d1Primary = cf.IsD1Configured;
    return Results.Ok(new
    {
        status = "ok",
        time = DateTime.UtcNow,
        database = new
        {
            provider = d1Primary ? "cloudflare-d1" : "sqlite-file",
            primary = d1Primary ? "d1" : "local-file",
            path = d1Primary ? cf.D1DatabaseId : configuration.GetConnectionString("Default"),
            statelessApi = d1Primary,
        },
        storage = new
        {
            uploads = cf.IsR2Configured ? "r2" : cf.AllowLocalUploadFallback ? "local-fallback" : "not-configured",
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
                d1 = new { enabled = cf.D1Enabled, configured = cf.IsD1Configured, primary = d1Primary },
                r2 = new
                {
                    enabled = cf.R2Enabled,
                    configured = cf.IsR2Configured,
                    localUploadFallback = cf.AllowLocalUploadFallback && !cf.IsR2Configured,
                    missing = cf.IsR2Configured ? Array.Empty<string>() : cf.GetR2MissingFields(),
                },
                aiReview = new
                {
                    configured = cf.IsAiReviewConfigured && adminSettings.IsConfigured,
                    url = string.IsNullOrWhiteSpace(cf.AiReviewUrl) ? null : cf.AiReviewUrl,
                },
            },
            admin = new
            {
                configured = adminSettings.IsConfigured,
            },
        },
    });
});

app.Run();
