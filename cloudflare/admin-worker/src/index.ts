export interface Env {
  UNIMARKET_API_URL: string;
  ADMIN_API_KEY: string;
  AI: Ai;
}

interface Ai {
  run(model: string, input: Record<string, unknown>): Promise<unknown>;
}

export interface VerificationRequest {
  id: string;
  userId: string;
  requestType: string;
  status: string;
  storeName?: string | null;
  studentEmail?: string | null;
  idDocumentUrl?: string | null;
  aiReviewSummary?: string | null;
  aiRecommendation?: string | null;
  adminNotes?: string | null;
  submittedAt: string;
  processedAt?: string | null;
  userFullName?: string | null;
  userEmail?: string | null;
  university?: string | null;
  campus?: string | null;
  isSeller: boolean;
  isVerified: boolean;
}

async function apiFetch(
  env: Env,
  path: string,
  init?: RequestInit,
): Promise<Response> {
  const base = env.UNIMARKET_API_URL.replace(/\/$/, "");
  return fetch(`${base}${path}`, {
    ...init,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-Admin-Key": env.ADMIN_API_KEY,
      ...(init?.headers ?? {}),
    },
  });
}

function labelForType(type: string): string {
  return type === "verified_badge" ? "Verified badge" : "Seller application";
}

function renderPage(body: string): Response {
  return new Response(body, {
    headers: {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

function renderDashboard(items: VerificationRequest[]): string {
  const rows = items
    .map((item) => {
      const submitted = new Date(item.submittedAt).toLocaleString();
      return `<tr>
        <td><a href="/requests/${item.id}">${escapeHtml(labelForType(item.requestType))}</a></td>
        <td>${escapeHtml(item.userFullName ?? "—")}<br><span class="muted">${escapeHtml(item.userEmail ?? "")}</span></td>
        <td>${escapeHtml(item.storeName ?? "—")}</td>
        <td><span class="pill">${escapeHtml(item.status)}</span></td>
        <td>${escapeHtml(submitted)}</td>
      </tr>`;
    })
    .join("");

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>UniMarket Admin</title>
  <style>
    :root { --green:#1f6b4a; --bg:#f4f6f5; --card:#fff; --muted:#667; }
    * { box-sizing:border-box; }
    body { margin:0; font-family:Segoe UI, system-ui, sans-serif; background:var(--bg); color:#122; }
    header { background:var(--green); color:#fff; padding:20px 24px; }
    main { max-width:1100px; margin:24px auto; padding:0 16px 40px; }
    .card { background:var(--card); border-radius:16px; padding:20px; box-shadow:0 8px 24px rgba(0,0,0,.06); }
    table { width:100%; border-collapse:collapse; }
    th, td { text-align:left; padding:12px 8px; border-bottom:1px solid #e8ecea; vertical-align:top; }
    th { font-size:12px; text-transform:uppercase; letter-spacing:.04em; color:var(--muted); }
    a { color:var(--green); text-weight:600; text-decoration:none; }
    .muted { color:var(--muted); font-size:13px; }
    .pill { display:inline-block; padding:4px 10px; border-radius:999px; background:#eef6f1; color:var(--green); font-size:12px; font-weight:600; }
    .toolbar { display:flex; gap:10px; flex-wrap:wrap; margin-bottom:16px; }
    button, .btn { border:0; border-radius:10px; padding:10px 14px; cursor:pointer; font-weight:600; }
    .btn-green { background:var(--green); color:#fff; }
    .btn-light { background:#e8ecea; color:#122; }
    img.doc { max-width:100%; border-radius:12px; border:1px solid #dde3df; }
    pre.ai { white-space:pre-wrap; background:#f8faf9; padding:12px; border-radius:12px; }
  </style>
</head>
<body>
  <header>
    <h1>UniMarket Admin</h1>
    <p>Review seller applications and verified badge requests</p>
  </header>
  <main>
    <div class="card">
      <div class="toolbar">
        <a class="btn btn-light" href="/?status=Pending">Pending</a>
        <a class="btn btn-light" href="/?status=Approved">Approved</a>
        <a class="btn btn-light" href="/?status=Rejected">Rejected</a>
        <a class="btn btn-light" href="/?type=seller_application">Seller apps</a>
        <a class="btn btn-light" href="/?type=verified_badge">Badge requests</a>
      </div>
      <table>
        <thead>
          <tr>
            <th>Type</th>
            <th>Applicant</th>
            <th>Store</th>
            <th>Status</th>
            <th>Submitted</th>
          </tr>
        </thead>
        <tbody>
          ${rows || `<tr><td colspan="5" class="muted">No requests in this view.</td></tr>`}
        </tbody>
      </table>
    </div>
  </main>
</body>
</html>`;
}

function renderDetail(item: VerificationRequest): string {
  const doc = item.idDocumentUrl
    ? `<img class="doc" src="/requests/${escapeAttr(item.id)}/id-document" alt="ID document" />`
    : `<p class="muted">No ID document attached.</p>`;

  const aiBlock = item.aiReviewSummary
    ? `<pre class="ai">${escapeHtml(item.aiReviewSummary)}${
        item.aiRecommendation
          ? `\n\nRecommendation: ${item.aiRecommendation}`
          : ""
      }</pre>`
    : `<p class="muted">No AI review yet.</p>`;

  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Review ${escapeHtml(item.id)}</title>
  <style>
    :root { --green:#1f6b4a; --bg:#f4f6f5; --card:#fff; --muted:#667; }
    body { margin:0; font-family:Segoe UI, system-ui, sans-serif; background:var(--bg); color:#122; }
    header { background:var(--green); color:#fff; padding:20px 24px; }
    main { max-width:900px; margin:24px auto; padding:0 16px 40px; display:grid; gap:16px; }
    .card { background:var(--card); border-radius:16px; padding:20px; box-shadow:0 8px 24px rgba(0,0,0,.06); }
    .muted { color:var(--muted); }
    img.doc { max-width:100%; border-radius:12px; border:1px solid #dde3df; }
    pre.ai { white-space:pre-wrap; background:#f8faf9; padding:12px; border-radius:12px; }
    .actions { display:flex; gap:10px; flex-wrap:wrap; }
    button { border:0; border-radius:10px; padding:12px 16px; cursor:pointer; font-weight:600; }
    .approve { background:var(--green); color:#fff; }
    .reject { background:#b42318; color:#fff; }
    .ai { background:#eef6f1; color:var(--green); }
    textarea { width:100%; min-height:80px; border-radius:10px; border:1px solid #ccd4cf; padding:10px; }
    a { color:var(--green); }
  </style>
</head>
<body>
  <header>
    <p><a href="/" style="color:#dff3e8">← Back to queue</a></p>
    <h1>${escapeHtml(labelForType(item.requestType))}</h1>
    <p>${escapeHtml(item.userFullName ?? "")} · ${escapeHtml(item.userEmail ?? "")}</p>
  </header>
  <main>
    <section class="card">
      <h2>Applicant</h2>
      <p><strong>Campus:</strong> ${escapeHtml(item.university ?? "—")} · ${escapeHtml(item.campus ?? "—")}</p>
      <p><strong>Student email:</strong> ${escapeHtml(item.studentEmail ?? item.userEmail ?? "—")}</p>
      <p><strong>Store:</strong> ${escapeHtml(item.storeName ?? "—")}</p>
      <p><strong>Status:</strong> ${escapeHtml(item.status)}</p>
    </section>
    <section class="card">
      <h2>Student ID</h2>
      ${doc}
    </section>
    <section class="card">
      <h2>AI assist</h2>
      <p class="muted">Runs in the background after submit, or on demand below. AI never auto-approves.</p>
      ${aiBlock}
      <form method="post" action="/requests/${escapeAttr(item.id)}/ai-review" style="margin-top:12px">
        <button class="ai" type="submit">Run Workers AI review</button>
      </form>
    </section>
    <section class="card">
      <h2>Decision</h2>
      <form method="post" action="/requests/${escapeAttr(item.id)}/reject" style="margin-bottom:12px">
        <label class="muted">Notes (optional, shown internally)</label>
        <textarea name="notes" placeholder="Reason if rejecting…"></textarea>
        <div class="actions" style="margin-top:12px">
          <button class="reject" type="submit">Reject</button>
        </div>
      </form>
      <form method="post" action="/requests/${escapeAttr(item.id)}/approve">
        <div class="actions">
          <button class="approve" type="submit">Approve</button>
        </div>
      </form>
    </section>
  </main>
</body>
</html>`;
}

function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function escapeAttr(value: string): string {
  return escapeHtml(value).replaceAll("'", "&#39;");
}

interface AiReviewResult {
  summary: string;
  recommendation: "approve" | "review";
}

interface IdVisionAssessment {
  isStudentId: boolean;
  summary: string;
  whatImageShows: string | null;
  nameOnId: string | null;
  universityOnId: string | null;
  nameMatchesProfile: boolean;
  universityMatchesProfile: boolean;
}

interface ParsedVisionFields {
  rawText: string;
  isStudentIdClaim: boolean | null;
  whatImageShows: string | null;
  nameOnId: string | null;
  universityOnId: string | null;
  nameMatchesProfile: boolean | null;
  universityMatchesProfile: boolean | null;
}

const VISION_MODEL_PRIMARY = "@cf/meta/llama-3.2-11b-vision-instruct";
const VISION_MODEL_FALLBACK = "@cf/llava-hf/llava-1.5-7b-hf";

interface EmailCampusCheck {
  summary: string;
  isCampusDomain: boolean;
  domainMatchesUniversity: boolean;
  score: number;
}

function tokenizeUniversity(value: string): string[] {
  const stopWords = new Set(["the", "and", "of", "for", "at", "in"]);
  const words = value
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((token) => token.length > 2 && !stopWords.has(token));

  const tokens = [...words];
  const acronym = words
    .filter((word) => word.length > 1)
    .map((word) => word[0])
    .join("");
  if (acronym.length >= 3) {
    tokens.push(acronym);
  }

  return tokens;
}

function assessEmailCampusMatch(
  email: string | null | undefined,
  university: string | null | undefined,
): EmailCampusCheck {
  const normalizedEmail = (email ?? "").trim().toLowerCase();
  const normalizedUniversity = (university ?? "").trim().toLowerCase();
  const domain = normalizedEmail.includes("@")
    ? normalizedEmail.split("@").pop() ?? ""
    : "";

  const campusDomainPatterns = [".edu", ".ac.uk", ".edu.gh", ".edu.ng", ".ac.za"];
  const isCampusDomain = campusDomainPatterns.some((pattern) => domain.endsWith(pattern));

  const universityTokens = tokenizeUniversity(normalizedUniversity);
  const domainMatchesUniversity =
    universityTokens.length > 0 &&
    universityTokens.some((token) => domain.includes(token));

  const genericProviders = [
    "gmail.com",
    "yahoo.com",
    "hotmail.com",
    "outlook.com",
    "icloud.com",
    "live.com",
  ];
  const isPersonalEmail = genericProviders.includes(domain);

  let score = 0;
  if (isCampusDomain) score += 2;
  if (domainMatchesUniversity) score += 2;
  if (isPersonalEmail) score -= 2;

  const summary = [
    `Email: ${normalizedEmail || "missing"}`,
    `Profile university: ${normalizedUniversity || "missing"}`,
    `Email domain: ${domain || "missing"}`,
    isCampusDomain ? "Campus-style email domain detected." : "No campus email domain detected.",
    domainMatchesUniversity
      ? "Email domain appears related to the profile university."
      : "Email domain does not clearly match the profile university.",
    isPersonalEmail ? "Personal email provider — manual review recommended." : "",
  ]
    .filter(Boolean)
    .join("\n");

  return { summary, isCampusDomain, domainMatchesUniversity, score };
}

async function fetchIdDocumentBytes(
  env: Env,
  requestId: string,
): Promise<Uint8Array | null> {
  const response = await apiFetch(
    env,
    `/api/admin/verification-requests/${requestId}/id-document`,
  );
  if (!response.ok) return null;
  return new Uint8Array(await response.arrayBuffer());
}

function extractVisionText(result: unknown): string {
  if (typeof result === "object" && result && "description" in result) {
    return String((result as { description?: string }).description ?? result);
  }
  if (typeof result === "object" && result && "response" in result) {
    return String((result as { response?: string }).response ?? result);
  }
  return JSON.stringify(result);
}

const NON_ID_IMAGE_SIGNALS = [
  "not a student",
  "not an id",
  "not a id",
  "is not a student",
  "is not an id",
  "not a university id",
  "not a school id",
  "advertisement",
  "advertising",
  "promotional",
  "promotion",
  "flyer",
  "poster",
  "marketing",
  "jersey",
  "jerseys",
  "football",
  "soccer",
  "product photo",
  "screenshot",
  "meme",
  "whatsapp",
  "social media",
  "banner",
  "logo design",
  "e-commerce",
  "sports graphic",
  "club jersey",
  "eazy",
];

const STUDENT_ID_DESCRIPTION_SIGNALS = [
  "student id",
  "student card",
  "id card",
  "identification card",
  "university card",
  "campus card",
  "school id",
  "university id",
];

function visionLooksLikeNonStudentId(vision: string): boolean {
  const normalized = vision.toLowerCase();
  return NON_ID_IMAGE_SIGNALS.some((signal) => normalized.includes(signal));
}

function visionDescriptionLooksLikeStudentId(description: string): boolean {
  const normalized = description.toLowerCase();
  return STUDENT_ID_DESCRIPTION_SIGNALS.some((signal) => normalized.includes(signal));
}

function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

function parseVisionLine(visionText: string, key: string): string | null {
  const match = visionText.match(new RegExp(`^${key}:\\s*(.+)$`, "im"));
  return match ? match[1].trim() : null;
}

function parseYesNoUnclear(value: string | null): boolean | null {
  if (!value) return null;
  const normalized = value.trim().toLowerCase();
  if (normalized === "yes") return true;
  if (normalized === "no") return false;
  return null;
}

function parseVisionFields(visionText: string): ParsedVisionFields {
  const isStudentIdLine = visionText.match(/IS_STUDENT_ID:\s*(yes|no)/i);
  return {
    rawText: visionText.trim(),
    isStudentIdClaim: isStudentIdLine
      ? isStudentIdLine[1].toLowerCase() === "yes"
      : null,
    whatImageShows: parseVisionLine(visionText, "WHAT_IMAGE_SHOWS"),
    nameOnId: parseVisionLine(visionText, "NAME_ON_ID"),
    universityOnId: parseVisionLine(visionText, "UNIVERSITY_ON_ID"),
    nameMatchesProfile: parseYesNoUnclear(
      parseVisionLine(visionText, "NAME_MATCHES_PROFILE"),
    ),
    universityMatchesProfile: parseYesNoUnclear(
      parseVisionLine(visionText, "UNIVERSITY_MATCHES_PROFILE"),
    ),
  };
}

function isMeaningfulIdField(value: string | null): boolean {
  if (!value) return false;
  const normalized = value.trim().toLowerCase();
  return (
    normalized.length > 0 &&
    !["none", "n/a", "unknown", "not visible"].includes(normalized)
  );
}

function finalizeVisionAssessment(
  fields: ParsedVisionFields,
  item: VerificationRequest,
): IdVisionAssessment {
  const combined = [fields.rawText, fields.whatImageShows ?? ""].join("\n");
  const description = fields.whatImageShows ?? fields.rawText;
  const incomplete =
    !fields.whatImageShows ||
    fields.whatImageShows.length < 12 ||
    fields.isStudentIdClaim === null;

  if (incomplete) {
    return {
      isStudentId: false,
      whatImageShows: fields.whatImageShows,
      nameOnId: fields.nameOnId,
      universityOnId: fields.universityOnId,
      nameMatchesProfile: false,
      universityMatchesProfile: false,
      summary: [
        "Vision could not reliably classify the uploaded image.",
        fields.rawText || "No vision output.",
        "Treat as NOT a verified student ID until an admin reviews the photo.",
      ].join("\n"),
    };
  }

  if (visionLooksLikeNonStudentId(combined)) {
    return {
      isStudentId: false,
      whatImageShows: fields.whatImageShows,
      nameOnId: fields.nameOnId,
      universityOnId: fields.universityOnId,
      nameMatchesProfile: false,
      universityMatchesProfile: false,
      summary: [
        "Uploaded image is NOT a student ID card.",
        `WHAT_IMAGE_SHOWS: ${fields.whatImageShows}`,
        fields.nameOnId ? `NAME_ON_ID: ${fields.nameOnId}` : "",
        fields.universityOnId ? `UNIVERSITY_ON_ID: ${fields.universityOnId}` : "",
      ]
        .filter(Boolean)
        .join("\n"),
    };
  }

  const describesStudentId = visionDescriptionLooksLikeStudentId(description);
  const hasVisibleIdFields =
    isMeaningfulIdField(fields.nameOnId) ||
    isMeaningfulIdField(fields.universityOnId);
  const isStudentId =
    fields.isStudentIdClaim === true &&
    describesStudentId &&
    hasVisibleIdFields &&
    !visionLooksLikeNonStudentId(combined);

  const profileName = (item.userFullName ?? "").trim().toLowerCase();
  const profileUniversity = (item.university ?? "").trim().toLowerCase();

  const nameMatchesProfile =
    isStudentId &&
    (fields.nameMatchesProfile === true ||
      (profileName.length > 0 &&
        isMeaningfulIdField(fields.nameOnId) &&
        fields.nameOnId!.toLowerCase().includes(profileName.split(" ")[0])));

  const universityTokens = tokenizeUniversity(profileUniversity);
  const universityMatchesProfile =
    isStudentId &&
    (fields.universityMatchesProfile === true ||
      (universityTokens.length > 0 &&
        isMeaningfulIdField(fields.universityOnId) &&
        universityTokens.some((token) =>
          fields.universityOnId!.toLowerCase().includes(token),
        )));

  const summary = isStudentId
    ? [
        "Uploaded image appears to be a student/university ID card.",
        `WHAT_IMAGE_SHOWS: ${fields.whatImageShows}`,
        fields.nameOnId ? `NAME_ON_ID: ${fields.nameOnId}` : "",
        fields.universityOnId ? `UNIVERSITY_ON_ID: ${fields.universityOnId}` : "",
        `NAME_MATCHES_PROFILE: ${nameMatchesProfile ? "yes" : "no"}`,
        `UNIVERSITY_MATCHES_PROFILE: ${universityMatchesProfile ? "yes" : "no"}`,
      ]
        .filter(Boolean)
        .join("\n")
    : [
        "Uploaded image does NOT appear to be a student ID card.",
        `WHAT_IMAGE_SHOWS: ${fields.whatImageShows}`,
        fields.isStudentIdClaim
          ? "Model claimed IS_STUDENT_ID: yes — overridden after description check."
          : "IS_STUDENT_ID: no",
      ].join("\n");

  return {
    isStudentId,
    whatImageShows: fields.whatImageShows,
    nameOnId: fields.nameOnId,
    universityOnId: fields.universityOnId,
    nameMatchesProfile,
    universityMatchesProfile,
    summary,
  };
}

async function runVisionPrompt(
  env: Env,
  imageBytes: Uint8Array,
  prompt: string,
): Promise<string> {
  const imageDataUrl = `data:image/jpeg;base64,${bytesToBase64(imageBytes)}`;

  try {
    const result = await env.AI.run(VISION_MODEL_PRIMARY, {
      messages: [
        {
          role: "system",
          content:
            "You verify uploaded photos for a campus marketplace. Be strict. Advertisements, sports graphics, product photos, flyers, jerseys, memes, and screenshots are never student IDs. Only answer yes to IS_STUDENT_ID when you clearly see a physical university/student identification card with school branding.",
        },
        { role: "user", content: prompt },
      ],
      image: imageDataUrl,
      max_tokens: 450,
    });
    return extractVisionText(result);
  } catch {
    const result = await env.AI.run(VISION_MODEL_FALLBACK, {
      image: [...imageBytes],
      prompt,
      max_tokens: 512,
    });
    return extractVisionText(result);
  }
}

async function analyzeStudentIdImage(
  env: Env,
  imageBytes: Uint8Array,
  item: VerificationRequest,
): Promise<IdVisionAssessment> {
  const prompt = [
    "Look at the uploaded image carefully.",
    "Do not assume it is a student ID. Describe what you actually see.",
    `Applicant profile name: ${item.userFullName ?? "unknown"}`,
    `Applicant profile university: ${item.university ?? "unknown"}`,
    "",
    "Reply using exactly these labeled lines:",
    "IS_STUDENT_ID: yes or no",
    "WHAT_IMAGE_SHOWS: one detailed sentence describing the image content (required)",
    "NAME_ON_ID: full name printed on the document, or none",
    "UNIVERSITY_ON_ID: school/university printed on the document, or none",
    "NAME_MATCHES_PROFILE: yes, no, or unclear",
    "UNIVERSITY_MATCHES_PROFILE: yes, no, or unclear",
    "NOTES: fraud or quality concerns",
    "",
    "Examples:",
    "- Sports jersey advertisement -> IS_STUDENT_ID: no",
    "- University photo ID card with student name -> IS_STUDENT_ID: yes",
  ].join("\n");

  try {
    const visionText = await runVisionPrompt(env, imageBytes, prompt);
    const fields = parseVisionFields(visionText);
    return finalizeVisionAssessment(fields, item);
  } catch {
    return {
      isStudentId: false,
      whatImageShows: null,
      summary: "Vision model could not analyze the uploaded image.",
      nameOnId: null,
      universityOnId: null,
      nameMatchesProfile: false,
      universityMatchesProfile: false,
    };
  }
}

function decideHeuristicRecommendation(
  emailCheck: EmailCampusCheck,
  vision: IdVisionAssessment,
  idLoaded: boolean,
): "approve" | "review" {
  if (!idLoaded || !vision.isStudentId) return "review";
  if (visionLooksLikeNonStudentId(vision.summary)) return "review";

  const identityStrong =
    vision.nameMatchesProfile && vision.universityMatchesProfile;
  const campusEmailStrong =
    emailCheck.isCampusDomain && emailCheck.domainMatchesUniversity;

  if (identityStrong && campusEmailStrong) return "approve";
  return "review";
}

function buildFallbackSummary(
  emailCheck: EmailCampusCheck,
  vision: IdVisionAssessment,
  idLoaded: boolean,
  recommendation: "approve" | "review",
): string {
  const idSection = !idLoaded
    ? "Could not load the uploaded image from the API for analysis."
    : !vision.isStudentId
      ? `Uploaded image does not appear to be a student ID.\n${vision.summary}`
      : vision.summary;

  return [
    "Automated seller application review (assist only — admin decides)",
    "",
    "**Email & campus**",
    emailCheck.summary,
    "",
    "**Uploaded document**",
    idSection,
    "",
    `**Recommendation:** ${recommendation}`,
    recommendation === "review"
      ? "Queued for manual admin review."
      : "Strong match — admin may approve quickly.",
  ].join("\n");
}

function synthesizeReview(
  emailCheck: EmailCampusCheck,
  vision: IdVisionAssessment,
  idLoaded: boolean,
): AiReviewResult {
  if (!idLoaded) {
    return {
      recommendation: "review",
      summary: buildFallbackSummary(
        emailCheck,
        vision,
        idLoaded,
        "review",
      ),
    };
  }

  if (!vision.isStudentId || visionLooksLikeNonStudentId(vision.summary)) {
    return {
      recommendation: "review",
      summary: buildFallbackSummary(
        emailCheck,
        vision,
        idLoaded,
        "review",
      ),
    };
  }

  const heuristic = decideHeuristicRecommendation(emailCheck, vision, idLoaded);
  return {
    recommendation: heuristic,
    summary: buildFallbackSummary(emailCheck, vision, idLoaded, heuristic),
  };
}

function applicationEmail(item: VerificationRequest): string | null | undefined {
  return item.studentEmail ?? item.userEmail;
}

async function runAiReview(env: Env, item: VerificationRequest): Promise<AiReviewResult> {
  const emailCheck = assessEmailCampusMatch(applicationEmail(item), item.university);

  let vision: IdVisionAssessment = {
    isStudentId: false,
    summary: "No student ID image was attached.",
    whatImageShows: null,
    nameOnId: null,
    universityOnId: null,
    nameMatchesProfile: false,
    universityMatchesProfile: false,
  };
  let idLoaded = false;

  if (item.idDocumentUrl) {
    const imageBytes = await fetchIdDocumentBytes(env, item.id);
    if (imageBytes && imageBytes.length > 0) {
      idLoaded = true;
      vision = await analyzeStudentIdImage(env, imageBytes, item);
    } else {
      vision = {
        isStudentId: false,
        summary:
          "The API could not provide the uploaded image for vision review. Manual check required.",
        whatImageShows: null,
        nameOnId: null,
        universityOnId: null,
        nameMatchesProfile: false,
        universityMatchesProfile: false,
      };
    }
  }

  if (item.requestType !== "seller_application") {
    return {
      recommendation: "review",
      summary: [
        "Verified badge requests always require manual admin review.",
        emailCheck.summary,
        vision.summary,
      ].join("\n\n"),
    };
  }

  return synthesizeReview(emailCheck, vision, idLoaded);
}

async function persistAiReview(
  env: Env,
  item: VerificationRequest,
  review: AiReviewResult,
): Promise<void> {
  await apiFetch(env, `/api/admin/verification-requests/${item.id}/ai-review`, {
    method: "POST",
    body: JSON.stringify(review),
  });
}

async function processRequestReview(
  env: Env,
  item: VerificationRequest,
): Promise<AiReviewResult> {
  const review = await runAiReview(env, item);
  await persistAiReview(env, item, review);
  return review;
}

async function processPendingReviews(env: Env): Promise<void> {
  const response = await apiFetch(
    env,
    `/api/admin/verification-requests?status=Pending&type=seller_application`,
  );
  if (!response.ok) return;

  const items = (await response.json()) as VerificationRequest[];
  for (const item of items) {
    if (item.aiReviewSummary || item.status !== "Pending") continue;
    await processRequestReview(env, item);
  }
}

export default {
  async scheduled(
    _controller: ScheduledController,
    env: Env,
    ctx: ExecutionContext,
  ): Promise<void> {
    ctx.waitUntil(processPendingReviews(env));
  },

  async fetch(request: Request, env: Env): Promise<Response> {
    if (!env.ADMIN_API_KEY) {
      return new Response("ADMIN_API_KEY secret is not configured.", { status: 500 });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    if (path === "/api/ai-review" && request.method === "GET") {
      return Response.json({
        message:
          "This is a server-only POST endpoint, not a browser page. Open the admin dashboard at / instead.",
        dashboard: `${url.origin}/`,
        postUsage:
          "POST /api/process-request with header X-Admin-Key and body { requestId }",
      });
    }

    if (path === "/api/process-request" && request.method === "POST") {
      if (request.headers.get("X-Admin-Key") !== env.ADMIN_API_KEY) {
        return new Response("Unauthorized", { status: 401 });
      }

      const body = (await request.json()) as { requestId?: string };
      if (!body.requestId) {
        return Response.json({ message: "requestId is required." }, { status: 400 });
      }

      const detailResponse = await apiFetch(
        env,
        `/api/admin/verification-requests/${body.requestId}`,
      );
      if (!detailResponse.ok) {
        return new Response(await detailResponse.text(), {
          status: detailResponse.status,
        });
      }

      const item = (await detailResponse.json()) as VerificationRequest;
      if (item.aiReviewSummary) {
        return Response.json({ ok: true, skipped: true, reason: "already_reviewed" });
      }

      const review = await processRequestReview(env, item);
      return Response.json({ ok: true, review });
    }

    if (path === "/api/ai-review" && request.method === "POST") {
      if (request.headers.get("X-Admin-Key") !== env.ADMIN_API_KEY) {
        return new Response("Unauthorized", { status: 401 });
      }

      const item = (await request.json()) as VerificationRequest;
      const review = await runAiReview(env, item);
      return Response.json(review);
    }

    if (path === "/" || path === "") {
      const status = url.searchParams.get("status") ?? "Pending";
      const type = url.searchParams.get("type");
      const query = new URLSearchParams({ status });
      if (type) query.set("type", type);

      const response = await apiFetch(
        env,
        `/api/admin/verification-requests?${query.toString()}`,
      );
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      const items = (await response.json()) as VerificationRequest[];
      return renderPage(renderDashboard(items));
    }

    const idDocMatch = path.match(/^\/requests\/([^/]+)\/id-document$/);
    if (idDocMatch && request.method === "GET") {
      const response = await apiFetch(
        env,
        `/api/admin/verification-requests/${idDocMatch[1]}/id-document`,
      );
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return new Response(response.body, {
        headers: {
          "content-type": response.headers.get("content-type") ?? "image/jpeg",
          "cache-control": "no-store",
        },
      });
    }

    const detailMatch = path.match(/^\/requests\/([^/]+)$/);
    if (detailMatch && request.method === "GET") {
      const response = await apiFetch(
        env,
        `/api/admin/verification-requests/${detailMatch[1]}`,
      );
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      const item = (await response.json()) as VerificationRequest;
      return renderPage(renderDetail(item));
    }

    const approveMatch = path.match(/^\/requests\/([^/]+)\/approve$/);
    if (approveMatch && request.method === "POST") {
      const response = await apiFetch(
        env,
        `/api/admin/verification-requests/${approveMatch[1]}/approve`,
        { method: "POST" },
      );
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return Response.redirect(`${url.origin}/requests/${approveMatch[1]}`, 303);
    }

    const rejectMatch = path.match(/^\/requests\/([^/]+)\/reject$/);
    if (rejectMatch && request.method === "POST") {
      const form = await request.formData();
      const notes = form.get("notes")?.toString() ?? "";
      const response = await apiFetch(
        env,
        `/api/admin/verification-requests/${rejectMatch[1]}/reject`,
        { method: "POST", body: JSON.stringify({ notes }) },
      );
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return Response.redirect(`${url.origin}/`, 303);
    }

    const aiMatch = path.match(/^\/requests\/([^/]+)\/ai-review$/);
    if (aiMatch && request.method === "POST") {
      const detailResponse = await apiFetch(
        env,
        `/api/admin/verification-requests/${aiMatch[1]}`,
      );
      if (!detailResponse.ok) {
        return new Response(await detailResponse.text(), {
          status: detailResponse.status,
        });
      }
      const item = (await detailResponse.json()) as VerificationRequest;
      await processRequestReview(env, item);

      return Response.redirect(`${url.origin}/requests/${aiMatch[1]}`, 303);
    }

    return new Response("Not found", { status: 404 });
  },
};
