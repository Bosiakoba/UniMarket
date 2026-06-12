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

interface EmailCampusCheck {
  summary: string;
  isCampusDomain: boolean;
  domainMatchesUniversity: boolean;
  score: number;
}

function tokenizeUniversity(value: string): string[] {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((token) => token.length > 2 && !["the", "and", "of", "for"].includes(token));
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

async function analyzeStudentIdImage(
  env: Env,
  imageBytes: Uint8Array,
  item: VerificationRequest,
): Promise<string> {
  const prompt = [
    "You are reviewing a student ID photo for a campus marketplace seller application.",
    `Applicant name on profile: ${item.userFullName ?? "unknown"}`,
    `University on profile: ${item.university ?? "unknown"}`,
    `Campus on profile: ${item.campus ?? "unknown"}`,
    `Applicant email: ${applicationEmail(item) ?? "unknown"}`,
    "Describe:",
    "1) Is this a readable student/university ID card?",
    "2) What full name appears on the ID?",
    "3) What university or school name appears on the ID?",
    "4) Does the ID university match the profile university?",
    "5) Does the ID name match the profile name?",
    "6) Any fraud or quality concerns?",
    "Be concise and factual.",
  ].join("\n");

  try {
    const result = await env.AI.run("@cf/llava-hf/llava-1.5-7b-hf", {
      image: [...imageBytes],
      prompt,
      max_tokens: 512,
    });

    if (typeof result === "object" && result && "description" in result) {
      return String((result as { description?: string }).description ?? result);
    }
    if (typeof result === "object" && result && "response" in result) {
      return String((result as { response?: string }).response ?? result);
    }
    return JSON.stringify(result);
  } catch {
    return "Vision model could not analyze the student ID image.";
  }
}

async function synthesizeReview(
  env: Env,
  item: VerificationRequest,
  emailCheck: EmailCampusCheck,
  visionAnalysis: string,
  idLoaded: boolean,
): Promise<AiReviewResult> {
  const prompt = [
    "You are the automated reviewer for a campus marketplace seller application.",
    "Return ONLY valid JSON with this shape:",
    '{"recommendation":"approve"|"review","summary":"markdown bullet summary"}',
    "",
    "Rules:",
    "- recommendation must be approve ONLY when the student ID is readable, looks genuine,",
    "  the university on the ID matches the profile university, and the name on the ID matches the profile name.",
    "- If email is a personal provider (gmail/outlook/etc), still approve when ID + university + name strongly match.",
    "- Otherwise use review for manual admin check.",
    "- Never recommend reject; admins handle rejection.",
    "",
    `Applicant: ${item.userFullName ?? "unknown"} (${applicationEmail(item) ?? "no email"})`,
    `Profile university: ${item.university ?? "unknown"} · campus: ${item.campus ?? "unknown"}`,
    `Store name: ${item.storeName ?? "n/a"}`,
    `ID image loaded: ${idLoaded ? "yes" : "no"}`,
    "",
    "Email / campus check:",
    emailCheck.summary,
    "",
    "Student ID vision analysis:",
    visionAnalysis,
  ].join("\n");

  try {
    const result = await env.AI.run("@cf/meta/llama-3.1-8b-instruct", {
      messages: [{ role: "user", content: prompt }],
    });

    const text =
      typeof result === "object" && result && "response" in result
        ? String((result as { response?: string }).response ?? "")
        : JSON.stringify(result);

    const jsonMatch = text.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]) as {
        recommendation?: string;
        summary?: string;
      };
      const recommendation =
        parsed.recommendation?.toLowerCase() === "approve" ? "approve" : "review";
      const summary =
        typeof parsed.summary === "string" && parsed.summary.trim().length > 0
          ? parsed.summary.trim()
          : buildFallbackSummary(emailCheck, visionAnalysis, idLoaded, recommendation);
      return { summary, recommendation };
    }
  } catch {
    // fall through to heuristic review
  }

  const heuristic = decideHeuristicRecommendation(
    emailCheck,
    visionAnalysis,
    idLoaded,
  );
  return {
    recommendation: heuristic,
    summary: buildFallbackSummary(emailCheck, visionAnalysis, idLoaded, heuristic),
  };
}

function decideHeuristicRecommendation(
  emailCheck: EmailCampusCheck,
  visionAnalysis: string,
  idLoaded: boolean,
): "approve" | "review" {
  if (!idLoaded) return "review";

  const vision = visionAnalysis.toLowerCase();
  if (
    vision.includes("not a student") ||
    vision.includes("not an id") ||
    vision.includes("could not analyze")
  ) {
    return "review";
  }

  const idReadable =
    !vision.includes("unreadable") &&
    (vision.includes("student") ||
      vision.includes("id card") ||
      vision.includes("university"));

  const universityMatches =
    vision.includes("university") &&
    (vision.includes("match") ||
      vision.includes("same") ||
      vision.includes("consistent"));

  const nameMatches =
    vision.includes("name") &&
    (vision.includes("match") ||
      vision.includes("same") ||
      vision.includes("consistent"));

  const identityStrong = idReadable && universityMatches && nameMatches;
  const campusEmailStrong =
    emailCheck.isCampusDomain && emailCheck.domainMatchesUniversity;

  if (identityStrong && campusEmailStrong) return "approve";
  if (identityStrong && emailCheck.isCampusDomain) return "approve";
  if (identityStrong) return "approve";

  return "review";
}

function buildFallbackSummary(
  emailCheck: EmailCampusCheck,
  visionAnalysis: string,
  idLoaded: boolean,
  recommendation: "approve" | "review",
): string {
  return [
    "Automated seller application review",
    "",
    "**Email & campus**",
    emailCheck.summary,
    "",
    "**Student ID image**",
    idLoaded
      ? visionAnalysis
      : "Could not load the ID image from the API for analysis.",
    "",
    `**Recommendation:** ${recommendation}`,
    recommendation === "review"
      ? "Queued for manual admin review."
      : "Checks passed — auto-approval eligible.",
  ].join("\n");
}

function applicationEmail(item: VerificationRequest): string | null | undefined {
  return item.studentEmail ?? item.userEmail;
}

async function runAiReview(env: Env, item: VerificationRequest): Promise<AiReviewResult> {
  const emailCheck = assessEmailCampusMatch(applicationEmail(item), item.university);

  let visionAnalysis = "No student ID was attached.";
  let idLoaded = false;

  if (item.idDocumentUrl) {
    const imageBytes = await fetchIdDocumentBytes(env, item.id);
    if (imageBytes && imageBytes.length > 0) {
      idLoaded = true;
      visionAnalysis = await analyzeStudentIdImage(env, imageBytes, item);
    } else {
      visionAnalysis =
        "The API could not provide the student ID image for vision review. Manual check required.";
    }
  }

  if (item.requestType !== "seller_application") {
    return {
      recommendation: "review",
      summary: [
        "Verified badge requests always require manual admin review.",
        emailCheck.summary,
        visionAnalysis,
      ].join("\n\n"),
    };
  }

  return synthesizeReview(env, item, emailCheck, visionAnalysis, idLoaded);
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (!env.ADMIN_API_KEY) {
      return new Response("ADMIN_API_KEY secret is not configured.", { status: 500 });
    }

    const url = new URL(request.url);
    const path = url.pathname;

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
      const review = await runAiReview(env, item);

      await apiFetch(
        env,
        `/api/admin/verification-requests/${aiMatch[1]}/ai-review`,
        {
          method: "POST",
          body: JSON.stringify(review),
        },
      );

      if (
        review.recommendation === "approve" &&
        item.requestType === "seller_application" &&
        item.status === "Pending"
      ) {
        await apiFetch(
          env,
          `/api/admin/verification-requests/${aiMatch[1]}/approve`,
          { method: "POST" },
        );
      }

      return Response.redirect(`${url.origin}/requests/${aiMatch[1]}`, 303);
    }

    return new Response("Not found", { status: 404 });
  },
};
