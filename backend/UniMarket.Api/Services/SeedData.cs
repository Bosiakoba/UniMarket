using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public static class SeedData
{
    public static async Task InitializeAsync(AppDbContext db)
    {
        if (await db.Users.AnyAsync()) return;

        var demoUser = new User
        {
            Id = "alex-demo",
            Email = "alex.morgan@university.edu",
            FullName = "Alex Morgan",
            IsSeller = true,
            IsVerified = false,
            University = "State University",
            Campus = "Main Campus",
            Phone = "+233 50 000 1122",
            ProfileComplete = true,
            InterestCategoriesJson =
                "[\"Electronics & Gadgets\",\"Books & Stationery\"]",
            CreatedAt = DateTime.UtcNow.AddDays(-21),
        };

        var sellers = new[]
        {
            new User
            {
                Id = "seller-jordan",
                Email = "jordan@university.edu",
                FullName = "Jordan K.",
                IsSeller = true,
                IsVerified = true,
                ProfileComplete = true,
                InterestCategoriesJson =
                    "[\"Fashion & Accessories\",\"Electronics & Gadgets\"]",
            },
            new User
            {
                Id = "seller-kwesi",
                Email = "kwesi@university.edu",
                FullName = "Kwesi M.",
                IsSeller = true,
                IsVerified = true,
                ProfileComplete = true,
                InterestCategoriesJson = "[\"Food & Snacks\"]",
            },
        };

        db.Users.Add(demoUser);
        db.Users.AddRange(sellers);

        var hubListing = CreateListing(
            "l-macbook",
            sellers[0].Id,
            "MacBook Air M1 — 256GB",
            4200,
            "Computers & Accessories",
            0.3,
            ["macbook", "apple", "laptop"],
            new Dictionary<string, string>
            {
                ["brand"] = "Apple",
                ["model"] = "MacBook Air M1",
                ["storage"] = "256GB",
            },
            "Like new",
            "Main Campus library");

        var textbook = CreateListing(
            "p1",
            demoUser.Id,
            "Calculus textbook — 3rd edition",
            45,
            "Books & Stationery",
            0,
            ["textbook", "calculus", "engineering"],
            new Dictionary<string, string>(),
            "Good",
            "Main Campus");

        var hubDeal = CreateListing(
            "p2",
            demoUser.Id,
            "USB-C hub for MacBook",
            52,
            "Computers & Accessories",
            0,
            ["macbook", "usb-c", "accessories"],
            new Dictionary<string, string>(),
            "Like new",
            "Main Campus");
        hubDeal.OriginalPrice = 65;
        hubDeal.DiscountEndsAt = DateTime.UtcNow.AddDays(5);
        hubDeal.DiscountDurationDays = 7;
        hubDeal.AvailabilityType = "stock";
        hubDeal.QuantityAvailable = 10;
        hubDeal.UnitsSold = 2;

        var designService = CreateListing(
            "p3",
            demoUser.Id,
            "Logo design — campus clubs",
            80,
            "Services & Gigs",
            0,
            ["design", "logo", "freelance"],
            new Dictionary<string, string>(),
            "Like new",
            "Main Campus");
        designService.AvailabilityType = "ongoing";
        designService.UnitsSold = 5;

        db.Listings.AddRange(hubListing, textbook, hubDeal, designService);

        db.ListingReviews.AddRange(
            new ListingReview
            {
                Id = "r1",
                ListingId = hubListing.Id,
                AuthorUserId = demoUser.Id,
                AuthorName = "Alex Morgan",
                Score = 5,
                Comment = "Exactly as described. Quick meetup at the library.",
                CreatedAt = DateTime.UtcNow.AddDays(-2),
            },
            new ListingReview
            {
                Id = "r2",
                ListingId = hubListing.Id,
                AuthorUserId = "buyer-1",
                AuthorName = "Sam R.",
                Score = 4,
                Comment = "Good condition, fair price.",
                CreatedAt = DateTime.UtcNow.AddDays(-7),
            });

        var hubEnquiryChat = new Chat
        {
            Id = "chat-p2-jordan",
            ListingId = hubDeal.Id,
            BuyerId = sellers[0].Id,
            SellerId = demoUser.Id,
            CreatedAt = DateTime.UtcNow.AddHours(-6),
        };
        db.Chats.Add(hubEnquiryChat);
        db.Messages.AddRange(
            new Message
            {
                Id = "msg-hub-1",
                ChatId = hubEnquiryChat.Id,
                SenderId = sellers[0].Id,
                Content = "Hi! Is the USB-C hub still available?",
                MessageType = "text",
                SentAt = DateTime.UtcNow.AddHours(-5),
            },
            new Message
            {
                Id = "msg-hub-2",
                ChatId = hubEnquiryChat.Id,
                SenderId = demoUser.Id,
                Content = "Yes — I can meet at the library this afternoon.",
                MessageType = "text",
                SentAt = DateTime.UtcNow.AddHours(-4),
            });

        await db.SaveChangesAsync();
    }

    private static Listing CreateListing(
        string id,
        string userId,
        string title,
        decimal price,
        string category,
        double distanceKm,
        List<string> tags,
        Dictionary<string, string> attributes,
        string condition,
        string meetup)
    {
        return new Listing
        {
            Id = id,
            UserId = userId,
            Title = title,
            Description = $"{title} — listed on campus. Contact seller to arrange meetup.",
            Price = price,
            Category = category,
            Condition = condition,
            MeetupLocation = meetup,
            Status = "active",
            TagsJson = ListingMapper.SerializeTags(tags),
            AttributesJson = ListingMapper.SerializeAttributes(attributes),
            DistanceKm = distanceKm,
            Images =
            [
                new ListingImage
                {
                    Id = $"{id}-img-1",
                    ListingId = id,
                    ImageUrl = $"https://placehold.co/600x600/png?text={Uri.EscapeDataString(title)}",
                    SortOrder = 0,
                },
            ],
        };
    }
}
