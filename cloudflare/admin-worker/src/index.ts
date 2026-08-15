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

interface CarouselBanner {
  id: string;
  title: string;
  subtitle: string;
  imageUrl: string;
  routePath: string;
  createdAt: string;
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

function renderPage(body: string, activeTab: string): Response {
  const html = `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>UniMarket Admin</title>
  <script src="https://unpkg.com/lucide@latest"></script>
  <style>
    :root {
      --green: #1f6b4a;
      --green-light: #eef6f1;
      --bg: #f4f6f5;
      --card: #ffffff;
      --text: #12221b;
      --muted: #66776f;
      --border: #e8ecea;
      --red: #b42318;
      --red-light: #fef3f2;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background: var(--bg);
      color: var(--text);
      min-height: 100vh;
    }
    .app-layout {
      display: flex;
      width: 100%;
      min-height: 100vh;
    }
    .sidebar {
      width: 260px;
      background: #ffffff;
      border-right: 1px solid var(--border);
      display: flex;
      flex-direction: column;
      padding: 24px;
      position: fixed;
      top: 0;
      bottom: 0;
      left: 0;
    }
    .sidebar-header h2 {
      color: var(--green);
      margin: 0;
      font-size: 20px;
      font-weight: 700;
    }
    .sidebar-header p {
      margin: 4px 0 24px 0;
      font-size: 13px;
    }
    .sidebar-nav {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    .nav-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 12px 16px;
      color: var(--text);
      text-decoration: none;
      font-weight: 600;
      border-radius: 10px;
      transition: all 0.2s;
    }
    .nav-item:hover {
      background: var(--bg);
    }
    .nav-item.active {
      background: var(--green-light);
      color: var(--green);
    }
    .nav-item .icon {
      width: 18px;
      height: 18px;
      stroke-width: 2.5px;
    }
    .content {
      flex: 1;
      padding: 40px;
      margin-left: 260px;
      max-width: 1400px;
      min-height: 100vh;
    }
    .card { background:var(--card); border-radius:16px; padding:24px; box-shadow:0 8px 24px rgba(0,0,0,.04); border: 1px solid var(--border); }
    table { width:100%; border-collapse:collapse; margin-top:16px; }
    th, td { text-align:left; padding:16px 12px; border-bottom:1px solid var(--border); vertical-align:middle; }
    th { font-size:12px; text-transform:uppercase; letter-spacing:.04em; color:var(--muted); font-weight:600; }
    a { color:var(--green); text-decoration:none; font-weight: 600; }
    a:hover { text-decoration: underline; }
    .muted { color:var(--muted); font-size:13px; }
    .pill { display:inline-block; padding:6px 12px; border-radius:999px; font-size:12px; font-weight:600; text-align:center; }
    .pill-green { background:var(--green-light); color:var(--green); }
    .pill-red { background:var(--red-light); color:var(--red); }
    .pill-yellow { background:#fffbeb; color:#d97706; }
    .pill-gray { background:#f3f4f6; color:#4b5563; }
    .toolbar { display:flex; gap:12px; flex-wrap:wrap; margin-bottom:20px; align-items:center; }
    button, .btn { border:0; border-radius:10px; padding:10px 18px; cursor:pointer; font-weight:600; display:inline-flex; align-items:center; justify-content:center; font-size:14px; transition: all 0.15s; }
    .btn-green { background:var(--green); color:#fff; }
    .btn-green:hover { background:#165137; }
    .btn-red { background:var(--red); color:#fff; }
    .btn-red:hover { background:#911810; }
    .btn-light { background:#e8ecea; color:#122; border: 1px solid var(--border); }
    .btn-light:hover { background:#d8dedb; }
    img.doc { max-width:100%; border-radius:12px; border:1px solid #dde3df; margin-top: 12px; }
    pre.ai { white-space:pre-wrap; background:#f8faf9; padding:16px; border-radius:12px; border:1px solid var(--border); font-family: monospace; font-size:14px; line-height:1.5; }
    .title-row { margin-bottom:24px; }
    .title-row h1 { margin:0; font-size:28px; font-weight:700; color:var(--green); }
    .form-group { margin-bottom: 20px; }
    .form-group label { display:block; font-weight:600; margin-bottom:8px; font-size:14px; }
    textarea, input[type="text"] { width:100%; border-radius:10px; border:1px solid #ccd4cf; padding:12px; font-family:inherit; font-size:14px; }
    textarea:focus, input[type="text"]:focus { outline:none; border-color:var(--green); }
  </style>
</head>
<body>
  <div class="app-layout">
    <aside class="sidebar">
      <div class="sidebar-header">
        <h2>UniMarket Admin</h2>
        <p class="muted">App Moderation & Queue</p>
      </div>
      <nav class="sidebar-nav">
        <a href="/" class="nav-item ${activeTab === 'verifications' ? 'active' : ''}">
          <i data-lucide="check-square" class="icon"></i> Queue
        </a>
        <a href="/reports" class="nav-item ${activeTab === 'reports' ? 'active' : ''}">
          <i data-lucide="alert-triangle" class="icon"></i> Reports
        </a>
        <a href="/users" class="nav-item ${activeTab === 'users' ? 'active' : ''}">
          <i data-lucide="users" class="icon"></i> Users
        </a>
        <a href="/listings" class="nav-item ${activeTab === 'listings' ? 'active' : ''}">
          <i data-lucide="shopping-bag" class="icon"></i> Listings
        </a>
        <a href="/appeals" class="nav-item ${activeTab === 'appeals' ? 'active' : ''}">
          <i data-lucide="message-square" class="icon"></i> Appeals
        </a>
        <a href="/campaigns" class="nav-item ${activeTab === 'campaigns' ? 'active' : ''}">
          <i data-lucide="mail" class="icon"></i> Campaigns
        </a>
        <a href="/banners" class="nav-item ${activeTab === 'banners' ? 'active' : ''}">
          <i data-lucide="image" class="icon"></i> Banners
        </a>
      </nav>
    </aside>
    <main class="content">
      ${body}
    </main>
  </div>
  <script>
    lucide.createIcons();
  </script>
</body>
</html>`;
  return new Response(html, {
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
      let statusClass = "pill-yellow";
      if (item.status === "Approved") statusClass = "pill-green";
      else if (item.status === "Rejected") statusClass = "pill-red";

      return `<tr>
        <td><a href="/requests/${item.id}">${escapeHtml(labelForType(item.requestType))}</a></td>
        <td>${escapeHtml(item.userFullName ?? "—")}<br><span class="muted">${escapeHtml(item.userEmail ?? "")}</span></td>
        <td>${escapeHtml(item.storeName ?? "—")}</td>
        <td><span class="pill ${statusClass}">${escapeHtml(item.status)}</span></td>
        <td>${escapeHtml(submitted)}</td>
      </tr>`;
    })
    .join("");

  return `
    <div class="title-row">
      <h1>Verification Queue</h1>
    </div>
    <div class="toolbar">
      <a class="btn btn-light" href="/?status=Pending">Pending</a>
      <a class="btn btn-light" href="/?status=Approved">Approved</a>
      <a class="btn btn-light" href="/?status=Rejected">Rejected</a>
      <a class="btn btn-light" href="/?type=seller_application">Seller apps</a>
      <a class="btn btn-light" href="/?type=verified_badge">Badge requests</a>
    </div>
    <div class="card">
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
          ${rows || `<tr><td colspan="5" class="muted" style="text-align:center">No requests in this view.</td></tr>`}
        </tbody>
      </table>
    </div>
  `;
}

interface AdminReport {
  id: string;
  listingId: string;
  listingTitle: string;
  reporterUserId: string;
  reporterName: string;
  reason: string;
  comment: string;
  status: string;
  createdAt: string;
}

function renderReports(reports: AdminReport[]): string {
  const rows = reports.map(r => {
    const isResolved = r.status === "Resolved";
    const statusPill = isResolved ? `<span class="pill pill-green">Resolved</span>` : `<span class="pill pill-yellow">Pending</span>`;
    return `<tr>
      <td><strong>${escapeHtml(r.listingTitle)}</strong><br><span class="muted">ID: ${escapeHtml(r.listingId)}</span></td>
      <td>${escapeHtml(r.reporterName)}<br><span class="muted">ID: ${escapeHtml(r.reporterUserId)}</span></td>
      <td><strong>${escapeHtml(r.reason)}</strong></td>
      <td>${escapeHtml(r.comment || "—")}</td>
      <td>${statusPill}</td>
      <td>
        <div style="display:flex; gap:8px;">
          ${!isResolved ? `
            <form method="post" action="/reports/${r.id}/resolve" style="margin:0">
              <button class="btn btn-light" type="submit">Resolve</button>
            </form>
            <button class="btn btn-red" onclick="suspendListing('${r.listingId}', '${escapeAttr(r.listingTitle)}')">Suspend Product</button>
          ` : '—'}
        </div>
      </td>
    </tr>`;
  }).join("");

  return `
    <div class="title-row">
      <h1>Listing Reports Moderation</h1>
    </div>
    <div class="card">
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Reporter</th>
            <th>Reason</th>
            <th>Comment</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${rows || '<tr><td colspan="6" class="muted" style="text-align:center">No reports received.</td></tr>'}
        </tbody>
      </table>
    </div>
    <script>
      function suspendListing(id, title) {
        const reason = prompt("Enter suspension reason to notify the seller:");
        if (reason === null) return;
        
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = '/listings/' + id + '/suspend?from=reports&reason=' + encodeURIComponent(reason);
        document.body.appendChild(form);
        form.submit();
      }
    </script>
  `;
}

interface AdminUser {
  id: string;
  fullName: string;
  email: string;
  role: string;
  isSeller: boolean;
  isVerified: boolean;
  isSuspended: boolean;
  createdAt: string;
}

function renderUsers(users: AdminUser[]): string {
  const rows = users.map(u => {
    const statusPill = u.isSuspended 
      ? `<span class="pill pill-red">Suspended</span>` 
      : `<span class="pill pill-green">Active</span>`;
    
    const rolePill = u.role === "Admin"
      ? `<span class="pill pill-green">Admin</span>`
      : `<span class="pill pill-gray">${escapeHtml(u.role)}</span>`;

    const badges = [];
    if (u.isSeller) badges.push(`<span class="pill pill-green" style="font-size:10px; padding:2px 6px;">Seller</span>`);
    if (u.isVerified) badges.push(`<span class="pill pill-green" style="font-size:10px; padding:2px 6px;">Verified Badge</span>`);
    
    return `<tr>
      <td><strong>${escapeHtml(u.fullName)}</strong><br><span class="muted">${escapeHtml(u.email)}</span></td>
      <td>${rolePill}</td>
      <td>${badges.join(" ") || "—"}</td>
      <td>${statusPill}</td>
      <td>${new Date(u.createdAt).toLocaleDateString()}</td>
      <td>
        ${u.role !== "Admin" ? (u.isSuspended ? `
          <form method="post" action="/users/${u.id}/unsuspend" style="margin:0">
            <button class="btn btn-green" type="submit">Unsuspend</button>
          </form>
        ` : `
          <button class="btn btn-red" onclick="suspendUser('${u.id}', '${escapeAttr(u.fullName)}')">Suspend</button>
        `) : '—'}
      </td>
    </tr>`;
  }).join("");

  return `
    <div class="title-row">
      <h1>Users Directory</h1>
    </div>
    <div class="card">
      <table>
        <thead>
          <tr>
            <th>User</th>
            <th>Role</th>
            <th>Badges</th>
            <th>Status</th>
            <th>Joined</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          ${rows || '<tr><td colspan="6" class="muted" style="text-align:center">No users registered.</td></tr>'}
        </tbody>
      </table>
    </div>
    <script>
      function suspendUser(id, name) {
        const reason = prompt("Enter account suspension reason to email " + name + ":");
        if (reason === null) return;
        
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = '/users/' + id + '/suspend?reason=' + encodeURIComponent(reason);
        document.body.appendChild(form);
        form.submit();
      }
    </script>
  `;
}

interface AdminListing {
  id: string;
  title: string;
  price: number;
  status: string;
  views: number;
  createdAt: string;
  sellerName: string;
  sellerEmail: string;
  appealComment?: string;
}

function renderListings(listings: AdminListing[]): string {
  const rows = listings.map(l => {
    let statusPill = `<span class="pill pill-green">${escapeHtml(l.status)}</span>`;
    if (l.status === "suspended") {
      statusPill = `<span class="pill pill-red">Suspended</span>`;
      if (l.appealComment) {
        statusPill += `<br><span class="pill pill-yellow" style="margin-top: 4px; display: inline-block;">Appeal Pending</span>`;
      }
    }
    else if (l.status !== "active") statusPill = `<span class="pill pill-gray">${escapeHtml(l.status)}</span>`;

    return `<tr>
      <td>
        <strong>${escapeHtml(l.title)}</strong><br>
        <span class="muted">ID: ${escapeHtml(l.id)}</span>
        ${l.appealComment ? `
          <div style="margin-top: 8px; padding: 10px 14px; background: #fff9db; border: 1px solid #ffe3a3; border-radius: 8px; font-size: 13px; color: #7a5000;">
            <strong>Appeal Comment:</strong> "${escapeHtml(l.appealComment)}"
          </div>
        ` : ''}
      </td>
      <td>GH₵${l.price.toFixed(2)}</td>
      <td>${escapeHtml(l.sellerName)}<br><span class="muted">${escapeHtml(l.sellerEmail)}</span></td>
      <td><strong>${l.views}</strong> views</td>
      <td>${statusPill}</td>
      <td>${new Date(l.createdAt).toLocaleDateString()}</td>
      <td>
        ${l.status === "suspended" ? `
          <form method="post" action="/listings/${l.id}/unsuspend" style="margin:0">
            <button class="btn btn-green" type="submit">Approve Appeal / Reinstate</button>
          </form>
        ` : `
          <button class="btn btn-red" onclick="suspendListing('${l.id}', '${escapeAttr(l.title)}')">Suspend</button>
        `}
      </td>
    </tr>`;
  }).join("");

  return `
    <div class="title-row">
      <h1>Listings (Products) Directory</h1>
    </div>
    <div class="card">
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Price</th>
            <th>Seller</th>
            <th>Views</th>
            <th>Status</th>
            <th>Created</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          ${rows || '<tr><td colspan="7" class="muted" style="text-align:center">No listings found.</td></tr>'}
        </tbody>
      </table>
    </div>
    <script>
      function suspendListing(id, title) {
        const reason = prompt("Enter suspension reason to notify the seller:");
        if (reason === null) return;
        
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = '/listings/' + id + '/suspend?reason=' + encodeURIComponent(reason);
        document.body.appendChild(form);
        form.submit();
      }
    </script>
  `;
}

function renderAppeals(listings: AdminListing[]): string {
  const appeals = listings.filter(l => l.status === "suspended" && l.appealComment);
  const rows = appeals.map(l => {
    return `<tr>
      <td>
        <strong>${escapeHtml(l.title)}</strong><br>
        <span class="muted">ID: ${escapeHtml(l.id)}</span>
      </td>
      <td>GH₵${l.price.toFixed(2)}</td>
      <td>${escapeHtml(l.sellerName)}<br><span class="muted">${escapeHtml(l.sellerEmail)}</span></td>
      <td>
        <div style="padding: 10px 14px; background: #fff9db; border: 1px solid #ffe3a3; border-radius: 8px; font-size: 13px; color: #7a5000;">
          "${escapeHtml(l.appealComment!)}"
        </div>
      </td>
      <td>${new Date(l.createdAt).toLocaleDateString()}</td>
      <td>
        <form method="post" action="/listings/${l.id}/unsuspend?from=appeals" style="margin:0">
          <button class="btn btn-green" type="submit">Approve Appeal / Reinstate</button>
        </form>
      </td>
    </tr>`;
  }).join("");

  return `
    <div class="title-row">
      <h1>Listing Appeals Panel</h1>
    </div>
    <div class="card">
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Price</th>
            <th>Seller</th>
            <th>Appeal Explanation</th>
            <th>Created</th>
            <th>Action</th>
          </tr>
        </thead>
        <tbody>
          ${rows || '<tr><td colspan="6" class="muted" style="text-align:center">No pending listing appeals found.</td></tr>'}
        </tbody>
      </table>
    </div>
  `;
}

function renderCampaigns(): string {
  return `
    <div class="title-row">
      <h1>Launch Email Campaign</h1>
    </div>
    <div class="card" style="max-width: 700px;">
      <p class="muted" style="margin-top:0; margin-bottom:24px;">Send a targeted campaign email to all active, non-suspended users in the system. The emails will be styled with our clean, editorial template.</p>
      <form method="post" action="/campaigns/send">
        <div class="form-group">
          <label>Campaign Subject</label>
          <input type="text" name="subject" required placeholder="e.g. Campus Safety Updates & Guidelines" />
        </div>
        <div class="form-group">
          <label>Email Body (HTML supported)</label>
          <textarea name="htmlBody" required style="min-height: 250px;" placeholder="<p>Write your email campaign content here...</p>"></textarea>
        </div>
        <button class="btn btn-green" type="submit">Send Campaign to All Users</button>
      </form>
    </div>
  `;
}

function renderBanners(banners: CarouselBanner[]): string {
  const rows = banners
    .map((b) => {
      const created = new Date(b.createdAt).toLocaleString();
      return `<tr>
        <td>
          <img src="${escapeAttr(b.imageUrl)}" alt="" style="width:80px; height:48px; object-fit:cover; border-radius:8px; border:1px solid var(--border);" onerror="this.style.display='none'" />
        </td>
        <td><strong>${escapeHtml(b.title)}</strong><br><span class="muted">${escapeHtml(b.subtitle || '—')}</span></td>
        <td><code style="font-size:12px; background:#f3f4f6; padding:4px 8px; border-radius:6px;">${escapeHtml(b.routePath || 'none')}</code></td>
        <td class="muted">${escapeHtml(created)}</td>
        <td>
          <a href="/banners/${escapeAttr(b.id)}/edit" class="btn btn-light" style="margin-right:8px; text-decoration:none;">Edit</a>
          <form method="post" action="/banners/${escapeAttr(b.id)}/delete" style="display:inline;" onsubmit="return confirm('Delete this banner?')">
            <button class="btn btn-red" type="submit">Delete</button>
          </form>
        </td>
      </tr>`;
    })
    .join("");

  return `
    <div class="title-row">
      <h1>Carousel Banners</h1>
    </div>
    <div class="toolbar">
      <a href="/banners/create" class="btn btn-green" style="color:#fff; text-decoration:none;">+ New Banner</a>
    </div>
    <div class="card">
      <table>
        <thead>
          <tr>
            <th style="width:100px">Image</th>
            <th>Title / Subtitle</th>
            <th>Route</th>
            <th>Created</th>
            <th style="width:200px">Actions</th>
          </tr>
        </thead>
        <tbody>
          ${rows || '<tr><td colspan="5" class="muted" style="text-align:center">No banners yet. Create one to get started.</td></tr>'}
        </tbody>
      </table>
    </div>
  `;
}

function renderBannerForm(banner?: CarouselBanner): string {
  const isEdit = !!banner;
  const title = isEdit ? 'Edit Banner' : 'Create Banner';
  const action = isEdit ? `/banners/${banner!.id}/update` : '/banners/create';

  return `
    <div class="title-row">
      <p><a href="/banners">← Back to banners</a></p>
      <h1>${title}</h1>
    </div>
    <div class="card" style="max-width: 700px;">
      <form method="post" action="${action}">
        <div class="form-group">
          <label>Title *</label>
          <input type="text" name="title" required value="${escapeAttr(banner?.title ?? '')}" placeholder="e.g. Get Verified Today!" />
        </div>
        <div class="form-group">
          <label>Subtitle</label>
          <input type="text" name="subtitle" value="${escapeAttr(banner?.subtitle ?? '')}" placeholder="e.g. Boost your sales with a verified badge" />
        </div>
        <div class="form-group">
          <label>Image URL *</label>
          <input type="text" name="imageUrl" required value="${escapeAttr(banner?.imageUrl ?? '')}" placeholder="https://example.com/banner.jpg" />
          ${banner?.imageUrl ? `<img src="${escapeAttr(banner.imageUrl)}" alt="Preview" style="margin-top:12px; max-width:100%; max-height:200px; border-radius:12px; border:1px solid var(--border);" onerror="this.style.display='none'" />` : ''}
        </div>
        <div class="form-group">
          <label>Route Path</label>
          <input type="text" name="routePath" value="${escapeAttr(banner?.routePath ?? '')}" placeholder="e.g. /verification-benefits or https://..." />
          <p class="muted" style="margin-top:4px; font-size:12px;">Internal app route (e.g. /verification-benefits) or external URL. Leave empty to make the banner non-clickable.</p>
        </div>
        <button class="btn btn-green" type="submit">${isEdit ? 'Save Changes' : 'Create Banner'}</button>
      </form>
    </div>
  `;
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

  return `
    <div class="title-row">
      <p><a href="/">← Back to queue</a></p>
      <h1>Review ${escapeHtml(labelForType(item.requestType))}</h1>
      <p class="muted">${escapeHtml(item.userFullName ?? "")} · ${escapeHtml(item.userEmail ?? "")}</p>
    </div>
    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:24px;">
      <div>
        <section class="card" style="margin-bottom: 24px;">
          <h2>Applicant Details</h2>
          <p><strong>Campus:</strong> ${escapeHtml(item.university ?? "—")} · ${escapeHtml(item.campus ?? "—")}</p>
          <p><strong>Student email:</strong> ${escapeHtml(item.studentEmail ?? item.userEmail ?? "—")}</p>
          <p><strong>Store:</strong> ${escapeHtml(item.storeName ?? "—")}</p>
          <p><strong>Status:</strong> ${escapeHtml(item.status)}</p>
        </section>
        <section class="card">
          <h2>AI Assistant</h2>
          <p class="muted">Starts within seconds of submit. High-confidence rejections are automatic; uncertain cases stay in the manual queue.</p>
          ${aiBlock}
          <form method="post" action="/requests/${escapeAttr(item.id)}/ai-review" style="margin-top:16px">
            <button class="btn btn-light" type="submit">Run Workers AI review</button>
          </form>
        </section>
      </div>
      <div>
        <section class="card" style="margin-bottom: 24px;">
          <h2>Student ID Card</h2>
          ${doc}
        </section>
        <section class="card">
          <h2>Decision</h2>
          <form method="post" action="/requests/${escapeAttr(item.id)}/reject" style="margin-bottom:16px">
            <label class="muted" style="display:block; margin-bottom:8px; font-weight:600;">Notes (optional, emailed to user)</label>
            <textarea name="notes" placeholder="Reason if rejecting…"></textarea>
            <div style="margin-top:12px">
              <button class="btn btn-red" type="submit">Reject</button>
            </div>
          </form>
          <form method="post" action="/requests/${escapeAttr(item.id)}/approve">
            <div>
              <button class="btn btn-green" type="submit">Approve</button>
            </div>
          </form>
        </section>
      </div>
    </div>
  `;
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
  recommendation: "approve" | "review" | "reject";
  confidence: "high" | "low";
}

interface IdVisionAssessment {
  isStudentId: boolean;
  confidence: "high" | "low";
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
  const stopWords = new Set(["the", "of", "for", "at", "in"]);
  const words = value
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((token) => token.length > 2 && !stopWords.has(token));

  const tokens = [...words];
  const acronym = value
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .split(/\s+/)
    .filter((word) => word.length > 0 && !stopWords.has(word))
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
  "does not appear to be a student id",
  "does not appear to be a student",
  "advertisement",
  "advertising",
  "promotional",
  "promotion",
  "promotional material",
  "flyer",
  "poster",
  "marketing",
  "tournament",
  "bracket",
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

function normalizeVisionText(visionText: string): string {
  return visionText
    .replace(/\*\*/g, "")
    .replace(/^[-*]\s+/gm, "")
    .trim();
}

function parseVisionLine(visionText: string, key: string): string | null {
  const normalized = normalizeVisionText(visionText);
  const lineMatch = normalized.match(new RegExp(`^${key}:\\s*(.+)$`, "im"));
  if (lineMatch) return lineMatch[1].trim();

  const inlineMatch = normalized.match(
    new RegExp(`${key}:\\s*(.+?)(?:\\n|$)`, "i"),
  );
  return inlineMatch ? inlineMatch[1].trim() : null;
}

function parseYesNoUnclear(value: string | null): boolean | null {
  if (!value) return null;
  const normalized = value.trim().toLowerCase();
  if (normalized === "yes") return true;
  if (normalized === "no") return false;
  return null;
}

function parseIsStudentIdClaim(visionText: string): boolean | null {
  const normalized = normalizeVisionText(visionText);
  const match = normalized.match(/IS_STUDENT_ID:\s*(yes|no)\b/i);
  if (!match) return null;
  return match[1].toLowerCase() === "yes";
}

function parseVisionFields(visionText: string): ParsedVisionFields {
  const rawText = visionText.trim();
  return {
    rawText,
    isStudentIdClaim: parseIsStudentIdClaim(rawText),
    whatImageShows: parseVisionLine(rawText, "WHAT_IMAGE_SHOWS"),
    nameOnId: parseVisionLine(rawText, "NAME_ON_ID"),
    universityOnId: parseVisionLine(rawText, "UNIVERSITY_ON_ID"),
    nameMatchesProfile: parseYesNoUnclear(
      parseVisionLine(rawText, "NAME_MATCHES_PROFILE"),
    ),
    universityMatchesProfile: parseYesNoUnclear(
      parseVisionLine(rawText, "UNIVERSITY_MATCHES_PROFILE"),
    ),
  };
}

function buildNonIdAssessment(
  fields: ParsedVisionFields,
  summaryLines: string[],
): IdVisionAssessment {
  return {
    isStudentId: false,
    confidence: "high",
    whatImageShows: fields.whatImageShows,
    nameOnId: fields.nameOnId,
    universityOnId: fields.universityOnId,
    nameMatchesProfile: false,
    universityMatchesProfile: false,
    summary: summaryLines.filter(Boolean).join("\n"),
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
  const explicitNotStudentId = fields.isStudentIdClaim === false;
  const incomplete =
    !fields.whatImageShows ||
    fields.whatImageShows.length < 12 ||
    fields.isStudentIdClaim === null;

  if (explicitNotStudentId && visionLooksLikeNonStudentId(combined)) {
    return buildNonIdAssessment(fields, [
      "Uploaded image is NOT a student ID card.",
      fields.whatImageShows
        ? `WHAT_IMAGE_SHOWS: ${fields.whatImageShows}`
        : fields.rawText,
      fields.nameOnId ? `NAME_ON_ID: ${fields.nameOnId}` : "",
      fields.universityOnId ? `UNIVERSITY_ON_ID: ${fields.universityOnId}` : "",
    ]);
  }

  if (incomplete) {
    if (explicitNotStudentId) {
      return buildNonIdAssessment(fields, [
        "Uploaded image is NOT a student ID card.",
        fields.whatImageShows
          ? `WHAT_IMAGE_SHOWS: ${fields.whatImageShows}`
          : fields.rawText,
      ]);
    }

    return {
      isStudentId: false,
      confidence: "low",
      whatImageShows: fields.whatImageShows,
      nameOnId: fields.nameOnId,
      universityOnId: fields.universityOnId,
      nameMatchesProfile: false,
      universityMatchesProfile: false,
      summary: [
        "Vision could not reliably classify the uploaded image.",
        fields.rawText || "No vision output.",
        "Manual admin review required.",
      ].join("\n"),
    };
  }

  if (visionLooksLikeNonStudentId(combined)) {
    return buildNonIdAssessment(fields, [
      "Uploaded image is NOT a student ID card.",
      `WHAT_IMAGE_SHOWS: ${fields.whatImageShows}`,
      fields.nameOnId ? `NAME_ON_ID: ${fields.nameOnId}` : "",
      fields.universityOnId ? `UNIVERSITY_ON_ID: ${fields.universityOnId}` : "",
    ]);
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

  const confidence: "high" | "low" = isStudentId
    ? nameMatchesProfile && universityMatchesProfile
      ? "high"
      : "low"
    : !isMeaningfulIdField(fields.nameOnId) &&
        !isMeaningfulIdField(fields.universityOnId) &&
        !describesStudentId
      ? "high"
      : "low";

  return {
    isStudentId,
    confidence,
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
      confidence: "low",
      whatImageShows: null,
      summary: "Vision model could not analyze the uploaded image.",
      nameOnId: null,
      universityOnId: null,
      nameMatchesProfile: false,
      universityMatchesProfile: false,
    };
  }
}

function emailSupportsApproval(emailCheck: EmailCampusCheck): boolean {
  return emailCheck.isCampusDomain && emailCheck.score >= 2;
}

function buildFallbackSummary(
  emailCheck: EmailCampusCheck,
  vision: IdVisionAssessment,
  idLoaded: boolean,
  recommendation: AiReviewResult["recommendation"],
  confidence: AiReviewResult["confidence"],
): string {
  const idSection = !idLoaded
    ? "Could not load the uploaded image from the API for analysis."
    : vision.summary;

  const actionLine =
    recommendation === "reject"
      ? "High confidence — application will be auto-rejected."
      : recommendation === "approve"
        ? "High confidence — application is eligible for auto-approval."
        : "Low confidence — queued for manual admin review.";

  return [
    "Automated seller application review",
    "",
    "**Email & campus**",
    emailCheck.summary,
    "",
    "**Uploaded document**",
    idSection,
    "",
    `**Recommendation:** ${recommendation} (${confidence} confidence)`,
    actionLine,
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
      confidence: "low",
      summary: buildFallbackSummary(
        emailCheck,
        vision,
        idLoaded,
        "review",
        "low",
      ),
    };
  }

  if (!vision.isStudentId) {
    const recommendation: AiReviewResult["recommendation"] =
      vision.confidence === "high" ||
      parseIsStudentIdClaim(vision.summary) === false
        ? "reject"
        : "review";
    return {
      recommendation,
      confidence: vision.confidence,
      summary: buildFallbackSummary(
        emailCheck,
        vision,
        idLoaded,
        recommendation,
        vision.confidence,
      ),
    };
  }

  const canAutoApprove =
    vision.confidence === "high" &&
    vision.nameMatchesProfile &&
    vision.universityMatchesProfile &&
    emailSupportsApproval(emailCheck);

  const recommendation: AiReviewResult["recommendation"] = canAutoApprove
    ? "approve"
    : "review";

  return {
    recommendation,
    confidence: canAutoApprove ? "high" : "low",
    summary: buildFallbackSummary(
      emailCheck,
      vision,
      idLoaded,
      recommendation,
      canAutoApprove ? "high" : "low",
    ),
  };
}

function applicationEmail(item: VerificationRequest): string | null | undefined {
  return item.studentEmail ?? item.userEmail;
}

async function runAiReview(env: Env, item: VerificationRequest): Promise<AiReviewResult> {
  const emailCheck = assessEmailCampusMatch(applicationEmail(item), item.university);

  let vision: IdVisionAssessment = {
    isStudentId: false,
    confidence: "high",
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
        confidence: "low",
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
    if (item.requestType === "verified_badge") {
      let stats: any = {};
      try {
        if (item.adminNotes) {
          stats = JSON.parse(item.adminNotes);
        }
      } catch (e) {
        // failed to parse
      }

      const followers = stats.followers ?? 0;
      const activeListings = stats.activeListings ?? 0;
      const daysAsSeller = stats.daysAsSeller ?? 0;
      const rating = stats.rating ?? 0;
      const ratingCount = stats.ratingCount ?? 0;

      if (
        followers >= 500 &&
        activeListings >= 3 &&
        daysAsSeller >= 90 &&
        rating >= 4.5 &&
        ratingCount >= 15
      ) {
        return {
          recommendation: "approve",
          confidence: "high",
          summary: [
            "Automated seller badge verification review",
            "",
            "**Metrics Check**",
            `Followers: ${followers} (Target: 500+) -> PASSED`,
            `Listings: ${activeListings} (Target: 3+) -> PASSED`,
            `Days as Seller: ${daysAsSeller} (Target: 90+) -> PASSED`,
            `Rating: ${rating} from ${ratingCount} reviews (Target: 4.5+ from 15+) -> PASSED`,
            "",
            "High confidence — applicant strongly meets all metrics and is eligible for auto-approval.",
          ].join("\n"),
        };
      }

      return {
        recommendation: "review",
        confidence: "low",
        summary: [
          "Automated seller badge verification review",
          "",
          "**Metrics Check**",
          `Followers: ${followers}`,
          `Listings: ${activeListings}`,
          `Days as Seller: ${daysAsSeller}`,
          `Rating: ${rating} from ${ratingCount} reviews`,
          "",
          "Low confidence — one or more metrics fell short or were considered borderline. Queued for manual admin review.",
        ].join("\n"),
      };
    }

    return {
      recommendation: "review",
      confidence: "low",
      summary: [
        "Unrecognized request type requires manual admin review.",
        emailCheck.summary,
      ].join("\n\n"),
    };
  }

  if (!item.idDocumentUrl) {
    return {
      recommendation: "reject",
      confidence: "high",
      summary: buildFallbackSummary(
        emailCheck,
        vision,
        idLoaded,
        "reject",
        "high",
      ),
    };
  }

  return synthesizeReview(emailCheck, vision, idLoaded);
}

async function persistAiReview(
  env: Env,
  item: VerificationRequest,
  review: AiReviewResult,
): Promise<void> {
  const response = await apiFetch(
    env,
    `/api/admin/verification-requests/${item.id}/ai-review`,
    {
      method: "POST",
      body: JSON.stringify({
        summary: review.summary,
        recommendation: review.recommendation,
      }),
    },
  );

  if (!response.ok) {
    const body = await response.text();
    throw new Error(
      `Failed to save AI review for ${item.id}: ${response.status} ${body}`,
    );
  }
}

function autoRejectNotes(review: AiReviewResult): string {
  const preview = review.summary.length > 600
    ? `${review.summary.slice(0, 600)}...`
    : review.summary;
  return [
    "Automatically rejected by AI review (high confidence).",
    "Upload a clear photo of your university student ID card and submit again.",
    "",
    preview,
  ].join("\n");
}

async function persistAiReviewAndAct(
  env: Env,
  item: VerificationRequest,
  review: AiReviewResult,
): Promise<void> {
  await persistAiReview(env, item, review);

  if (item.status !== "Pending" || (item.requestType !== "seller_application" && item.requestType !== "verified_badge")) {
    return;
  }

  if (review.recommendation === "reject" && review.confidence === "high") {
    await apiFetch(env, `/api/admin/verification-requests/${item.id}/reject`, {
      method: "POST",
      body: JSON.stringify({ notes: autoRejectNotes(review) }),
    });
    return;
  }

  if (review.recommendation === "approve" && review.confidence === "high") {
    await apiFetch(env, `/api/admin/verification-requests/${item.id}/approve`, {
      method: "POST",
    });
  }
}

async function processRequestReview(
  env: Env,
  item: VerificationRequest,
): Promise<AiReviewResult> {
  const review = await runAiReview(env, item);
  await persistAiReviewAndAct(env, item, review);
  return review;
}

async function processPendingReviews(env: Env): Promise<void> {
  // Fetch seller applications
  let pendingItems: VerificationRequest[] = [];

  const response = await apiFetch(
    env,
    `/api/admin/verification-requests?status=Pending&type=seller_application`,
  );
  if (response.ok) {
    pendingItems = pendingItems.concat(await response.json() as VerificationRequest[]);
  }

  const badgeResponse = await apiFetch(
    env,
    `/api/admin/verification-requests?status=Pending&type=verified_badge`,
  );
  if (badgeResponse.ok) {
    pendingItems = pendingItems.concat(await badgeResponse.json() as VerificationRequest[]);
  }

  const pending = pendingItems.filter(
    (item) => !item.aiReviewSummary && item.status === "Pending",
  );

  await Promise.all(pending.map((item) => processRequestReview(env, item)));
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

    try {
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

      const runReview = async (): Promise<Response> => {
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
          return Response.json({
            ok: true,
            skipped: true,
            reason: "already_reviewed",
          });
        }

        const review = await processRequestReview(env, item);
        return Response.json({ ok: true, review });
      };

      try {
        return await runReview();
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "AI review processing failed.";
        return Response.json({ ok: false, message }, { status: 500 });
      }
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
      return renderPage(renderDashboard(items), "verifications");
    }

    if (path === "/reports" && request.method === "GET") {
      const response = await apiFetch(env, "/api/admin/reports");
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      const reports = (await response.json()) as AdminReport[];
      return renderPage(renderReports(reports), "reports");
    }

    const resolveReportMatch = path.match(/^\/reports\/([^/]+)\/resolve$/);
    if (resolveReportMatch && request.method === "POST") {
      const response = await apiFetch(env, `/api/admin/reports/${resolveReportMatch[1]}/resolve`, {
        method: "POST",
      });
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return Response.redirect(`${url.origin}/reports`, 303);
    }

    if (path === "/users" && request.method === "GET") {
      const response = await apiFetch(env, "/api/admin/users");
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      const users = (await response.json()) as AdminUser[];
      return renderPage(renderUsers(users), "users");
    }

    const suspendUserMatch = path.match(/^\/users\/([^/]+)\/suspend$/);
    if (suspendUserMatch && request.method === "POST") {
      const reason = url.searchParams.get("reason") ?? "";
      const response = await apiFetch(env, `/api/admin/users/${suspendUserMatch[1]}/suspend?reason=${encodeURIComponent(reason)}`, {
        method: "POST",
      });
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return Response.redirect(`${url.origin}/users`, 303);
    }

    const unsuspendUserMatch = path.match(/^\/users\/([^/]+)\/unsuspend$/);
    if (unsuspendUserMatch && request.method === "POST") {
      const response = await apiFetch(env, `/api/admin/users/${unsuspendUserMatch[1]}/unsuspend`, {
        method: "POST",
      });
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return Response.redirect(`${url.origin}/users`, 303);
    }

    if (path === "/listings" && request.method === "GET") {
      const response = await apiFetch(env, "/api/admin/listings");
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      const listings = (await response.json()) as AdminListing[];
      return renderPage(renderListings(listings), "listings");
    }

    if (path === "/appeals" && request.method === "GET") {
      const response = await apiFetch(env, "/api/admin/listings");
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      const listings = (await response.json()) as AdminListing[];
      return renderPage(renderAppeals(listings), "appeals");
    }

    const suspendListingMatch = path.match(/^\/listings\/([^/]+)\/suspend$/);
    if (suspendListingMatch && request.method === "POST") {
      const reason = url.searchParams.get("reason") ?? "";
      const from = url.searchParams.get("from") ?? "listings";
      const response = await apiFetch(env, `/api/admin/listings/${suspendListingMatch[1]}/suspend?reason=${encodeURIComponent(reason)}`, {
        method: "POST",
      });
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return Response.redirect(`${url.origin}/${from}`, 303);
    }

    const unsuspendListingMatch = path.match(/^\/listings\/([^/]+)\/unsuspend$/);
    if (unsuspendListingMatch && request.method === "POST") {
      const from = url.searchParams.get("from") ?? "listings";
      const response = await apiFetch(env, `/api/admin/listings/${unsuspendListingMatch[1]}/unsuspend`, {
        method: "POST",
      });
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return Response.redirect(`${url.origin}/${from}`, 303);
    }

    if (path === "/campaigns" && request.method === "GET") {
      return renderPage(renderCampaigns(), "campaigns");
    }

    if (path === "/campaigns/send" && request.method === "POST") {
      const form = await request.formData();
      const subject = form.get("subject")?.toString() ?? "";
      const htmlBody = form.get("htmlBody")?.toString() ?? "";
      const response = await apiFetch(env, "/api/admin/campaigns/send", {
        method: "POST",
        body: JSON.stringify({ subject, htmlBody }),
      });
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      const result = (await response.json()) as { sentCount: number };
      return renderPage(`
        <div class="title-row">
          <h1>Campaign Sent Successfully!</h1>
        </div>
        <div class="card" style="max-width: 600px;">
          <p>Your email campaign has been successfully broadcast to all <strong>${result.sentCount}</strong> active users.</p>
          <div style="margin-top: 24px;">
            <a href="/campaigns" class="btn btn-green" style="color:#fff; text-decoration:none;">Go Back</a>
          </div>
        </div>
      `, "campaigns");
    }

    // ---- Banners CRUD ----
    if (path === "/banners" && request.method === "GET") {
      const response = await apiFetch(env, "/api/admin/carousel-banners");
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      const banners = (await response.json()) as CarouselBanner[];
      return renderPage(renderBanners(banners), "banners");
    }

    if (path === "/banners/create" && request.method === "GET") {
      return renderPage(renderBannerForm(), "banners");
    }

    if (path === "/banners/create" && request.method === "POST") {
      try {
        const form = await request.formData();
        const title = form.get("title")?.toString() ?? "";
        const subtitle = form.get("subtitle")?.toString() ?? "";
        const imageUrl = form.get("imageUrl")?.toString() ?? "";
        const routePath = form.get("routePath")?.toString() ?? "";
        const response = await apiFetch(env, "/api/admin/carousel-banners", {
          method: "POST",
          body: JSON.stringify({ title, subtitle, imageUrl, routePath }),
        });
        if (!response.ok) {
          const errorText = await response.text();
          return renderPage(`
            <div class="title-row">
              <p><a href="/banners">← Back to banners</a></p>
              <h1 style="color:var(--red);">Error Creating Banner</h1>
            </div>
            <div class="card" style="max-width: 700px; border-color: var(--red);">
              <p style="margin-top:0;">The backend API returned an error (HTTP ${response.status}):</p>
              <pre class="ai" style="color:var(--red);">${escapeHtml(errorText || "(empty response — check backend logs)")}</pre>
              <p class="muted">This usually means the database table is missing. Ensure the CarouselBanners table exists in your database schema.</p>
              <div style="margin-top: 16px;">
                <a href="/banners/create" class="btn btn-green" style="color:#fff; text-decoration:none;">Try Again</a>
              </div>
            </div>
          `, "banners");
        }
        return Response.redirect(`${url.origin}/banners`, 303);
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);
        return renderPage(`
          <div class="title-row">
            <p><a href="/banners">← Back to banners</a></p>
            <h1 style="color:var(--red);">Connection Error</h1>
          </div>
          <div class="card" style="max-width: 700px; border-color: var(--red);">
            <p style="margin-top:0;">Failed to reach the backend API:</p>
            <pre class="ai" style="color:var(--red);">${escapeHtml(message)}</pre>
            <p class="muted">Check that the backend API is running and UNIMARKET_API_URL is configured correctly.</p>
            <div style="margin-top: 16px;">
              <a href="/banners/create" class="btn btn-green" style="color:#fff; text-decoration:none;">Try Again</a>
            </div>
          </div>
        `, "banners");
      }
    }

    const bannerEditMatch = path.match(/^\/banners\/([^/]+)\/edit$/);
    if (bannerEditMatch && request.method === "GET") {
      const response = await apiFetch(env, "/api/admin/carousel-banners");
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      const banners = (await response.json()) as CarouselBanner[];
      const banner = banners.find((b) => b.id === bannerEditMatch[1]);
      if (!banner) return new Response("Banner not found", { status: 404 });
      return renderPage(renderBannerForm(banner), "banners");
    }

    const bannerUpdateMatch = path.match(/^\/banners\/([^/]+)\/update$/);
    if (bannerUpdateMatch && request.method === "POST") {
      const form = await request.formData();
      const title = form.get("title")?.toString() ?? "";
      const subtitle = form.get("subtitle")?.toString() ?? "";
      const imageUrl = form.get("imageUrl")?.toString() ?? "";
      const routePath = form.get("routePath")?.toString() ?? "";
      const response = await apiFetch(env, `/api/admin/carousel-banners/${bannerUpdateMatch[1]}`, {
        method: "PUT",
        body: JSON.stringify({ title, subtitle, imageUrl, routePath }),
      });
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return Response.redirect(`${url.origin}/banners`, 303);
    }

    const bannerDeleteMatch = path.match(/^\/banners\/([^/]+)\/delete$/);
    if (bannerDeleteMatch && request.method === "POST") {
      const response = await apiFetch(env, `/api/admin/carousel-banners/${bannerDeleteMatch[1]}`, {
        method: "DELETE",
      });
      if (!response.ok) {
        return new Response(await response.text(), { status: response.status });
      }
      return Response.redirect(`${url.origin}/banners`, 303);
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
      return renderPage(renderDetail(item), "verifications");
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
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      const stack = err instanceof Error ? err.stack : "";
      return new Response(`Worker error: ${message}\n${stack}`, { status: 500 });
    }
  },
};
