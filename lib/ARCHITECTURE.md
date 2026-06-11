# UniMarket — App Architecture

Flutter prototype structured for a future API backend. UI stays in **features**; shared contracts live in **core**.

## Folder layout

```
lib/
├── app.dart                 # App root, store DI, MaterialApp routes
├── routes/                  # Named routes (auth, shell entry)
├── core/
│   ├── constants/           # Categories, assets, posting schemas
│   ├── models/              # Domain models (ListingItem, threads, …)
│   ├── theme/               # Colors, typography, AppTheme
│   ├── navigation/          # ListingNavigation (detail, grids)
│   ├── data/
│   │   ├── mock/            # Temporary seed data — delete when API lands
│   │   ├── stores/          # ChangeNotifier state (SellerStore, MessageStore)
│   │   ├── services/        # HomeFeedService (feed composition)
│   │   └── repositories/    # Backend contracts (swap mock → API here)
│   └── widgets/             # Design system + store scopes only
└── features/                # One folder per user journey
    ├── auth/
    ├── onboarding/
    ├── shell/               # Bottom nav, feed chrome
    ├── home/
    ├── listings/            # Browse, detail, reviews, cards, grid
    ├── search/
    ├── sell/                # Post, edit, seller onboarding
    ├── seller/              # Public seller profile
    ├── profile/
    ├── messages/
    └── notifications/
```

## Layers

| Layer | Role | Backend swap |
|-------|------|----------------|
| **features/** | Screens & feature widgets | Minimal changes |
| **repositories/** | Data contracts | Add `ApiListingsRepository`, etc. |
| **stores/** | In-memory state today | Repos call API, stores become caches |
| **mock/** | Seed JSON-shaped data | Remove; repos fetch remote |
| **services/** | Feed/section composition | Move to `FeedRepository` + API |

## Key flows

- **Catalog**: `SellerStore.allListings` (seller posts + mock catalog). Use `ListingsRepository` interface when wiring API.
- **Home feed**: `HomeFeedService.buildFeed()` → sections with previews. **See all** → `ListingGridScreen` (single reusable grid).
- **Categories**: `ListingGridScreen.openCategory()` — same grid, category filter.
- **Listing detail**: `ListingNavigation.openDetail()` — resolves canonical listing id before push.

## Conventions

1. **No navigation in stores** — push routes from screens or `core/navigation/`.
2. **No feature imports in `core/widgets/`** — listing UI lives under `features/listings/`.
3. **Mock data only in `core/data/mock/`** — features read via stores/repos.
4. **Barrel exports**: `core/data/data.dart`, `features/listings/listings.dart`.

## UI state (prototype-complete)

| Store | Path | Backend target |
|-------|------|----------------|
| Session | `stores/user_session_store.dart` | Firebase Auth + `POST /api/auth/session` |
| Seller | `stores/seller_store.dart` | Listings, seller application |
| Wishlist | `stores/wishlist_store.dart` | `GET/POST /api/wishlist` |
| Messages | `stores/message_store.dart` | Chats + SignalR |
| Notifications | `stores/notification_store.dart` | Push / inbox API |
| Reviews | `stores/review_store.dart` | Listing reviews |
| Reports | `stores/report_store.dart` | `POST /api/reports` |
| Preferences | `stores/app_preferences_store.dart` | Local only |

Screens added: `settings_screen`, `edit_profile_screen`, `my_reports_screen`.

Demo sign-in: `alex.morgan@university.edu` loads seller seed data.

## Next steps (backend)

1. Run API on home server: `backend/UniMarket.Api` (see `backend/README.md`).
2. Add `ApiClient` + DTOs with `fromJson`.
3. Implement `ApiListingsRepository` / `ApiFeedRepository`.
4. Replace `imageAsset` with R2 URLs on models.
5. Wire Firebase ID tokens when Firebase project is ready.
