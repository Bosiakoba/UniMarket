using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Models;

namespace UniMarket.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<User> Users => Set<User>();
    public DbSet<Listing> Listings => Set<Listing>();
    public DbSet<ListingImage> ListingImages => Set<ListingImage>();
    public DbSet<Chat> Chats => Set<Chat>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<VerificationRequest> VerificationRequests => Set<VerificationRequest>();
    public DbSet<ListingReview> ListingReviews => Set<ListingReview>();
    public DbSet<ListingReport> ListingReports => Set<ListingReport>();
    public DbSet<WishlistItem> WishlistItems => Set<WishlistItem>();
    public DbSet<SaleRecord> SaleRecords => Set<SaleRecord>();
    public DbSet<SaleConfirmation> SaleConfirmations => Set<SaleConfirmation>();
    public DbSet<DeviceRegistration> DeviceRegistrations => Set<DeviceRegistration>();
    public DbSet<UserNotification> UserNotifications => Set<UserNotification>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>().HasIndex(u => u.Email).IsUnique();
        modelBuilder.Entity<User>().HasIndex(u => u.FirebaseUid);
        modelBuilder.Entity<VerificationRequest>().HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId);
        modelBuilder.Entity<WishlistItem>().HasKey(w => new { w.UserId, w.ListingId });
        modelBuilder.Entity<DeviceRegistration>().HasIndex(d => d.Token).IsUnique();
        modelBuilder.Entity<UserNotification>().HasIndex(n => new { n.UserId, n.CreatedAt });
    }
}
