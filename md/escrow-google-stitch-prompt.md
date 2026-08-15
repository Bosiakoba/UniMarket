# UniMarket × Escrow — Prompt for Google Stitch

> How to use: paste everything below the line into Google Stitch (the text between "START PROMPT" and "END PROMPT"). The prompt is fully self-contained — every color, font size, radius, spacing and layout rule is specified so Stitch reproduces the app's design with no other reference needed.

---

## START PROMPT

Build a mobile marketplace app called **UniMarket** — a student-to-student buying & selling marketplace for Ghanaian university campuses (Legon, KNUST, etc.). ALL money amounts are in Ghana Cedis (GHS), whole numbers for item prices, with decimals only in fee/total rows. Reproduce the exact design language below on EVERY screen, then implement the 8 escrow-protection screens at the end with the same visual system.

---

## PART A — DESIGN SYSTEM (apply globally, never deviate)

**Font:** Poppins for everything (headings, body, buttons, inputs, captions). No other font ever.

**Type scale (exact):**
- Display = 40px, weight 800, letterSpacing −0.5, white
- H1 = 28px, weight 700, letterSpacing −0.3, near-black
- H2 = 22px, weight 600, near-black
- H3 = 18px, weight 600, near-black
- Body = 15px, weight 400, line-height 1.5, #5C6358
- BodyBold = 15px, weight 600, near-black
- Caption = 13px, weight 500, #8A9187
- Price = 17px, weight 700, forest green
- Button = 16px, weight 600, white
- Micro labels/numbers inside stat tiles = 11px weight 700 (numbers may scale to 22px weight 800)

**Color palette (exact hex, nothing else):**
- forestGreen #093F0B · forestGreenLight #0F5A14 · forestGreenDeep #062808
- white #FFFFFF · black #0A0A0A · canvas #F7F8F6 · surfaceMuted #F0F2EE · border #E4E6E1
- textPrimary #0A0A0A · textSecondary #5C6358 · textTertiary #8A9187
- dustyRose #CF9D9D · logoOrange #FF8C42 · logoPink #FF4E63 · dealRed #E53935 · verifiedGold #E8B84A
- Brand gradient (page-level green backdrops) = linear, top-left → bottom-right, #093F0B → #0F5A14 → #062808
- Logo gradient = linear, top → bottom, #FF8C42 → #FF4E63

**Radii (exact):** sm 12 · md 20 · lg 28 · pill 999 · sheet 40 (sheet = top corners only)
**Spacing scale:** 4 / 8 / 16 / 24 / 32 / 48 px

**Buttons (signature pill buttons, height 56, zero elevation/shadow):**
- PRIMARY = black background #0A0A0A, white 16px/600 text, full pill radius. Default action on every screen.
- GREEN = forestGreen background, white text, pill.
- SECONDARY = white background, black text, pill.
- OUTLINE = transparent fill, black text, 1px #E4E6E1 border, pill.
- Loading state = replace label with a 22px white circular spinner (stroke 2) inside the same pill.
- Hero/Get Started variant = white pill 260×58, radius 40, soft drop shadow (0,8,20px, black@15%), label 16/600 black, right-anchored 46px forestGreen circle containing a white arrow-right icon.

**Text inputs (UniTextField style, used everywhere):**
- Filled white, FULL PILL radius 999, content padding 22 horizontal / 18 vertical.
- Border 1px #E4E6E1; focused border becomes forestGreen @ 1.5px.
- Hint/placeholder text #8A9187; optional leading icon 22px #8A9187.
- Multiline/textarea variant: same fill but radius 16, 4 lines, top-aligned text.

**Card token:** white surface, hairline border 1px #E4E6E1 (or light gray #E0E0E0), radius 8 for product tiles / radius 14–16 for content & info cards, internal padding 16–20.
**Green-backdrop screens (auth, splash, onboarding, success states):**
- Fill the entire page with the brand gradient. Decorate with 3 soft translucent blobs: a dusty-rose circle (#CF9D9D @ 18% opacity) near top-right, an orange circle (#FF8C42 @ 12%) bottom-left, a faint white circle (@ 6%) mid-left.
- White content cards / frosted panels sit above (horizontal page padding 24).
- Back button where needed = plain white arrow head, white icon.

**Floating bottom nav (main shell) — keep exactly:**
- Black floating pill bar, radius 32, height 58, horizontal margin 20, bottom margin 12 (above the safe-area inset), elevation 8 with black@20% shadow.
- Order: Home → Search → center raised 52px forestGreen circle with a white "+" (Post) → Heart (Wishlist) → User (Profile).
- Active item = white filled circle 44px with black icon; inactive = white icons @85% opacity.

**Feed top bar:** storefront/logo glyph 26px forestGreen + "UniMarket" in 20px weight 900 forestGreen, letterSpacing -0.6; right side: two 44px circles (surfaceMuted) with message-circle and bell icons (20px), each showing a dealRed unread badge (16px pill, white 1.5px border, "99+" cap).

**Badges & meta tokens:**
- Verified badge = pill, forestGreen@10% bg, forestGreen@20% 1px border, emerald badge-check 14px + "Verified" 13/500 green.
- Verified-ID mini badge on product photos = light blue bg #E3F2FD, text #0D47A1, 11px bold, small shield-check icon.
- Discount chip on product photos = dealRed bg, white bold 11px, e.g. "-20% · 6d left", 6px radius.
- Star rating row = 5 star icons 14-16px (filled verifiedGold, empty #E4E6E1) + "4.8" bold + "(23 reviews)" caption.
- Price display = forestGreen, weight 700, line-through original in #8A9187 when discounted.

## PART B — EXISTING PROPERTY TO KEEP IDENTICAL

1. Splash — center white-disc logo ring on the green gradient.
2. Onboarding (3 pages) — descriptions: "Discover campus deals", "Meet verified sellers", "Earn while you study"; frosted-white content panel + page dots + hero Get-Started button.
3. Sign In / Sign Up — green gradient, white rounded sheet, pill inputs, black primary button, social round buttons, green "Create account".
4. Home feed — feed top bar; H1 headline "Discover campus deals near you."; sticky search pill; sections with H3 + "See all" green links; 2-column grid of listing cards; pull-to-refresh.
5. Listing detail — photo carousel (white round arrows + page dots), title, price + original line-through, star rating, attribute chips, green "Contact seller" pill.
6. Listing card — white tile radius 8, 1px light-gray border, image top with badges + heart, price 15/700 green, title 13 max-2-lines, caption meta joined by " • ".
7. Profile — avatar disc, "Verified" badge, stats row, settings/submenu tile list (icon 20, title, chevron).
8. Chat — bubbles: mine = forestGreen pill white text radius 16 with one 4px corner; theirs = white with border; system messages centered gray pills; pill input row.

The escrow screens below are NEW screens that continue this exact design language.
## PART C — THE 8 NEW ESCROW SCREENS

**Global escrow concept every screen reflects:** UniMarket holds the buyer's payment in escrow until the buyer confirms the item was received. Funds are only released to the seller after confirmation. All 8 screens use white/canvas page backgrounds (except success gates), the feed top bar pattern with a back arrow, standard AppBars where needed, and the exact buttons/inputs from Part A.

---

**SCREEN 1 — ESCROW CHECKOUT** (entry: buyer taps "Buy with Escrow" on a listing)

Layout: white page, standard AppBar with back arrow + H3 title "Escrow Checkout".

- Product summary card (white, radius 14, 1px border): row of [photo 64x64 radius 12] [title BodyBold 15 (2 lines) · seller name caption grey · "GHS 450" price 15/700 forestGreen].
- Below: a forestGreen@8% callout row (radius 14): shield-check icon forestGreen 18px + caption "Payment is protected by UniMarket escrow — you only release it when you confirm receipt."
- H3 "Buyer information":
  - Text field 1 (pill): "Full name" placeholder
  - Text field 2 (pill): "Campus email"
  - Text field 3 (pill): "Phone number"
- H3 "Payment breakdown" white card: label-left / value-right rows:
  - "Item price" → GHS 450.00
  - "Delivery fee" → GHS 15.00
  - "Platform fee (3%)" → GHS 13.50
  - divider
  - "Total amount" (bold 15) → "GHS 478.50" price style forestGreen 18px/700
- Explainer block (muted): lock icon + "Funds are held by UniMarket escrow and only released to the seller when you confirm receipt."
- Fixed bottom bar (white, top hairline, safe area, padding 20): BLACK primary pill "Pay GHS 478.50" (full width, 56px). Tap → spinner → Screen 2. Caption under button: "Pay with Mobile Money (MTN / Vodafone / AirtelTigo)".

---

**SCREEN 2 — PAYMENT SUCCESSFUL**

Full green brand-gradient background + soft blobs (Part A).

Center column (padding 32, centered):
- Confirmation mark: 120px white circle with a 64px forestGreen circle inside and a white check icon.
- H1 white: "Payment successful!"
- Body white@88%: "Your payment is safely held in escrow. The seller has been notified to prepare and deliver your item."
- White card (radius 20): "How escrow works" mini-steps: ① Buyer pays — funds held by UniMarket; ② Seller delivers; ③ Buyer confirms receipt; ④ Seller is paid.
- Action: hero white pill 280 width "Track order" → Screen 3. Below: transparent outline white "Back to home".

---

**SCREEN 3 — ORDER TRACKING** (buyer; route: after payment / orders hub)

AppBar title "Order Tracking" + back chevron.

- Top card (white, radius 14, 1px border): product thumb 48 + title (2 lines, 14/600) + "GHS 478.50 total" caption + green "Order #UN-482910" pill.
- H3 "Order progress".
- Vertical TIMELINE inside a white rounded card (radius 16), padding 20, with a continuous 2px vertical guide line on the left 24px gutter. Six steps, each with a marker + title + caption + timestamp:
  1. "Awaiting payment" — caption "Waiting for buyer to pay at escrow checkout." — dot = outline
  2. "Payment held in escrow" — caption "GHS 478.50 locked by UniMarket." — dot = filled forestGreen (current)
  3. "Seller preparing order" — "Seller has started preparing." 
  4. "Seller delivered item" — "Item left at pickup point."
  5. "Waiting for buyer confirmation" — "Confirm receipt to release funds."
  6. "Payment released to seller" — "Funds sent to seller's payout account."
- Marker states: completed = forestGreen filled circle + white check (14px); current = forestGreen ring with pulsing inner dot; upcoming = light grey outline #C9CEC5.
- Below timeline: dealRed outline text row "Need help? Open a dispute" opening Screen 7. Plus small grey caption "Money stays in escrow until you confirm receipt."

---

**SCREEN 4 — DELIVERY CONFIRMATION** (buyer)

AppBar "Confirm Delivery".

- Info banner green@8%: truck icon in forestGreen circle + "Your item has arrived at the pickup point." caption.
- H3 "Delivery status" card (white radius 14): rows "Arrived at UniMarket Hub" (bold) / "Student Services Building, Legon" / "Collect before 6 PM today" + status pill dealRed "Action needed".
- H3 "Order summary" card: thumb 48 + title + "GHS 450.00" + divider + row "Order" / "#UM-4822" + "Delivery code" / "884F3A" monospace.
- H3 "Confirm receipt" — the two methods:
  - OUTLINE pill full width "Enter collection code" → inline 6-box code input (see Screen 5)
  - SECONDARY pill "Scan QR code" → Screen 5
- Confirm explainer caption: "Confirming releases escrow funds to the seller immediately. Only confirm when you have the item in hand."
- Green primary pill (56px) "Confirm receipt" → success gate (green gradient check screen: "Great! Payment released to seller") → Screen 6.

---

**SCREEN 5 — QR VERIFICATION** (buyer)

AppBar "Verify delivery".

- Main card (white radius 20, padding 24): dashed rounded square (aspect 1:1) with a QR-code glyph placeholder (56px) + caption "Scan the QR code on the seller's package using your phone camera."
- Below in card: "OR" centered caption, then "Manual entry" — six 34px square cells in a row (radius 8, hairline border; focused cell gets forestGreen border + subtle shadow); button GREEN pill "Verify code" disabled until 6 digits.
- Mock valid code: 884F3A. On verify → green check overlay "Code verified" → auto-advance to Screen 4 confirm-receipt success / Screen 6.

---

**SCREEN 6 — ESCROW STATUS**

AppBar "Escrow status".

- Top card (white, radius 14) shield icon + "Escrow protection active" chip green + order summary mini row.
- Money "vault" hero card with three stacked rows, each: [icon 20 in tinted circle] [label + caption] [value right bold]:
  1. "Funds held" — forestGreen tint — "GHS 450.00" + "Held by UniMarket" 
  2. "Funds pending release" — verifiedGold/amber tint — "GHS 0.00" + "Awaiting buyer confirmation"
  3. "Funds released" — forestGreen with check — "GHS 0.00" + "Sent to seller when released".
- State becomes highlighted depending on position: active row strong filled icon / other rows descoped.
- Below: fee breakdown caption "Item 450 · Delivery 15 · Fee 13.50 · Total 478.50" grey 13px.
- Depending on state, the bottom action shows:
  - Held → green pill "Confirm receipt" + outline "Open dispute"
  - Pending release → amber info banner "Awaiting buyer confirmation"
  - Released → banner green "Funds released on Aug 14 · Reference #REF-884F3A".
---

**SCREEN 7 — DISPUTE** (buyer)

AppBar "Dispute".

- Info banner (amber @10% bg, radius 14): info icon verifiedGold + caption "While a dispute is open, escrow funds are frozen — neither party can be paid until UniMarket resolves it."
- H3 "Open a dispute":
  - white selection card (radius 14) with exclusive options (radio circles, checked = forestGreen dot, unchecked = grey ring):
    a. Item not delivered
    b. Item different from description
    c. Item damaged or defective
    d. Seller unresponsive
    e. Other
  - "Tell us what happened" — multiline textarea (radius 16, 4 lines).
  - "Upload evidence" — add-tile 56 dashed + thumbnail tiles (with tiny X).
- "Chat with seller" card: avatar disc initials + name + "Online", chevron → opens chat with caption "Messages are saved as dispute evidence."
- Bottom BLACK primary pill "Submit dispute" (56px) → dialog confirmation "Dispute submitted. Funds are frozen. We'll respond within 5 business days." → green success route.

---

**SCREEN 8 — SELLER ORDER MANAGEMENT** (seller view)

AppBar "Orders" + earnings pill right (green caption "GHS 1,240.00").

- 2×2 dashboard tile grid: each tile = white card radius 14, big number 24/800 black, label caption, colored icon:
  - "Active orders" — forestGreen
  - "Pending release" — verifiedGold
  - "Released payments" — green check
  - "Disputed orders" — dealRed
- Filter chips row horizontal scroll: All / Active / Pending release / Released / Disputed (selected = forestGreen pill filled; unselected = white pill grey text).
- Order cards (white radius 14, 1px border), each:
  - Row: thumb 48 + title (14/600) + order id caption + price green bold + status pill (Preparing = green@8% text; Awaiting confirmation = amber; Released = green filled; Disputed = red@10% dealRed text).
  - Action row depends: "Mark as delivered" green pill / "Release funds" green pill (pending release) / "View dispute" outline red / "Reached payout" text grey.
- Pinned bottom bar (white): left caption "Holdings in escrow: GHS 1,375.50" + right black pill "Release all eligible".

---

## PART D — FLOW & BEHAVIOR NOTES

- Navigation: Listing detail → "Buy with Escrow" (green pill) → Screen 1 → Screen 2 → Screen 3 → 4/5 → success → 6. 7 reachable from 3/6/8. 8 only reachable via seller menu ("Orders").
- All data is mock/UI-only but must look realistic (Legon campus, GHS amounts, MTN/Vodafone/AirtelTigo mobile money).
- Keep the app fully in the same design language; all 8 screens must look like they were designed by the same Figma file as the original pages.

## END PROMPT