-- UniMarket D1 schema (SQLite-compatible). Applied by API startup when D1 is enabled.
-- Home server uses the same model via EF Core SQLite file: data/unimarket.db

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
  InterestCategoriesJson TEXT NOT NULL DEFAULT '[]',
  CreatedAt TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS IX_Users_Email ON Users(Email);
CREATE INDEX IF NOT EXISTS IX_Users_FirebaseUid ON Users(FirebaseUid);

CREATE TABLE IF NOT EXISTS VerificationRequests (
  Id TEXT PRIMARY KEY NOT NULL,
  UserId TEXT NOT NULL,
  RequestType TEXT NOT NULL,
  Status TEXT NOT NULL,
  StoreName TEXT,
  IdDocumentUrl TEXT,
  AiReviewSummary TEXT,
  AiRecommendation TEXT,
  AdminNotes TEXT,
  SubmittedAt TEXT NOT NULL,
  ProcessedAt TEXT,
  FOREIGN KEY (UserId) REFERENCES Users(Id)
);
