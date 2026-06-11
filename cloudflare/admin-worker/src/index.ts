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
    ? `<img class="doc" src="${escapeAttr(item.idDocumentUrl)}" alt="ID document" />`
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

async function runAiReview(env: Env, item: VerificationRequest): Promise<string> {
  const prompt = [
    "You are reviewing a campus marketplace seller verification request.",
    `Request type: ${item.requestType}`,
    `Applicant: ${item.userFullName ?? "unknown"} (${item.userEmail ?? "no email"})`,
    `University: ${item.university ?? "unknown"}, campus: ${item.campus ?? "unknown"}`,
    `Store name: ${item.storeName ?? "n/a"}`,
    item.idDocumentUrl
      ? `ID document URL: ${item.idDocumentUrl}`
      : "No ID document was uploaded.",
    "Summarize risk signals and recommend approve, review, or reject.",
  ].join("\n");

  try {
    const result = await env.AI.run("@cf/meta/llama-3.1-8b-instruct", {
      messages: [{ role: "user", content: prompt }],
    });
    if (typeof result === "object" && result && "response" in result) {
      return String((result as { response?: string }).response ?? result);
    }
    return JSON.stringify(result);
  } catch {
    return [
      "AI review unavailable from this environment.",
      "Checklist:",
      "- Campus email domain matches university",
      "- Student ID image is readable",
      "- Store name looks legitimate",
      "Recommendation: review",
    ].join("\n");
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    if (!env.ADMIN_API_KEY) {
      return new Response("ADMIN_API_KEY secret is not configured.", { status: 500 });
    }

    const url = new URL(request.url);
    const path = url.pathname;

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
      const summary = await runAiReview(env, item);
      const recommendation = summary.toLowerCase().includes("reject")
        ? "reject"
        : summary.toLowerCase().includes("approve")
          ? "approve"
          : "review";

      await apiFetch(
        env,
        `/api/admin/verification-requests/${aiMatch[1]}/ai-review`,
        {
          method: "POST",
          body: JSON.stringify({ summary, recommendation }),
        },
      );

      return Response.redirect(`${url.origin}/requests/${aiMatch[1]}`, 303);
    }

    return new Response("Not found", { status: 404 });
  },
};
