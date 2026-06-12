-- UniMarket D1 schema (SQLite). Source of truth when Cloudflare__D1Enabled=true.
-- C# API hydrates from D1 on startup and syncs writes back after each SaveChanges.

CREATE TABLE IF NOT EXISTS Users (
  Id TEXT PRIMARY KEY NOT NULL,
  FirebaseUid TEXT,
  FullName TEXT NOT NULL,
  Email TEXT NOT NULL,
  Role TEXT NOT NULL DEFAULT 'Student',
  IsSeller INTEGER NOT NULL DEFAULT 0,
  IsVerified INTEGER NOT NULL DEFAULT 0,
  AvatarUrl TEXT,
  University TEXT NOT NULL DEFAULT 'State University',
  Campus TEXT NOT NULL DEFAULT 'Main Campus',
  Phone TEXT,
  ProfileComplete INTEGER NOT NULL DEFAULT 0,
  VerifiedStudentEmail TEXT,
  VerifiedStudentEmailAt TEXT,
  InterestCategoriesJson TEXT NOT NULL DEFAULT '[]',
  CreatedAt TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS IX_Users_Email ON Users(Email);
CREATE INDEX IF NOT EXISTS IX_Users_FirebaseUid ON Users(FirebaseUid);

CREATE TABLE IF NOT EXISTS Listings (
  Id TEXT PRIMARY KEY NOT NULL,
  UserId TEXT NOT NULL,
  Title TEXT NOT NULL,
  Description TEXT NOT NULL,
  Price REAL NOT NULL,
  OriginalPrice REAL,
  DiscountEndsAt TEXT,
  DiscountDurationDays INTEGER,
  Category TEXT NOT NULL,
  Condition TEXT,
  MeetupLocation TEXT,
  Status TEXT NOT NULL DEFAULT 'active',
  AvailabilityType TEXT NOT NULL DEFAULT 'unique',
  QuantityAvailable INTEGER,
  UnitsSold INTEGER NOT NULL DEFAULT 0,
  TagsJson TEXT NOT NULL DEFAULT '[]',
  AttributesJson TEXT NOT NULL DEFAULT '{}',
  Latitude REAL,
  Longitude REAL,
  DistanceKm REAL NOT NULL DEFAULT 0,
  CreatedAt TEXT NOT NULL,
  FOREIGN KEY (UserId) REFERENCES Users(Id)
);

CREATE INDEX IF NOT EXISTS IX_Listings_UserId ON Listings(UserId);
CREATE INDEX IF NOT EXISTS IX_Listings_Status ON Listings(Status);

CREATE TABLE IF NOT EXISTS ListingImages (
  Id TEXT PRIMARY KEY NOT NULL,
  ListingId TEXT NOT NULL,
  ImageUrl TEXT NOT NULL,
  SortOrder INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (ListingId) REFERENCES Listings(Id)
);

CREATE INDEX IF NOT EXISTS IX_ListingImages_ListingId ON ListingImages(ListingId);

CREATE TABLE IF NOT EXISTS Chats (
  Id TEXT PRIMARY KEY NOT NULL,
  ListingId TEXT NOT NULL,
  BuyerId TEXT NOT NULL,
  SellerId TEXT NOT NULL,
  CreatedAt TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS IX_Chats_BuyerId ON Chats(BuyerId);
CREATE INDEX IF NOT EXISTS IX_Chats_SellerId ON Chats(SellerId);

CREATE TABLE IF NOT EXISTS Messages (
  Id TEXT PRIMARY KEY NOT NULL,
  ChatId TEXT NOT NULL,
  SenderId TEXT NOT NULL,
  Content TEXT NOT NULL,
  MessageType TEXT NOT NULL DEFAULT 'text',
  SaleId TEXT,
  ConfirmationStatus TEXT,
  SentAt TEXT NOT NULL,
  FOREIGN KEY (ChatId) REFERENCES Chats(Id)
);

CREATE INDEX IF NOT EXISTS IX_Messages_ChatId ON Messages(ChatId);

CREATE TABLE IF NOT EXISTS CampusEmailOtps (
  Id TEXT PRIMARY KEY NOT NULL,
  UserId TEXT NOT NULL,
  Email TEXT NOT NULL,
  CodeHash TEXT NOT NULL,
  ExpiresAt TEXT NOT NULL,
  VerifiedAt TEXT,
  CreatedAt TEXT NOT NULL,
  FOREIGN KEY (UserId) REFERENCES Users(Id)
);

CREATE INDEX IF NOT EXISTS IX_CampusEmailOtps_UserId_CreatedAt
  ON CampusEmailOtps(UserId, CreatedAt);

CREATE TABLE IF NOT EXISTS VerificationRequests (
  Id TEXT PRIMARY KEY NOT NULL,
  UserId TEXT NOT NULL,
  RequestType TEXT NOT NULL,
  Status TEXT NOT NULL,
  StoreName TEXT,
  StudentEmail TEXT,
  IdDocumentUrl TEXT,
  AiReviewSummary TEXT,
  AiRecommendation TEXT,
  AdminNotes TEXT,
  SubmittedAt TEXT NOT NULL,
  ProcessedAt TEXT,
  FOREIGN KEY (UserId) REFERENCES Users(Id)
);

CREATE INDEX IF NOT EXISTS IX_VerificationRequests_UserId ON VerificationRequests(UserId);
CREATE INDEX IF NOT EXISTS IX_VerificationRequests_Status ON VerificationRequests(Status);

CREATE TABLE IF NOT EXISTS ListingReviews (
  Id TEXT PRIMARY KEY NOT NULL,
  ListingId TEXT NOT NULL,
  AuthorUserId TEXT NOT NULL,
  AuthorName TEXT NOT NULL,
  Score INTEGER NOT NULL,
  Comment TEXT NOT NULL,
  CreatedAt TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS IX_ListingReviews_ListingId ON ListingReviews(ListingId);

CREATE TABLE IF NOT EXISTS ListingReports (
  Id TEXT PRIMARY KEY NOT NULL,
  ListingId TEXT NOT NULL,
  ReporterUserId TEXT NOT NULL,
  Reason TEXT NOT NULL,
  Comment TEXT,
  Status TEXT NOT NULL DEFAULT 'Pending',
  CreatedAt TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS WishlistItems (
  UserId TEXT NOT NULL,
  ListingId TEXT NOT NULL,
  SavedAt TEXT NOT NULL,
  PRIMARY KEY (UserId, ListingId)
);

CREATE TABLE IF NOT EXISTS SaleRecords (
  Id TEXT PRIMARY KEY NOT NULL,
  ListingId TEXT NOT NULL,
  SellerId TEXT NOT NULL,
  BuyerId TEXT,
  Units INTEGER NOT NULL DEFAULT 1,
  Status TEXT NOT NULL DEFAULT 'seller_reported',
  CreatedAt TEXT NOT NULL,
  ConfirmedAt TEXT
);

CREATE INDEX IF NOT EXISTS IX_SaleRecords_ListingId ON SaleRecords(ListingId);
CREATE INDEX IF NOT EXISTS IX_SaleRecords_SellerId ON SaleRecords(SellerId);

CREATE TABLE IF NOT EXISTS SaleConfirmations (
  Id TEXT PRIMARY KEY NOT NULL,
  SaleId TEXT NOT NULL,
  BuyerId TEXT NOT NULL,
  ChatId TEXT NOT NULL,
  Status TEXT NOT NULL DEFAULT 'pending',
  CreatedAt TEXT NOT NULL,
  RespondedAt TEXT,
  FOREIGN KEY (SaleId) REFERENCES SaleRecords(Id)
);

CREATE INDEX IF NOT EXISTS IX_SaleConfirmations_SaleId ON SaleConfirmations(SaleId);

CREATE TABLE IF NOT EXISTS DeviceRegistrations (
  Id TEXT PRIMARY KEY NOT NULL,
  UserId TEXT NOT NULL,
  Token TEXT NOT NULL,
  Platform TEXT NOT NULL DEFAULT 'unknown',
  UpdatedAt TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS IX_DeviceRegistrations_Token ON DeviceRegistrations(Token);

CREATE TABLE IF NOT EXISTS UserNotifications (
  Id TEXT PRIMARY KEY NOT NULL,
  UserId TEXT NOT NULL,
  Title TEXT NOT NULL,
  Body TEXT NOT NULL,
  Type TEXT NOT NULL DEFAULT 'system',
  TargetId TEXT,
  ActionLabel TEXT,
  IsRead INTEGER NOT NULL DEFAULT 0,
  CreatedAt TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS IX_UserNotifications_UserId_CreatedAt
  ON UserNotifications(UserId, CreatedAt);
