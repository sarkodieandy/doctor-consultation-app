const SUPABASE_URL = "https://mkfcyhfmbncuoswyurgh.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1rZmN5aGZtYm5jdW9zd3l1cmdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxNjc0ODQsImV4cCI6MjA3ODc0MzQ4NH0.rvZEtonSpYD32l3vraU_pNkfcV6uLg0Coo5N9-hpDDY";

const db = window.supabase
  ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;

const viewPermissionMap = {
  dashboard: ["dashboard.view"],
  doctors: ["doctors.manage", "doctors.verify"],
  appointments: ["appointments.manage"],
  consultations: ["consultations.view"],
  payments: ["payments.manage", "payouts.manage"],
  payouts: ["payouts.manage"],
  refunds: ["refunds.manage"],
  patients: ["patients.manage"],
  reviews: ["reviews.moderate"],
  complaints: ["complaints.manage"],
  support: ["support.manage"],
  documents: ["patients.manage"],
  prescriptions: ["consultations.view"],
  notifications: ["notifications.manage"],
  content: ["content.manage"],
  reports: ["reports.view"],
  settings: ["settings.manage"],
  audit: ["audit.view"],
};

const rolePermissionFallback = {
  super_admin: Object.values(viewPermissionMap).flat(),
  finance_admin: ["dashboard.view", "payments.manage", "payouts.manage", "refunds.manage", "reports.view", "audit.view"],
  support_admin: ["dashboard.view", "patients.manage", "appointments.manage", "complaints.manage", "support.manage", "notifications.manage", "audit.view"],
  doctor_verification_admin: ["dashboard.view", "doctors.manage", "doctors.verify", "reviews.moderate", "audit.view"],
  content_manager: ["dashboard.view", "notifications.manage", "content.manage", "reports.view"],
};

const state = {
  session: null,
  view: "dashboard",
  search: "",
  appointmentFilter: "all",
  doctorFilter: "all",
  usingPreview: false,
  profiles: [],
  doctors: [],
  appointments: [],
  consultations: [],
  payments: [],
  payouts: [],
  complaints: [],
  refunds: [],
  supportTickets: [],
  medicalDocuments: [],
  prescriptions: [],
  reviews: [],
  notifications: [],
  cmsPages: [],
  appBanners: [],
  healthTips: [],
  settings: [],
  specialties: [],
  auditLog: [],
  adminProfile: null,
  adminRoleCode: "super_admin",
  adminRoleName: "Super Admin",
  adminPermissions: new Set(rolePermissionFallback.super_admin),
};

const preview = {
  profiles: [],
  doctors: [],
  appointments: [],
  consultations: [],
  payments: [],
  payouts: [],
  complaints: [],
  refunds: [],
  supportTickets: [],
  medicalDocuments: [],
  prescriptions: [],
  reviews: [],
  notifications: [],
  cmsPages: [],
  appBanners: [],
  healthTips: [],
  settings: [],
  specialties: [],
  auditLog: [],
};

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => Array.from(document.querySelectorAll(selector));

document.addEventListener("DOMContentLoaded", init);

async function init() {
  bindEvents();
  setInitialView();
  if (db) {
    const { data } = await db.auth.getSession();
    state.session = data.session;
  }
  if (state.session && (await isAdminSession())) {
    await openDashboard();
    return;
  }
  await db?.auth.signOut();
  state.session = null;
  showLogin();
}

function bindEvents() {
  $$(".module-toggle").forEach((button) => {
    button.addEventListener("click", () => {
      const group = button.closest(".nav-group");
      const isOpen = group.classList.toggle("open");
      button.setAttribute("aria-expanded", String(isOpen));
    });
  });

  $$(".nav-item").forEach((button) => {
    button.addEventListener("click", () => navigate(button.dataset.view));
  });

  window.addEventListener("hashchange", () => {
    const view = hashView();
    if (view && view !== state.view) {
        if (canAccessView(view)) {
          state.view = view;
          render();
        }
    }
  });

  $("#sidebarToggle")?.addEventListener("click", () => {
    $("#sidebar").classList.toggle("sidebar-open");
  });

  $("#refreshButton").addEventListener("click", async () => {
    await loadData();
    render();
    toast("Dashboard refreshed");
  });

  $("#loginButton").addEventListener("click", async () => {
    if (state.session) {
      await db?.auth.signOut();
      state.session = null;
      showLogin();
      toast("Signed out");
      return;
    }
    showLogin();
  });

  $("#authForm").addEventListener("submit", signIn);

  $("#searchInput").addEventListener("input", (event) => {
    state.search = event.target.value.toLowerCase();
    renderActiveView();
  });

  $("#appointmentFilter").addEventListener("change", (event) => {
    state.appointmentFilter = event.target.value;
    renderAppointments();
  });

  $$(".doctor-filter").forEach((button) => {
    button.addEventListener("click", () => {
      state.doctorFilter = button.dataset.filter || "all";
      renderDoctors();
    });
  });

  $("#seedDoctorButton").addEventListener("click", addSampleDoctor);
  $("#refreshDoctorsButton")?.addEventListener("click", async () => {
    await loadData();
    renderDoctors();
    toast("Doctor directory refreshed");
  });
  $("#refreshAuditButton")?.addEventListener("click", async () => {
    state.auditLog = await selectTable("audit_log", { orderBy: "created_at", ascending: false });
    renderAudit();
    toast("Audit log refreshed");
  });
  $("#notificationForm").addEventListener("submit", sendNotification);
  $("#settingsForm").addEventListener("submit", saveSettings);
  $("#specialtyForm").addEventListener("submit", addSpecialty);
  $("#cmsPageForm")?.addEventListener("submit", (event) => saveCmsPage(event));
  $("#bannerForm")?.addEventListener("submit", (event) => saveBanner(event));
  $("#healthTipForm")?.addEventListener("submit", (event) => saveHealthTip(event));

  $("#exportAppointmentsButton")?.addEventListener("click", () => exportCsv("appointments", state.appointments));
  $("#exportPaymentsButton")?.addEventListener("click", () => exportCsv("payments", state.payments));
  $("#exportDoctorsButton")?.addEventListener("click", () => exportCsv("doctors", state.doctors));
  $("#exportPatientsButton")?.addEventListener("click", () => exportCsv("patients", state.profiles.filter((p) => !["doctor", "admin", "superadmin"].includes(p.role))));
  $("#exportComplaintsButton")?.addEventListener("click", () => exportCsv("complaints", state.complaints));
  $("#exportSupportButton")?.addEventListener("click", () => exportCsv("support_tickets", state.supportTickets));
  $("#exportPayoutsButton")?.addEventListener("click", () => exportCsv("payouts", state.payouts));
  $("#exportRefundsButton")?.addEventListener("click", () => exportCsv("refunds", state.refunds));
  $("#exportPrescriptionsButton")?.addEventListener("click", () => exportCsv("prescriptions", state.prescriptions));
}

function setInitialView() {
  const view = hashView();
  if (view) state.view = view;
}

function hashView() {
  const value = window.location.hash.replace(/^#\/?/, "");
  return $(`.nav-item[data-view="${value}"]`) && canAccessView(value) ? value : "";
}

function navigate(view) {
  if (!view) return;
  if (!canAccessView(view)) {
    toast("You do not have access to this module");
    return;
  }
  state.view = view;
  window.location.hash = view;
  $("#sidebar").classList.remove("sidebar-open");
  render();
}

async function signIn(event) {
  event.preventDefault();
  const rawIdentifier = $("#adminEmail").value.trim();
  const password = $("#adminPassword").value;

  if (!rawIdentifier || !password) {
    toast("Enter admin username/email and password");
    return;
  }

  // Attempt Supabase auth when available
  if (db) {
    const email = await resolveLoginEmail(rawIdentifier);
    if (!email) {
      toast("Username not found");
      return;
    }
    const { data, error } = await db.auth.signInWithPassword({ email, password });
    if (!error) {
      state.session = data.session;
      if (!(await isAdminSession())) {
        await db.auth.signOut();
        state.session = null;
        showLogin();
        toast("Access denied: admin account required");
        return;
      }
      await openDashboard();
      toast("Connected as superadmin");
      return;
    }

    // If Supabase is reachable but credentials are wrong, stop here
    const isServerError = error.status >= 500 || /schema|database|unavailable|network/i.test(error.message);
    if (!isServerError) {
      toast(error.message);
      return;
    }
  }

  // Supabase unavailable — allow offline preview login with local credentials
  const validCredentials = rawIdentifier.toLowerCase() === "superadmin" && password === "123456";
  if (!validCredentials) {
    toast("Invalid credentials");
    return;
  }

  hydratePreview(true);
  document.body.classList.remove("logged-out");
  state.view = "dashboard";
  window.location.hash = "dashboard";
  render();
  toast("Connected in preview mode (Supabase offline)");
}

// Resolve a username or email to an auth email.
// If it looks like a username (no @), look it up in profiles by username field.
async function resolveLoginEmail(identifier) {
  const value = identifier.trim();
  if (value.includes("@")) return value;
  // Username — look up corresponding email from profiles
  try {
    const { data } = await db
      .from("profiles")
      .select("email")
      .eq("username", value)
      .eq("role", "admin")
      .maybeSingle();
    if (data?.email) return data.email;
  } catch (_) {}
  // Fallback for the default superadmin username
  if (value.toLowerCase() === "superadmin") return "superadmin@docconsult.app";
  return null;
}

async function isAdminSession() {
  if (!state.session?.user) return false;

  // Check JWT user metadata first (no DB query needed, avoids RLS chicken-and-egg)
  const meta = state.session.user.user_metadata || {};
  const appMeta = state.session.user.app_metadata || {};
  const metaRole = String(meta.role || appMeta.role || "").toLowerCase();
  if (["admin", "superadmin"].includes(metaRole)) return true;

  // Also allow superadmin email directly
  const email = state.session.user.email?.toLowerCase();
  if (email === "superadmin@docconsult.app") return true;

  // Fall back to profiles table query
  try {
    const { data, error } = await db
      .from("profiles")
      .select("role")
      .eq("id", state.session.user.id)
      .maybeSingle();
    if (error) throw error;
    return ["admin", "superadmin"].includes(String(data?.role || "").toLowerCase());
  } catch (_) {
    return false;
  }
}

async function openDashboard() {
  document.body.classList.remove("logged-out");
  await loadAdminAccessContext();
  state.view = "dashboard";
  if (!canAccessView(state.view)) {
    state.view = firstAllowedView();
  }
  window.location.hash = state.view;
  await loadData();
  render();
  if (db) subscribeRealtime();
}

function showLogin() {
  document.body.classList.add("logged-out");
  state.view = "dashboard";
  state.adminProfile = null;
  state.adminRoleCode = "super_admin";
  state.adminRoleName = "Super Admin";
  state.adminPermissions = new Set(rolePermissionFallback.super_admin);
  updateConnection("offline", "Signed out", "Login with superadmin");
}

async function loadData() {
  state.usingPreview = false;
  if (!db) {
    state.profiles = [];
    state.doctors = [];
    state.appointments = [];
    state.consultations = [];
    state.payments = [];
    state.payouts = [];
    state.complaints = [];
    state.refunds = [];
    state.supportTickets = [];
    state.medicalDocuments = [];
    state.prescriptions = [];
    state.reviews = [];
    state.notifications = [];
    state.cmsPages = [];
    state.appBanners = [];
    state.healthTips = [];
    state.settings = [];
    state.specialties = [];
    state.auditLog = [];
    return;
  }
  const [
    profiles,
    doctors,
    appointments,
    consultations,
    payments,
    payouts,
    complaints,
    refunds,
    supportTickets,
    medicalDocuments,
    prescriptions,
    reviews,
    notifications,
    cmsPages,
    appBanners,
    healthTips,
    settings,
    specialties,
    auditLog,
  ] =
    await Promise.all([
      selectTable("profiles", { orderBy: "created_at", ascending: false }),
      selectTable("doctors"),
      selectTable("appointments", { orderBy: "appointment_date", ascending: false }),
      selectTable("consultations", { orderBy: "created_at", ascending: false }),
      selectTable("payments", { orderBy: "created_at", ascending: false }),
      selectTable("payouts", { orderBy: "created_at", ascending: false }),
      selectTable("complaints", { orderBy: "created_at", ascending: false }),
      selectTable("refunds", { orderBy: "created_at", ascending: false }),
      selectTable("support_tickets", { orderBy: "created_at", ascending: false }),
      selectTable("medical_documents", { orderBy: "created_at", ascending: false }),
      selectTable("prescriptions", { orderBy: "created_at", ascending: false }),
      selectTable("reviews", { orderBy: "created_at", ascending: false }),
      selectTable("notifications", { orderBy: "created_at", ascending: false }),
      selectTable("cms_pages", { orderBy: "updated_at", ascending: false }),
      selectTable("app_banners", { orderBy: "created_at", ascending: false }),
      selectTable("health_tips", { orderBy: "created_at", ascending: false }),
      selectTable("settings"),
      selectTable("specialties", { orderBy: "name", ascending: true }),
      selectTable("audit_log", { orderBy: "created_at", ascending: false }),
    ]);

  state.profiles = profiles;
  state.doctors = mergeDoctorRows(profiles, doctors);
  state.appointments = appointments;
  state.consultations = consultations;
  state.payments = payments;
  state.payouts = payouts;
  state.complaints = complaints;
  state.refunds = refunds;
  state.supportTickets = supportTickets;
  state.medicalDocuments = medicalDocuments;
  state.prescriptions = prescriptions;
  state.reviews = reviews;
  state.notifications = notifications;
  state.cmsPages = cmsPages;
  state.appBanners = appBanners;
  state.healthTips = healthTips;
  state.settings = settings;
  state.specialties = specialties;
  state.auditLog = auditLog;

}

async function selectTable(table, options = {}) {
  try {
    let query = db.from(table).select("*").limit(options.limit || 500);
    if (options.orderBy) {
      query = query.order(options.orderBy, { ascending: options.ascending !== false });
    }
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  } catch (error) {
    console.warn(`Unable to load ${table}:`, error?.message || error);
    return [];
  }
}

function hydratePreview(silent = false) {
  state.usingPreview = true;
  state.profiles = [...preview.profiles];
  state.doctors = doctorsFromProfiles(preview.profiles);
  state.appointments = [...preview.appointments];
  state.consultations = [...preview.consultations];
  state.payments = [...preview.payments];
  state.payouts = [...preview.payouts];
  state.complaints = [...preview.complaints];
  state.refunds = [...preview.refunds];
  state.supportTickets = [...preview.supportTickets];
  state.medicalDocuments = [...preview.medicalDocuments];
  state.prescriptions = [...preview.prescriptions];
  state.reviews = [...preview.reviews];
  state.notifications = [...preview.notifications];
  state.cmsPages = [...preview.cmsPages];
  state.appBanners = [...preview.appBanners];
  state.healthTips = [...preview.healthTips];
  state.settings = [...preview.settings];
  state.specialties = [...preview.specialties];
  state.auditLog = [...preview.auditLog];
  if (!silent) updateConnection("offline", "Preview data", "Supabase tables are empty or blocked");
}

function render() {
  applyViewPermissions();
  if (!canAccessView(state.view)) {
    state.view = firstAllowedView();
    window.location.hash = state.view;
  }
  $$(".nav-item").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === state.view);
  });
  updateSidebarState();
  $$(".content-view").forEach((panel) => {
    panel.classList.toggle("hidden", panel.dataset.viewPanel !== state.view);
  });
  $("#pageTitle").textContent = pageTitle(state.view);
  $("#loginButton").textContent = state.session ? "Sign out" : "Admin sign in";
  updateConnectionStatus();
  renderActiveView();
}

function renderActiveView() {
  const renderers = {
    dashboard: renderDashboard,
    doctors: renderDoctors,
    appointments: renderAppointments,
    consultations: renderConsultations,
    payments: renderPayments,
    payouts: renderPayouts,
    refunds: renderRefunds,
    patients: renderPatients,
    reviews: renderReviews,
    complaints: renderComplaints,
    support: renderSupport,
    documents: renderDocuments,
    prescriptions: renderPrescriptions,
    notifications: renderNotifications,
    content: renderContent,
    reports: renderReports,
    settings: renderSettings,
    audit: renderAudit,
  };
  renderers[state.view]?.();
}

function updateSidebarState() {
  const activeItem = $(`.nav-item[data-view="${state.view}"]`);
  if (!activeItem) return;
  const activeGroup = activeItem.closest(".nav-group");
  $$(".nav-group").forEach((group) => {
    const shouldOpen = group === activeGroup || group.classList.contains("open");
    group.classList.toggle("open", shouldOpen);
    group.querySelector(".module-toggle")?.setAttribute("aria-expanded", String(shouldOpen));
  });
}

function renderDashboard() {
  const pendingDoctors = state.doctors.filter(
    (doctor) => normalizeStatus(doctor.approval_status) === "pending",
  );
  const patients = state.profiles.filter((profile) => !["doctor", "admin", "superadmin"].includes(profile.role));
  const revenue = state.payments
    .filter((payment) => normalizeStatus(payment.status) === "completed")
    .reduce((sum, payment) => sum + Number(payment.amount || 0), 0);

  $("#metricsGrid").innerHTML = [
    metricCard("Doctors", state.doctors.length, `${pendingDoctors.length} awaiting review`),
    metricCard("Patients", patients.length, "Registered care accounts"),
    metricCard("Appointments", state.appointments.length, "Across all statuses"),
    metricCard("Revenue", `GHS ${revenue.toFixed(0)}`, "Completed payments"),
  ].join("");

  renderStatusBars();
  renderApprovalQueue();
  renderActivity();
}

function renderStatusBars() {
  const statuses = ["confirmed", "pending", "completed", "cancelled"];
  const total = Math.max(state.appointments.length, 1);
  $("#statusBars").innerHTML = statuses
    .map((status) => {
      const count = state.appointments.filter(
        (appointment) => normalizeStatus(appointment.status) === status,
      ).length;
      const width = Math.max((count / total) * 100, count ? 8 : 0);
      return `
        <div class="bar-row">
          <header><span>${capitalize(status)}</span><strong>${count}</strong></header>
          <div class="bar-track"><div class="bar-fill" style="width:${width}%"></div></div>
        </div>
      `;
    })
    .join("");
}

function renderApprovalQueue() {
  const pending = state.doctors.filter(
    (doctor) => normalizeStatus(doctor.approval_status) === "pending",
  );
  $("#pendingCount").textContent = `${pending.length} pending`;
  $("#approvalQueue").innerHTML =
    pending
      .slice(0, 5)
      .map((doctor) => listItem(fullDoctorName(doctor), doctor.specialty, statusPill("pending")))
      .join("") || emptyState("No doctors waiting for approval.");
}

function renderActivity() {
  const feed = [
    ...state.appointments.slice(0, 4).map((appointment) => ({
      title: `${appointment.patient_name || patientName(appointment.user_id)} booked ${appointment.doctor_name || doctorName(appointment.doctor_id)}`,
      detail: `${formatDate(appointment.appointment_date)} · ${stripTags(statusPill(appointment.status))}`,
      date: appointment.created_at || appointment.appointment_date,
    })),
    ...state.payments.slice(0, 3).map((payment) => ({
      title: `Payment ${normalizeStatus(payment.status)}`,
      detail: `GHS ${Number(payment.amount || 0).toFixed(2)} · ${payment.payment_method || "method pending"}`,
      date: payment.created_at,
    })),
  ].sort((a, b) => new Date(b.date || 0) - new Date(a.date || 0));

  $("#activityList").innerHTML =
    feed
      .slice(0, 6)
      .map(
        (item) =>
          `<div class="activity-item"><div><strong>${item.title}</strong><span>${item.detail}</span></div><span>${relativeDate(item.date)}</span></div>`,
      )
      .join("") || emptyState("No recent activity yet.");
}

function renderDoctors() {
  const allDoctors = filterRows(state.doctors, ["name", "email", "specialty", "phone"]);
  const doctors = allDoctors.filter((doctor) => doctorMatchesFilter(doctor));
  const pending = state.doctors.filter((doctor) => normalizeStatus(doctor.approval_status) === "pending").length;
  const approved = state.doctors.filter((doctor) => normalizeStatus(doctor.approval_status) === "approved").length;
  const suspended = state.doctors.filter((doctor) => isDoctorSuspended(doctor)).length;
  const payoutReady = state.doctors.filter((doctor) => doctor.mobile_money_number || doctor.payout_recipient_code).length;

  $("#doctorStats").innerHTML = [
    doctorStat("Total doctors", state.doctors.length, "Directory profiles"),
    doctorStat("Pending review", pending, "Need credential decision"),
    doctorStat("Approved", approved, "Visible to patients"),
    doctorStat("Payout ready", payoutReady, `${suspended} suspended`),
  ].join("");
  $("#doctorCount").textContent = `${doctors.length} ${doctors.length === 1 ? "doctor" : "doctors"}`;
  $$(".doctor-filter").forEach((button) => {
    button.classList.toggle("active", button.dataset.filter === state.doctorFilter);
  });

  $("#doctorGrid").innerHTML =
    doctors
      .map((doctor) => {
        const status = normalizeStatus(doctor.approval_status || "pending");
        const fee = Number(doctor.consultation_fee || 0).toFixed(0);
        const payoutReady = doctor.mobile_money_number || doctor.payout_recipient_code;
        const hasDocument = Boolean(doctor.license_document_path);
        const appointments = state.appointments.filter((appointment) => appointment.doctor_id === doctor.id).length;
        return `
          <article class="doctor-card modern-doctor-card">
            <div class="doctor-card-accent"></div>
            <div class="doctor-top modern-doctor-top">
              ${profileAvatar(doctor, fullDoctorName(doctor))}
              <div class="doctor-heading">
                <div class="doctor-title-row">
                  <h2>${fullDoctorName(doctor)}</h2>
                  <span class="status ${isDoctorSuspended(doctor) ? "cancelled" : status}">${isDoctorSuspended(doctor) ? "Suspended" : capitalize(status)}</span>
                </div>
                <p>${doctor.specialty || "General Practice"} · ${doctor.experience || "Experience not set"}</p>
                <span class="doctor-email">${doctor.email || "No email on profile"}</span>
              </div>
            </div>
            <div class="doctor-meta modern-doctor-meta">
              <div><span>Fee</span><strong>GHS ${fee}</strong></div>
              <div><span>Rating</span><strong>${averageRating(doctor.id)}</strong></div>
              <div><span>Bookings</span><strong>${appointments}</strong></div>
              <div><span>Payout</span><strong>${payoutReady ? "Ready" : "Missing"}</strong></div>
            </div>
            <div class="doctor-readiness">
              <span class="${doctor.profile_image ? "ready" : ""}">Photo</span>
              <span class="${hasDocument ? "ready" : ""}">License</span>
              <span class="${doctor.phone ? "ready" : ""}">Phone</span>
              <span class="${payoutReady ? "ready" : ""}">Payout</span>
            </div>
            <div class="verification-strip ${hasDocument ? "ready" : "missing"}">
              <div>
                <strong>${hasDocument ? "Verification document uploaded" : "Verification document missing"}</strong>
                <span>${doctor.approval_note || (hasDocument ? "Open the license before approving." : "Doctor must upload a license from the app.")}</span>
              </div>
              <button class="small-button neutral" onclick="viewDoctorDocument('${doctor.id}')">${hasDocument ? "Review document" : "No document"}</button>
            </div>
            <div class="actions-row">
              <button class="small-button success" onclick="updateDoctorStatus('${doctor.id}', 'approved')">Approve</button>
              <button class="small-button danger" onclick="updateDoctorStatus('${doctor.id}', 'rejected')">Reject</button>
              <button class="small-button neutral" onclick="copyDoctorEmail('${doctor.id}')">Copy email</button>
              <button class="small-button danger" onclick="toggleDoctor('${doctor.id}')">${isDoctorSuspended(doctor) ? "Reactivate" : "Suspend"}</button>
            </div>
          </article>
        `;
      })
      .join("") || emptyState("No doctors found.");
}

function renderAppointments() {
  const rows = filterRows(state.appointments, [
    "patient_name",
    "doctor_name",
    "speciality",
    "status",
  ]);
  const filtered =
    state.appointmentFilter === "all"
      ? rows
      : rows.filter((appointment) => normalizeStatus(appointment.status) === state.appointmentFilter);

  $("#appointmentsTable").innerHTML =
    filtered
      .map(
        (appointment) => `
        <tr>
          <td><strong>${appointment.patient_name || patientName(appointment.user_id)}</strong><br><span>${appointment.speciality || "Consultation"}</span></td>
          <td>${appointment.doctor_name || doctorName(appointment.doctor_id)}</td>
          <td>${formatDate(appointment.appointment_date)}<br><span>${appointment.time_slot || ""}</span></td>
          <td>GHS ${Number(appointment.consultation_fee || 0).toFixed(2)}</td>
          <td>${statusPill(appointment.status)}</td>
          <td>
            <button class="small-button" onclick="updateAppointmentStatus('${appointment.id}', 'confirmed')">Confirm</button>
            <button class="small-button" onclick="updateAppointmentStatus('${appointment.id}', 'completed')">Complete</button>
            <button class="small-button danger" onclick="updateAppointmentStatus('${appointment.id}', 'cancelled')">Cancel</button>
          </td>
        </tr>
      `,
      )
      .join("") || `<tr><td colspan="6">${emptyState("No appointments match this view.")}</td></tr>`;
}

function renderPayments() {
  const completed  = state.payments.filter((p) => normalizeStatus(p.status) === "completed");
  const pending    = state.payments.filter((p) => normalizeStatus(p.status) === "pending");
  const failed     = state.payments.filter((p) => normalizeStatus(p.status) === "failed");
  const refunded   = state.payments.filter((p) => normalizeStatus(p.status) === "refunded");

  const completedTotal  = completed.reduce((s, p) => s + Number(p.amount || 0), 0);
  const pendingTotal    = pending.reduce((s, p) => s + Number(p.amount || 0), 0);
  const platformFeeTotal = completed.reduce((s, p) => s + Number(p.platform_fee || 0), 0);
  const doctorPayoutDue  = completed
    .filter((p) => (p.payout_status || "not_ready") === "pending")
    .reduce((s, p) => s + Number(p.doctor_amount || 0), 0);

  // ── Summary cards ──────────────────────────────────────────────────────────
  $("#paymentSummary").innerHTML = [
    listItem("Gross revenue",      `GHS ${completedTotal.toFixed(2)}`,   statusPill("completed")),
    listItem("Platform earnings",  `GHS ${platformFeeTotal.toFixed(2)}`, statusPill("confirmed")),
    listItem("Pending collection", `GHS ${pendingTotal.toFixed(2)}`,     statusPill("pending")),
    listItem("Doctor payouts due", `GHS ${doctorPayoutDue.toFixed(2)}`,  statusPill(doctorPayoutDue > 0 ? "pending" : "completed")),
    listItem("Total transactions", `${state.payments.length} records`,   statusPill("confirmed")),
    listItem("Refunded",           `${refunded.length} (${failed.length} failed)`, statusPill(refunded.length ? "cancelled" : "confirmed")),
  ].join("");

  // ── Per-doctor payout readiness ────────────────────────────────────────────
  $("#payoutList").innerHTML =
    state.doctors
      .map((doctor) => {
        const ready    = doctor.mobile_money_number || doctor.payout_recipient_code;
        const pending  = state.payments
          .filter((p) => p.doctor_id === doctor.id && (p.payout_status || "not_ready") === "pending")
          .reduce((s, p) => s + Number(p.doctor_amount || 0), 0);
        const label    = pending > 0 ? `GHS ${pending.toFixed(2)} due` : "No pending payout";
        return listItem(
          fullDoctorName(doctor),
          ready ? `${label} · Payout details on file` : "Missing payout details",
          statusPill(ready && pending > 0 ? "pending" : ready ? "approved" : "cancelled"),
        );
      })
      .join("") || emptyState("No doctors registered yet.");

  // ── Transactions table ─────────────────────────────────────────────────────
  const rows = filterRows(state.payments, ["status", "payment_method", "payout_status", "gateway_reference"]);
  $("#paymentsTable").innerHTML =
    rows
      .map((payment) => {
        const amount      = Number(payment.amount || 0);
        const fee         = Number(payment.platform_fee || 0);
        const doctorAmt   = Number(payment.doctor_amount || amount - fee);
        const ref         = payment.gateway_reference || payment.transaction_id || "—";
        const status      = normalizeStatus(payment.status);
        const payoutSt    = payment.payout_status || "not_ready";
        return `
          <tr>
            <td>
              <strong>${patientName(payment.user_id)}</strong>
              <br><span style="font-size:11px;opacity:0.6">${ref}</span>
            </td>
            <td>${doctorName(payment.doctor_id)}</td>
            <td>
              <strong>GHS ${amount.toFixed(2)}</strong>
              <br><span style="font-size:11px;opacity:0.6">Fee GHS ${fee.toFixed(2)} · Dr GHS ${doctorAmt.toFixed(2)}</span>
            </td>
            <td>${statusPill(status)}<br><span style="font-size:11px">${payment.payment_method || "—"}</span></td>
            <td>${statusPill(payoutSt)}</td>
            <td style="white-space:nowrap">
              ${status === "pending" ? `<button class="small-button" onclick="adminMarkPaymentPaid('${payment.id}')">Mark paid</button>` : ""}
              ${status === "completed" && payoutSt === "pending" ? `<button class="small-button success" onclick="adminMarkPayoutDone('${payment.id}')">Payout done</button>` : ""}
              ${status === "completed" ? `<button class="small-button danger" onclick="adminRefundPayment('${payment.id}', '${ref}')">Refund</button>` : ""}
              ${status !== "failed" && status !== "refunded" ? `<button class="small-button danger" onclick="updatePayment('${payment.id}', { status: 'failed' })">Fail</button>` : ""}
            </td>
          </tr>
        `;
      })
      .join("") || `<tr><td colspan="6">${emptyState("No payment records found.")}</td></tr>`;
}

async function adminMarkPaymentPaid(paymentId) {
  await updatePayment(paymentId, { status: "completed", payout_status: "pending" });
}

async function adminMarkPayoutDone(paymentId) {
  await updatePayment(paymentId, { payout_status: "processed" });
}

async function adminRefundPayment(paymentId, reference) {
  if (!confirm(`Refund payment ${reference}?\n\nThis will update the status to refunded. You must also initiate the actual refund via the Paystack dashboard.`)) return;
  await updatePayment(paymentId, { status: "refunded", refunded_at: new Date().toISOString() });
  toast("Marked as refunded. Complete the refund in your Paystack dashboard.");
}

async function updateConsultationStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const payload = { status, updated_at: new Date().toISOString() };
    if (status === "completed") payload.end_time = new Date().toISOString();
    const { error } = await db.from("consultations").update(payload).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_consultation_status", "consultations", id, { status });
  }
  const row = state.consultations.find((item) => item.id === id);
  if (row) row.status = status;
  renderConsultations();
  toast(`Consultation marked ${status}`);
}

async function updatePayoutStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const payload = { status, updated_at: new Date().toISOString() };
    if (status === "paid") payload.paid_at = new Date().toISOString();
    const { error } = await db.from("payouts").update(payload).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_payout_status", "payouts", id, { status });
  }
  const row = state.payouts.find((item) => item.id === id);
  if (row) Object.assign(row, { status });
  renderPayouts();
  toast(`Payout marked ${status}`);
}

async function updateRefundStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const payload = { status, updated_at: new Date().toISOString(), decided_at: new Date().toISOString(), decided_by: state.session?.user?.id || null };
    if (status === "refunded") payload.refunded_at = new Date().toISOString();
    const { error } = await db.from("refunds").update(payload).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_refund_status", "refunds", id, { status });
  }
  const row = state.refunds.find((item) => item.id === id);
  if (row) Object.assign(row, { status });
  renderRefunds();
  toast(`Refund marked ${status}`);
}

async function updateComplaintStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const payload = { status, updated_at: new Date().toISOString() };
    if (status === "resolved") payload.resolved_at = new Date().toISOString();
    if (status === "closed") payload.closed_at = new Date().toISOString();
    const { error } = await db.from("complaints").update(payload).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_complaint_status", "complaints", id, { status });
  }
  const row = state.complaints.find((item) => item.id === id);
  if (row) Object.assign(row, { status });
  renderComplaints();
  toast(`Complaint marked ${status}`);
}

async function updateSupportStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const payload = { status, updated_at: new Date().toISOString() };
    if (status === "resolved") payload.resolved_at = new Date().toISOString();
    if (status === "closed") payload.closed_at = new Date().toISOString();
    const { error } = await db.from("support_tickets").update(payload).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_support_ticket", "support_tickets", id, { status });
  }
  const row = state.supportTickets.find((item) => item.id === id);
  if (row) Object.assign(row, { status });
  renderSupport();
  toast(`Ticket marked ${status}`);
}

async function updateMedicalDocumentStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("medical_documents").update({ status, updated_at: new Date().toISOString() }).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_medical_document", "medical_documents", id, { status });
  }
  const row = state.medicalDocuments.find((item) => item.id === id);
  if (row) row.status = status;
  renderDocuments();
  toast(`Document marked ${status}`);
}

async function updatePrescriptionStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("prescriptions").update({ status, updated_at: new Date().toISOString() }).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_prescription", "prescriptions", id, { status });
  }
  const row = state.prescriptions.find((item) => item.id === id);
  if (row) row.status = status;
  renderPrescriptions();
  toast(`Prescription marked ${status}`);
}

function renderConsultations() {
  const rows = filterRows(state.consultations, ["id", "status", "consultation_type", "payment_status"]);
  $("#consultationsTable").innerHTML =
    rows
      .map((item) => {
        const duration = Number(item.duration_seconds || 0);
        const minutes = duration ? `${Math.round(duration / 60)} mins` : "—";
        return `
          <tr>
            <td><strong>${item.id}</strong><br><span>${formatDate(item.created_at)}</span></td>
            <td>${patientName(item.patient_id)}</td>
            <td>${doctorName(item.doctor_id)}</td>
            <td>${capitalize(item.consultation_type || "video")}</td>
            <td>${statusPill(item.status || "scheduled")}</td>
            <td>${statusPill(item.payment_status || "pending")}</td>
            <td>${minutes}</td>
            <td>
              <button class="small-button" onclick="updateConsultationStatus('${item.id}', 'in_progress')">Start</button>
              <button class="small-button success" onclick="updateConsultationStatus('${item.id}', 'completed')">Complete</button>
              <button class="small-button danger" onclick="updateConsultationStatus('${item.id}', 'cancelled')">Cancel</button>
            </td>
          </tr>
        `;
      })
      .join("") || `<tr><td colspan="8">${emptyState("No consultation records found.")}</td></tr>`;
}

function renderPayouts() {
  const rows = filterRows(state.payouts, ["status", "payout_method", "transfer_code"]);
  $("#payoutsTable").innerHTML =
    rows
      .map((item) => `
        <tr>
          <td><strong>${item.id}</strong><br><span>${item.transfer_code || "—"}</span></td>
          <td>${doctorName(item.doctor_id)}</td>
          <td>GHS ${Number(item.amount || 0).toFixed(2)}</td>
          <td>${item.payout_method || "MoMo / Bank"}</td>
          <td>${statusPill(item.status || "pending")}</td>
          <td>${formatDate(item.created_at)}</td>
          <td>
            <button class="small-button" onclick="updatePayoutStatus('${item.id}', 'processing')">Process</button>
            <button class="small-button success" onclick="updatePayoutStatus('${item.id}', 'paid')">Mark paid</button>
            <button class="small-button danger" onclick="updatePayoutStatus('${item.id}', 'failed')">Fail</button>
            <button class="small-button danger" onclick="updatePayoutStatus('${item.id}', 'on_hold')">Hold</button>
          </td>
        </tr>
      `)
      .join("") || `<tr><td colspan="7">${emptyState("No payout records found.")}</td></tr>`;
}

function renderRefunds() {
  const rows = filterRows(state.refunds, ["status", "reason", "gateway_reference"]);
  $("#refundsTable").innerHTML =
    rows
      .map((item) => `
        <tr>
          <td><strong>${item.id}</strong><br><span>${item.gateway_reference || "—"}</span></td>
          <td>${item.payment_id || "—"}</td>
          <td>${patientName(item.patient_id)}</td>
          <td>${doctorName(item.doctor_id)}</td>
          <td>GHS ${Number(item.amount || 0).toFixed(2)}</td>
          <td>${statusPill(item.status || "requested")}</td>
          <td>
            <button class="small-button success" onclick="updateRefundStatus('${item.id}', 'approved')">Approve</button>
            <button class="small-button danger" onclick="updateRefundStatus('${item.id}', 'rejected')">Reject</button>
            <button class="small-button" onclick="updateRefundStatus('${item.id}', 'refunded')">Mark refunded</button>
          </td>
        </tr>
      `)
      .join("") || `<tr><td colspan="7">${emptyState("No refunds found.")}</td></tr>`;
}

function renderComplaints() {
  const rows = filterRows(state.complaints, ["complaint_type", "status", "priority", "subject"]);
  $("#complaintsTable").innerHTML =
    rows
      .map((item) => `
        <tr>
          <td><strong>${item.complaint_code || item.id}</strong><br><span>${escapeHtml(item.subject || "No subject")}</span></td>
          <td>${capitalize(item.complaint_type || "other")}</td>
          <td>${patientName(item.patient_id)}</td>
          <td>${doctorName(item.doctor_id)}</td>
          <td>${statusPill(item.priority || "medium")}</td>
          <td>${statusPill(item.status || "open")}</td>
          <td>
            <button class="small-button" onclick="updateComplaintStatus('${item.id}', 'under_review')">Review</button>
            <button class="small-button success" onclick="updateComplaintStatus('${item.id}', 'resolved')">Resolve</button>
            <button class="small-button danger" onclick="updateComplaintStatus('${item.id}', 'closed')">Close</button>
          </td>
        </tr>
      `)
      .join("") || `<tr><td colspan="7">${emptyState("No complaints found.")}</td></tr>`;
}

function renderSupport() {
  const rows = filterRows(state.supportTickets, ["ticket_code", "subject", "status", "priority"]);
  $("#supportTable").innerHTML =
    rows
      .map((item) => `
        <tr>
          <td><strong>${item.ticket_code || item.id}</strong><br><span>${escapeHtml(item.subject || "No subject")}</span></td>
          <td>${patientName(item.user_id)}</td>
          <td>${statusPill(item.priority || "medium")}</td>
          <td>${statusPill(item.status || "open")}</td>
          <td>${formatDate(item.created_at)}</td>
          <td>
            <button class="small-button" onclick="updateSupportStatus('${item.id}', 'in_progress')">In progress</button>
            <button class="small-button success" onclick="updateSupportStatus('${item.id}', 'resolved')">Resolve</button>
            <button class="small-button danger" onclick="updateSupportStatus('${item.id}', 'closed')">Close</button>
          </td>
        </tr>
      `)
      .join("") || `<tr><td colspan="6">${emptyState("No support tickets found.")}</td></tr>`;
}

function renderDocuments() {
  const rows = filterRows(state.medicalDocuments, ["document_type", "status", "file_name"]);
  $("#documentsTable").innerHTML =
    rows
      .map((item) => {
        const path = item.storage_path || "";
        const bucket = item.storage_bucket || "medical-documents";
        const link = path ? `${SUPABASE_URL}/storage/v1/object/public/${bucket}/${path}` : "";
        return `
          <tr>
            <td><strong>${escapeHtml(item.file_name || item.id)}</strong><br><span>${escapeHtml(path || "—")}</span></td>
            <td>${patientName(item.patient_id)}</td>
            <td>${capitalize(item.document_type || "other")}</td>
            <td>${statusPill(item.status || "active")}</td>
            <td>${formatDate(item.created_at)}</td>
            <td>
              ${link ? `<a class="small-button" href="${escapeAttribute(link)}" target="_blank" rel="noreferrer">Open</a>` : ""}
              <button class="small-button danger" onclick="updateMedicalDocumentStatus('${item.id}', 'removed')">Remove</button>
            </td>
          </tr>
        `;
      })
      .join("") || `<tr><td colspan="6">${emptyState("No medical documents found.")}</td></tr>`;
}

function renderPrescriptions() {
  const rows = filterRows(state.prescriptions, ["status", "doctor_name", "notes"]);
  $("#prescriptionsTable").innerHTML =
    rows
      .map((item) => `
        <tr>
          <td><strong>${item.id}</strong><br><span>${escapeHtml(item.notes || "No notes")}</span></td>
          <td>${doctorName(item.doctor_id)}</td>
          <td>${patientName(item.patient_id)}</td>
          <td>${statusPill(item.status || "active")}</td>
          <td>${formatDate(item.prescribed_date || item.created_at)}</td>
          <td>
            <button class="small-button danger" onclick="updatePrescriptionStatus('${item.id}', 'completed')">Complete</button>
          </td>
        </tr>
      `)
      .join("") || `<tr><td colspan="6">${emptyState("No prescriptions found.")}</td></tr>`;
}

function renderContent() {
  const pages = state.cmsPages.slice(0, 5).map((item) => listItem(`Page · ${item.slug}`, item.title || "Untitled", statusPill(item.status || "draft")));
  const banners = state.appBanners.slice(0, 5).map((item) => listItem(`Banner · ${item.title}`, item.audience || "all", statusPill(item.is_active ? "approved" : "pending")));
  const tips = state.healthTips.slice(0, 5).map((item) => listItem(`Health tip · ${item.title}`, item.category || "general", statusPill(item.status || "draft")));
  $("#contentList").innerHTML = [...pages, ...banners, ...tips].join("") || emptyState("No CMS content yet.");
}

function renderReports() {
  const today = new Date();
  const isToday = (dateValue) => {
    if (!dateValue) return false;
    const d = new Date(dateValue);
    return d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate();
  };

  const totalRevenue = state.payments.filter((p) => normalizeStatus(p.status) === "completed").reduce((sum, p) => sum + Number(p.amount || 0), 0);
  const todayAppointments = state.appointments.filter((a) => isToday(a.appointment_date)).length;
  const completedConsultations = state.consultations.filter((c) => normalizeStatus(c.status) === "completed").length;
  const cancelledAppointments = state.appointments.filter((a) => normalizeStatus(a.status) === "cancelled").length;
  const lowRatedDoctors = state.reviews.filter((r) => Number(r.rating || 0) <= 2).length;
  const activeUsers = state.profiles.filter((p) => !p.deactivated).length;

  $("#reportMetrics").innerHTML = [
    metricCard("Daily appointments", todayAppointments, "Today bookings"),
    metricCard("Monthly revenue", `GHS ${totalRevenue.toFixed(2)}`, "Completed payments"),
    metricCard("Consultations completed", completedConsultations, "All time"),
    metricCard("Cancelled appointments", cancelledAppointments, "Operational risk"),
    metricCard("Low-rated reviews", lowRatedDoctors, "Needs QA review"),
    metricCard("Active users", activeUsers, "Patients + doctors + admins"),
  ].join("");
}

function renderPatients() {
  const patients = filterRows(
    state.profiles.filter((profile) => !["doctor", "admin", "superadmin"].includes(profile.role)),
    ["first_name", "last_name", "email", "phone"],
  );

  $("#patientGrid").innerHTML =
    patients
      .map((patient) => {
        const visits = state.appointments.filter((appointment) => appointment.user_id === patient.id).length;
        return `
          <article class="patient-card">
            <div class="patient-top">
              ${profileAvatar(patient, fullName(patient))}
              <div>
                <h2>${fullName(patient)}</h2>
                <p>${patient.email || "No email"} · ${patient.phone || "No phone"}</p>
              </div>
            </div>
            <div class="doctor-meta">
              <div><span>Appointments</span><strong>${visits}</strong></div>
              <div><span>Joined</span><strong>${formatDate(patient.created_at)}</strong></div>
            </div>
            <div class="actions-row">
              <button class="small-button danger" onclick="togglePatient('${patient.id}')">${patient.deactivated ? "Reactivate" : "Deactivate"}</button>
            </div>
          </article>
        `;
      })
      .join("") || emptyState("No patient accounts found.");
}

function renderReviews() {
  const reviews = filterRows(state.reviews, ["patient_name", "review_text", "status"]);
  $("#reviewGrid").innerHTML =
    reviews
      .map((review) => `
        <article class="doctor-card">
          <div class="doctor-top">
            <div class="avatar">${review.rating || 0}</div>
            <div>
              <h2>${review.patient_name || "Patient review"}</h2>
              <p>${doctorName(review.doctor_id)} · ${formatDate(review.created_at)}</p>
            </div>
          </div>
          <p>${review.review_text || review.comment || "No written comment."}</p>
          <div class="actions-row">
            ${statusPill(review.status || "pending")}
            <button class="small-button" onclick="updateReviewStatus('${review.id}', 'approved')">Approve</button>
            <button class="small-button danger" onclick="updateReviewStatus('${review.id}', 'rejected')">Reject</button>
            <button class="small-button danger" onclick="deleteReview('${review.id}')">Delete</button>
          </div>
        </article>
      `)
      .join("") || emptyState("No reviews found.");
}

function renderNotifications() {
  $("#notificationList").innerHTML =
    state.notifications
      .slice()
      .sort((a, b) => new Date(b.created_at || 0) - new Date(a.created_at || 0))
      .map((item) => listItem(item.title || "Announcement", item.message || item.body || "", `<span>${relativeDate(item.created_at)}</span>`))
      .join("") || emptyState("No notifications yet.");
}

function renderSettings() {
  const current = state.settings[0] || {};
  $("#defaultFee").value = current.default_fee || "";
  $("#platformCommission").value = current.platform_commission || "";
  $("#settingsList").innerHTML = [
    listItem("Default consultation fee", `GHS ${Number(current.default_fee || 0).toFixed(2)}`, statusPill("confirmed")),
    listItem("Platform commission", `${Number(current.platform_commission || 0).toFixed(1)}%`, statusPill("confirmed")),
    listItem("Supabase project", "mkfcyhfmbncuoswyurgh", statusPill(state.usingPreview ? "pending" : "approved")),
    ...state.specialties.map((specialty) =>
      listItem(
        specialty.name,
        specialty.active === false ? "Hidden from app" : "Available in app",
        `<button class="small-button ${specialty.active === false ? "success" : "danger"}" onclick="toggleSpecialty('${specialty.id}')">${specialty.active === false ? "Enable" : "Disable"}</button>`,
      ),
    ),
  ].join("");
}

function renderAudit() {
  const rows = filterRows(state.auditLog, ["action", "target_table", "target_id"]);
  $("#auditTable").innerHTML =
    rows
      .slice(0, 150)
      .map((entry) => {
        const details = entry.details || {};
        const admin = details.admin_email || adminName(entry.admin_id);
        return `
          <tr>
            <td><strong>${humanAction(entry.action)}</strong></td>
            <td>${entry.target_table || "platform"}<br><span>${entry.target_id || "—"}</span></td>
            <td>${admin || "System"}</td>
            <td>${formatDate(entry.created_at)}</td>
            <td><span>${escapeHtml(summaryFromDetails(details))}</span></td>
          </tr>
        `;
      })
      .join("") || `<tr><td colspan="5">${emptyState("No admin actions recorded yet.")}</td></tr>`;
}

function adminName(id) {
  const admin = state.profiles.find((profile) => profile.id === id);
  return admin ? fullName(admin) : "";
}

async function updateDoctorStatus(id, status) {
  const doctor = state.doctors.find((item) => item.id === id);
  if (!doctor) return;
  if (status === "approved" && !doctor.license_document_path) {
    const proceed = confirm("This doctor has no uploaded license document. Approve anyway?");
    if (!proceed) return;
  }
  const approvalNote =
    status === "approved"
      ? "Document reviewed and approved by KazHealth admin."
      : prompt("Reason for rejecting this doctor?", doctor.approval_note || "Document could not be verified.") ||
        "Document could not be verified.";
  const updates = doctorApprovalUpdates(status, approvalNote);

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("profiles").update(updates).eq("id", id);
    if (error) return toast(error.message);
    await ensureDoctorDirectoryRow(doctor);
    await notifyUser({
      userId: id,
      title: status === "approved" ? "Your doctor profile is approved" : "Doctor verification update",
      message:
        status === "approved"
          ? "Your license has been verified. You can now appear to patients and receive consultation requests."
          : `Your doctor profile was not approved. Reason: ${approvalNote}`,
      targetRole: "doctor",
      type: "verification",
      relatedId: id,
    });
    await logAdminAction(`${status}_doctor`, "profiles", id, {
      doctor_name: fullDoctorName(doctor),
      doctor_email: doctor.email,
      approval_note: approvalNote,
    });
  }

  Object.assign(doctor, updates);
  const profile = state.profiles.find((item) => item.id === id);
  if (profile) {
    Object.assign(profile, updates);
  }
  render();
  toast(`Doctor ${status}`);
}

// ── DOCTOR DOCUMENT REVIEW ────────────────────────────────────────────────
let _reviewingDoctorId = null;

function viewDoctorDocument(id) {
  const doctor = state.doctors.find((item) => item.id === id);
  if (!doctor) {
    toast("Doctor not found");
    return;
  }

  const documentPath = String(doctor.license_document_path || "").trim();
  if (!documentPath) {
    toast("No verification document uploaded");
    return;
  }

  _reviewingDoctorId = id;
  let documentUrl = documentPath;

  // If it's a Supabase storage path (not a full URL), construct public URL
  if (!documentPath.startsWith("http://") && !documentPath.startsWith("https://")) {
    documentUrl = `${SUPABASE_URL}/storage/v1/object/public/doctor-documents/${documentPath}`;
  }

  // Populate modal
  $("#docFrame").src = documentUrl;
  $("#reviewDoctorName").textContent = fullDoctorName(doctor);
  $("#reviewSpecialty").textContent = doctor.specialty || "General Practice";
  $("#reviewExperience").textContent = doctor.experience || "Not specified";
  $("#reviewNotes").value = doctor.approval_note || "";

  // Show modal
  $("#docReviewModal").classList.remove("hidden");
}

function closeDoctorReview() {
  _reviewingDoctorId = null;
  $("#docReviewModal").classList.add("hidden");
  $("#docFrame").src = "";
  $("#reviewNotes").value = "";
}

async function approveFromReview() {
  if (!_reviewingDoctorId) return;
  const notes = $("#reviewNotes").value || "Document reviewed and approved by KazHealth admin.";
  const doctor = state.doctors.find((d) => d.id === _reviewingDoctorId);
  if (!doctor) return;
  const updates = doctorApprovalUpdates("approved", notes);
  
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error: updateError } = await db.from("profiles").update(updates).eq("id", _reviewingDoctorId);
    if (updateError) return toast(updateError.message);
    await ensureDoctorDirectoryRow(doctor);

    await notifyUser({
      userId: _reviewingDoctorId,
      title: "Your profile is approved",
      message: "Your license has been verified. You're now visible to patients in the app and can accept consultation requests.",
      targetRole: "doctor",
      type: "verification",
      relatedId: _reviewingDoctorId,
    });
    await logAdminAction("approved_doctor", "profiles", _reviewingDoctorId, {
      doctor_name: fullDoctorName(doctor),
      doctor_email: doctor.email,
      approval_note: notes,
    });
  }

  Object.assign(doctor, updates);
  const profile = state.profiles.find((p) => p.id === _reviewingDoctorId);
  if (profile) {
    Object.assign(profile, updates);
  }

  closeDoctorReview();
  render();
  toast("✓ Doctor approved! Notification sent. Now visible to patients.");
}

async function rejectFromReview() {
  if (!_reviewingDoctorId) return;
  const reason = $("#reviewNotes").value || "Document could not be verified. Please resubmit.";
  const doctor = state.doctors.find((d) => d.id === _reviewingDoctorId);
  if (!doctor) return;
  const updates = doctorApprovalUpdates("rejected", reason);

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error: updateError } = await db.from("profiles").update(updates).eq("id", _reviewingDoctorId);
    if (updateError) return toast(updateError.message);

    await notifyUser({
      userId: _reviewingDoctorId,
      title: "Document needs revision",
      message: `Your license document could not be verified. Reason: ${reason}`,
      targetRole: "doctor",
      type: "verification",
      relatedId: _reviewingDoctorId,
    });
    await logAdminAction("rejected_doctor", "profiles", _reviewingDoctorId, {
      doctor_name: fullDoctorName(doctor),
      doctor_email: doctor.email,
      rejection_reason: reason,
    });
  }

  Object.assign(doctor, updates);
  const profile = state.profiles.find((p) => p.id === _reviewingDoctorId);
  if (profile) {
    Object.assign(profile, updates);
  }

  closeDoctorReview();
  render();
  toast("✗ Doctor rejected. They can resubmit a new document.");
}

async function updateAppointmentStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("appointments").update({ status, updated_at: new Date().toISOString() }).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_appointment_status", "appointments", id, { status });
  }

  const appointment = state.appointments.find((item) => item.id === id);
  if (appointment) appointment.status = status;
  render();
  toast(`Appointment marked ${status}`);
}

async function updatePayment(id, updates) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("payments").update(updates).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_payment", "payments", id, updates);
  }

  const payment = state.payments.find((item) => item.id === id);
  if (payment) Object.assign(payment, updates);
  renderActiveView();
  toast("Payment updated");
}

async function updateReviewStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("reviews").update({ status, approved: status === "approved" }).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("updated_review_status", "reviews", id, { status });
  }

  const review = state.reviews.find((item) => item.id === id);
  if (review) {
    review.status = status;
    review.approved = status === "approved";
  }
  renderReviews();
  toast(`Review ${status}`);
}

async function deleteReview(id) {
  if (!confirm("Delete this review?")) return;
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("reviews").delete().eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction("deleted_review", "reviews", id, {});
  }
  state.reviews = state.reviews.filter((item) => item.id !== id);
  renderReviews();
  toast("Review deleted");
}

async function togglePatient(id) {
  const patient = state.profiles.find((item) => item.id === id);
  if (!patient) return;
  const deactivated = !patient.deactivated;

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("profiles").update({ deactivated }).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction(deactivated ? "deactivated_patient" : "reactivated_patient", "profiles", id, {});
  }

  patient.deactivated = deactivated;
  renderPatients();
  toast(deactivated ? "Patient deactivated" : "Patient reactivated");
}

async function toggleDoctor(id) {
  const doctor = state.doctors.find((item) => item.id === id);
  const profile = state.profiles.find((item) => item.id === id);
  if (!doctor && !profile) return;
  const currentlySuspended = isDoctorSuspended(doctor || profile);
  const deactivated = !currentlySuspended;
  const isActive = !deactivated && normalizeStatus((doctor || profile).approval_status) === "approved";

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db
      .from("profiles")
      .update({ deactivated, is_active: isActive, updated_at: new Date().toISOString() })
      .eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction(deactivated ? "suspended_doctor" : "reactivated_doctor", "profiles", id, {
      doctor_name: fullDoctorName(doctor || profile),
    });
  }

  if (doctor) doctor.deactivated = deactivated;
  if (doctor) doctor.is_active = isActive;
  if (profile) {
    profile.deactivated = deactivated;
    profile.is_active = isActive;
  }
  renderDoctors();
  toast(deactivated ? "Doctor suspended" : "Doctor reactivated");
}

async function copyDoctorEmail(id) {
  const doctor = state.doctors.find((item) => item.id === id);
  if (!doctor?.email) {
    toast("Doctor email is not available");
    return;
  }

  try {
    await navigator.clipboard.writeText(doctor.email);
    toast("Doctor email copied");
  } catch (_) {
    toast(doctor.email);
  }
}

async function addSampleDoctor() {
  const doctor = {
    id: crypto.randomUUID(),
    first_name: "Dr. Nana",
    last_name: "Owusu",
    email: `nana.owusu+${Date.now()}@kazhealth.com`,
    phone: "+233 55 700 1188",
    role: "doctor",
    specialty: "Paediatrician",
    experience: "9 years",
    consultation_fee: 160,
    approval_status: "pending",
    created_at: new Date().toISOString(),
  };

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("profiles").insert(doctor);
    if (error) return toast(error.message);
    await logAdminAction("created_sample_doctor", "profiles", doctor.id, {
      doctor_name: fullDoctorName(doctor),
      doctor_email: doctor.email,
    });
  }

  state.profiles.unshift(doctor);
  state.doctors.unshift(doctorsFromProfiles([doctor])[0]);
  render();
  toast("Sample doctor added to review queue");
}

async function sendNotification(event) {
  event.preventDefault();
  const message = $("#notificationMessage").value.trim();
  if (!message) return;
  const targetRole = $("#notificationTarget").value;
  const createdAt = new Date().toISOString();
  const recipients = notificationRecipients(targetRole);

  if (!recipients.length) {
    toast("No recipients found for this announcement");
    return;
  }

  const notifications = recipients.map((profile) => ({
    id: crypto.randomUUID(),
    user_id: profile.id,
    title: "Platform announcement",
    message,
    target_role: targetRole,
    type: "announcement",
    is_read: false,
    created_at: createdAt,
  }));

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("notifications").insert(notifications);
    if (error) return toast(error.message);
    await logAdminAction("sent_notification", "notifications", notifications[0].id, {
      target_role: targetRole,
      recipient_count: notifications.length,
      message,
    });
  }

  state.notifications.unshift(...notifications);
  event.target.reset();
  renderNotifications();
  showAnnouncementPopup({
    count: notifications.length,
    targetRole,
    message,
  });
}

function notificationRecipients(targetRole) {
  return state.profiles.filter((profile) => {
    if (!profile?.id) return false;
    if (profile.deactivated) return false;
    if (targetRole === "all") return ["patient", "doctor", "admin", "superadmin"].includes(profile.role);
    return profile.role === targetRole;
  });
}

let announcementPopupTimer = null;

function showAnnouncementPopup({ count, targetRole, message }) {
  const popup = $("#announcePopup");
  if (!popup) return;

  $("#announcePopupTitle").textContent = `Delivered to ${count} recipient${count === 1 ? "" : "s"}`;
  $("#announcePopupCopy").textContent =
    targetRole === "all"
      ? "Your announcement has been distributed across the platform and will appear in user notifications."
      : `Your announcement has been targeted to ${audienceLabel(targetRole).toLowerCase()} and is now waiting in their notification inbox.`;
  $("#announcePopupAudience").textContent = audienceLabel(targetRole);
  $("#announcePopupCount").textContent = String(count);
  $("#announcePopupPreview").textContent = message;

  popup.classList.remove("hidden");

  if (announcementPopupTimer) clearTimeout(announcementPopupTimer);
  announcementPopupTimer = setTimeout(() => {
    hideAnnouncementPopup();
  }, 4200);
}

function hideAnnouncementPopup() {
  const popup = $("#announcePopup");
  if (!popup) return;
  popup.classList.add("hidden");
  if (announcementPopupTimer) {
    clearTimeout(announcementPopupTimer);
    announcementPopupTimer = null;
  }
}

function focusNotificationComposer() {
  hideAnnouncementPopup();
  window.location.hash = "notifications";
  state.view = "notifications";
  render();
  $("#notificationMessage")?.focus();
}

function audienceLabel(targetRole) {
  switch (targetRole) {
    case "patient":
      return "Patients";
    case "doctor":
      return "Doctors";
    case "admin":
      return "Admins";
    default:
      return "All users";
  }
}

async function saveCmsPage(event) {
  event.preventDefault();
  const slug = $("#cmsSlug").value.trim().toLowerCase();
  const title = $("#cmsTitle").value.trim();
  const content = $("#cmsContent").value.trim();
  if (!slug || !title || !content) return;

  const page = {
    id: crypto.randomUUID(),
    slug,
    title,
    content,
    status: "published",
    updated_at: new Date().toISOString(),
    created_by: state.session?.user?.id || null,
  };

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { data, error } = await db.from("cms_pages").upsert(page).select().single();
    if (error) return toast(error.message);
    Object.assign(page, data || {});
    await logAdminAction("updated_cms_page", "cms_pages", page.id, { slug, title });
  }

  state.cmsPages = [page, ...state.cmsPages.filter((item) => item.slug !== slug)];
  event.target.reset();
  renderContent();
  toast("CMS page saved");
}

async function saveBanner(event) {
  event.preventDefault();
  const title = $("#bannerTitle").value.trim();
  const imageUrl = $("#bannerImageUrl").value.trim();
  const audience = $("#bannerAudience").value;
  if (!title) return;

  const banner = {
    id: crypto.randomUUID(),
    title,
    image_url: imageUrl || null,
    audience,
    is_active: true,
    created_by: state.session?.user?.id || null,
    created_at: new Date().toISOString(),
  };

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { data, error } = await db.from("app_banners").insert(banner).select().single();
    if (error) return toast(error.message);
    Object.assign(banner, data || {});
    await logAdminAction("created_banner", "app_banners", banner.id, { title, audience });
  }

  state.appBanners.unshift(banner);
  event.target.reset();
  renderContent();
  toast("Banner published");
}

async function saveHealthTip(event) {
  event.preventDefault();
  const title = $("#healthTipTitle").value.trim();
  const body = $("#healthTipBody").value.trim();
  if (!title || !body) return;

  const tip = {
    id: crypto.randomUUID(),
    title,
    body,
    audience: "all",
    status: "published",
    created_by: state.session?.user?.id || null,
    created_at: new Date().toISOString(),
  };

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { data, error } = await db.from("health_tips").insert(tip).select().single();
    if (error) return toast(error.message);
    Object.assign(tip, data || {});
    await logAdminAction("created_health_tip", "health_tips", tip.id, { title });
  }

  state.healthTips.unshift(tip);
  event.target.reset();
  renderContent();
  toast("Health tip saved");
}

function exportCsv(name, rows) {
  if (!rows || !rows.length) {
    toast(`No ${name} data to export`);
    return;
  }
  const keys = Array.from(new Set(rows.flatMap((row) => Object.keys(row || {}))));
  const escape = (value) => `"${String(value ?? "").replaceAll('"', '""')}"`;
  const header = keys.join(",");
  const lines = rows.map((row) => keys.map((key) => escape(row[key])).join(","));
  const csv = [header, ...lines].join("\n");

  const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = `${name}_${new Date().toISOString().slice(0, 10)}.csv`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
  toast(`${name} CSV exported`);
}

async function saveSettings(event) {
  event.preventDefault();
  const settings = {
    id: 1,
    default_fee: Number($("#defaultFee").value || 0),
    platform_commission: Number($("#platformCommission").value || 0),
  };

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    settings.updated_at = new Date().toISOString();
    const { error } = await db.from("settings").upsert(settings);
    if (error) return toast(error.message);
    await logAdminAction("updated_settings", "settings", "00000000-0000-0000-0000-000000000001", settings);
  }

  state.settings = [settings];
  renderSettings();
  toast("Settings saved");
}

async function addSpecialty(event) {
  event.preventDefault();
  const name = $("#specialtyName").value.trim();
  if (!name) return;
  const specialty = { id: crypto.randomUUID(), name, active: true };

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { data, error } = await db.from("specialties").insert({ name, active: true }).select().single();
    if (error) return toast(error.message);
    Object.assign(specialty, data);
    await logAdminAction("created_specialty", "specialties", specialty.id, { name });
  }

  state.specialties.push(specialty);
  event.target.reset();
  renderSettings();
  toast("Specialty added");
}

async function toggleSpecialty(id) {
  const specialty = state.specialties.find((item) => item.id === id);
  if (!specialty) return;
  const active = specialty.active === false;

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("specialties").update({ active }).eq("id", id);
    if (error) return toast(error.message);
    await logAdminAction(active ? "enabled_specialty" : "disabled_specialty", "specialties", id, {
      name: specialty.name,
    });
  }

  specialty.active = active;
  renderSettings();
  toast(active ? "Specialty enabled" : "Specialty disabled");
}

function doctorApprovalUpdates(status, note) {
  return {
    approval_status: status,
    approval_note: note,
    is_doctor: true,
    is_patient: false,
    is_doctor_approved: status === "approved",
    is_active: status === "approved",
    deactivated: false,
    updated_at: new Date().toISOString(),
  };
}

async function ensureDoctorDirectoryRow(doctor) {
  if (!db || !doctor?.id) return;
  const { error } = await db.from("doctors").upsert({
    id: doctor.id,
    rating: Number(doctor.rating || 0),
    review_count: Number(doctor.review_count || 0),
  });
  if (error) console.warn("Doctor directory upsert failed:", error.message);
}

async function notifyUser({
  userId,
  title,
  message,
  targetRole = "all",
  type = "admin",
  relatedId = "",
}) {
  if (!db) return;
  const notification = {
    id: crypto.randomUUID(),
    user_id: userId || null,
    title,
    message,
    target_role: targetRole,
    type,
    related_id: relatedId || null,
    is_read: false,
    created_at: new Date().toISOString(),
  };
  const { error } = await db.from("notifications").insert(notification);
  if (error) {
    console.warn("Notification insert failed:", error.message);
    return;
  }
  state.notifications.unshift(notification);
}

async function logAdminAction(action, targetTable, targetId, details = {}) {
  if (!db) return;
  const entry = {
    id: crypto.randomUUID(),
    admin_id: state.session?.user?.id || null,
    action,
    target_table: targetTable,
    target_id: targetId || null,
    details: {
      ...details,
      admin_email: state.session?.user?.email || "superadmin@docconsult.app",
      timestamp: new Date().toISOString(),
    },
    created_at: new Date().toISOString(),
  };
  const { error } = await db.from("audit_log").insert(entry);
  if (error) {
    console.warn("Audit log insert failed:", error.message);
    return;
  }
  state.auditLog.unshift(entry);
}

function normalizeDoctors(rows) {
  return rows.map((doctor) => ({
    ...doctor,
    name: doctor.name || fullName(doctor),
    profile_image: doctor.profile_image || doctor.image_url || doctor.avatar_url || "",
    consultation_fee: Number(doctor.consultation_fee || doctor.consultationFee || 0),
  }));
}

function mergeDoctorRows(profiles, doctorRows) {
  const doctorMetaById = new Map(doctorRows.map((doctor) => [doctor.id, doctor]));
  const profileDoctors = doctorsFromProfiles(profiles).map((profileDoctor) =>
    normalizeDoctors([{ ...profileDoctor, ...(doctorMetaById.get(profileDoctor.id) || {}) }])[0],
  );
  const profileIds = new Set(profileDoctors.map((doctor) => doctor.id));
  const standaloneDoctors = normalizeDoctors(doctorRows).filter((doctor) => !profileIds.has(doctor.id));
  return [...profileDoctors, ...standaloneDoctors];
}

function doctorsFromProfiles(profiles) {
  return profiles
    .filter((profile) => profile.role === "doctor")
    .map((profile) => ({
      ...profile,
      name: fullName(profile),
      profile_image: profile.profile_image || profile.image_url || "",
      consultation_fee: Number(profile.consultation_fee || 0),
      approval_status: profile.approval_status || "pending",
      source: "profiles",
    }));
}

function updateConnectionStatus() {
  if (state.usingPreview) {
    updateConnection("offline", "Preview data", "Supabase tables are empty or blocked");
  } else if (!db) {
    updateConnection("offline", "Preview data", "Supabase client unavailable");
  } else {
    const roleSuffix = state.session ? ` · ${state.adminRoleName}` : "";
    updateConnection("online", "Supabase connected", state.session ? `Authenticated session${roleSuffix}` : "Anon access active");
  }
}

async function loadAdminAccessContext() {
  if (!db || !state.session?.user?.id) {
    state.adminRoleCode = "super_admin";
    state.adminRoleName = "Super Admin";
    state.adminPermissions = new Set(rolePermissionFallback.super_admin);
    return;
  }

  const userId = state.session.user.id;
  try {
    const [{ data: profile }, { data: adminUser }] = await Promise.all([
      db.from("profiles").select("id, first_name, last_name, email").eq("id", userId).maybeSingle(),
      db
        .from("admin_users")
        .select("role_id, is_active, admin_roles(code, name)")
        .eq("id", userId)
        .maybeSingle(),
    ]);

    state.adminProfile = profile || null;
    if (!adminUser?.is_active) {
      state.adminRoleCode = "super_admin";
      state.adminRoleName = "Super Admin";
      state.adminPermissions = new Set(rolePermissionFallback.super_admin);
      return;
    }

    const roleCode = String(adminUser.admin_roles?.code || state.session.user.user_metadata?.admin_role || "super_admin").toLowerCase();
    const roleName = String(adminUser.admin_roles?.name || roleCode.replaceAll("_", " "));

    let permissions = [];
    if (adminUser.role_id) {
      const { data: rolePerms } = await db
        .from("admin_role_permissions")
        .select("admin_permissions(code)")
        .eq("role_id", adminUser.role_id);
      permissions = (rolePerms || [])
        .map((item) => item.admin_permissions?.code)
        .filter(Boolean);
    }

    state.adminRoleCode = roleCode;
    state.adminRoleName = titleCase(roleName);
    state.adminPermissions = new Set(permissions.length ? permissions : rolePermissionFallback[roleCode] || rolePermissionFallback.super_admin);
  } catch (error) {
    console.warn("Unable to load admin access context:", error?.message || error);
    state.adminRoleCode = "super_admin";
    state.adminRoleName = "Super Admin";
    state.adminPermissions = new Set(rolePermissionFallback.super_admin);
  }
}

function applyViewPermissions() {
  $$(".nav-item").forEach((button) => {
    const view = button.dataset.view;
    button.classList.toggle("hidden", !canAccessView(view));
  });

  $$(".nav-group").forEach((group) => {
    const visibleItems = group.querySelectorAll(".nav-item:not(.hidden)");
    group.classList.toggle("hidden", visibleItems.length === 0);
  });
}

function canAccessView(view) {
  const required = viewPermissionMap[view];
  if (!required || !required.length) return true;
  if (state.adminRoleCode === "super_admin") return true;
  return required.some((permission) => state.adminPermissions.has(permission));
}

function firstAllowedView() {
  const first = $$(".nav-item").find((item) => canAccessView(item.dataset.view));
  return first?.dataset.view || "dashboard";
}

function titleCase(value) {
  return String(value || "")
    .split(/\s+/)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

function updateConnection(mode, label, detail) {
  $("#connectionDot").className = `status-dot ${mode}`;
  $("#connectionLabel").textContent = label;
  $("#connectionDetail").textContent = detail;
  const badge = $("#realtimeBadge");
  if (badge) badge.classList.toggle("hidden", mode !== "online");
}

function metricCard(label, value, detail) {
  return `<article class="metric-card"><span>${label}</span><strong>${value}</strong><small>${detail}</small></article>`;
}

function doctorStat(label, value, helper) {
  return `<article class="doctor-stat"><span>${label}</span><strong>${value}</strong><small>${helper}</small></article>`;
}

function doctorMatchesFilter(doctor) {
  if (state.doctorFilter === "all") return true;
  if (state.doctorFilter === "suspended") return isDoctorSuspended(doctor);
  return normalizeStatus(doctor.approval_status) === state.doctorFilter && !isDoctorSuspended(doctor);
}

function isDoctorSuspended(doctor) {
  return Boolean(doctor?.deactivated) || doctor?.is_active === false;
}

function listItem(title, detail, badge) {
  return `<div class="list-item"><div><strong>${title}</strong><span>${detail}</span></div>${badge}</div>`;
}

function statusPill(status = "pending") {
  const normalized = normalizeStatus(status);
  return `<span class="status ${normalized}">${capitalize(normalized)}</span>`;
}

function emptyState(message) {
  return `<div class="list-item"><div><strong>${message}</strong><span>Refresh after Supabase has rows or use preview data.</span></div></div>`;
}

function humanAction(action = "") {
  return String(action).replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function summaryFromDetails(details = {}) {
  if (!details || typeof details !== "object") return "";
  if (details.doctor_name) return `${details.doctor_name}${details.approval_note ? ` · ${details.approval_note}` : ""}`;
  if (details.doctor_email) return details.doctor_email;
  if (details.message) return details.message;
  if (details.status) return `Status: ${details.status}`;
  if (details.name) return details.name;
  const keys = Object.keys(details).filter((key) => !["timestamp", "admin_email"].includes(key));
  return keys.slice(0, 3).map((key) => `${key}: ${details[key]}`).join(" · ");
}

function filterRows(rows, keys) {
  if (!state.search) return rows;
  return rows.filter((row) =>
    keys.some((key) => String(row[key] || "").toLowerCase().includes(state.search)),
  );
}

function fullName(profile) {
  return `${profile.first_name || ""} ${profile.last_name || ""}`.trim() || profile.name || profile.email || "Unnamed user";
}

function fullDoctorName(doctor) {
  return doctor.name || fullName(doctor) || doctor.email || "Unnamed doctor";
}

function doctorName(id) {
  const doctor = state.doctors.find((item) => item.id === id);
  return doctor ? fullDoctorName(doctor) : "Assigned doctor";
}

function patientName(id) {
  const patient = state.profiles.find((item) => item.id === id);
  return patient ? fullName(patient) : "Patient";
}

function initials(name) {
  return String(name || "DC")
    .split(/\s+/)
    .map((part) => part[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

function profileAvatar(person, name) {
  const imageUrl = String(person.profile_image || person.image_url || person.avatar_url || "").trim();
  if (imageUrl.startsWith("http://") || imageUrl.startsWith("https://")) {
    return `<img class="avatar avatar-image" src="${escapeAttribute(imageUrl)}" alt="${escapeAttribute(name)} profile picture" loading="lazy" />`;
  }
  return `<div class="avatar">${initials(name)}</div>`;
}

function escapeAttribute(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

function normalizeStatus(status = "pending") {
  return String(status || "pending").toLowerCase();
}

function capitalize(value) {
  const text = String(value || "");
  return text.charAt(0).toUpperCase() + text.slice(1);
}

function formatDate(value) {
  if (!value) return "Not scheduled";
  return new Intl.DateTimeFormat("en-GH", {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

function relativeDate(value) {
  if (!value) return "Just now";
  const minutes = Math.max(1, Math.round((Date.now() - new Date(value).getTime()) / 60000));
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return `${Math.round(hours / 24)}d ago`;
}

function averageRating(doctorId) {
  const reviews = state.reviews.filter((review) => review.doctor_id === doctorId);
  if (!reviews.length) return "4.8";
  const total = reviews.reduce((sum, review) => sum + Number(review.rating || 0), 0);
  return (total / reviews.length).toFixed(1);
}

function pageTitle(view) {
  return {
    dashboard: "Platform Overview",
    doctors: "Doctor Management",
    appointments: "Appointment Operations",
    consultations: "Consultation Management",
    payments: "Payments & Payouts",
    payouts: "Payout Management",
    refunds: "Refund Management",
    patients: "Patient Accounts",
    reviews: "Review Moderation",
    complaints: "Complaints & Disputes",
    support: "Support Tickets",
    documents: "Medical Document Management",
    prescriptions: "Prescription Records",
    notifications: "Notifications",
    content: "CMS Content",
    reports: "Reports & Analytics",
    settings: "Platform Settings",
    audit: "Audit Logs",
  }[view] || "Platform Overview";
}

function stripTags(html) {
  const element = document.createElement("div");
  element.innerHTML = html;
  return element.textContent || "";
}

// ── REALTIME ─────────────────────────────────────────────────────────────
let _realtimeChannel = null;

function subscribeRealtime() {
  if (!db || _realtimeChannel) return;
  _realtimeChannel = db
    .channel("admin-realtime")
    .on("postgres_changes", { event: "*", schema: "public", table: "appointments" }, async () => {
      state.appointments = await selectTable("appointments");
      renderActiveView();
      toast("Appointments updated in real time");
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "profiles" }, async () => {
      const profiles = await selectTable("profiles");
      const doctors = await selectTable("doctors");
      state.profiles = profiles;
      state.doctors = mergeDoctorRows(profiles, doctors);
      renderActiveView();
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "doctors" }, async () => {
      const profiles = await selectTable("profiles");
      const doctors = await selectTable("doctors");
      state.profiles = profiles;
      state.doctors = mergeDoctorRows(profiles, doctors);
      renderActiveView();
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "payments" }, async () => {
      state.payments = await selectTable("payments");
      renderActiveView();
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "consultations" }, async () => {
      state.consultations = await selectTable("consultations", { orderBy: "created_at", ascending: false });
      renderActiveView();
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "payouts" }, async () => {
      state.payouts = await selectTable("payouts", { orderBy: "created_at", ascending: false });
      renderActiveView();
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "refunds" }, async () => {
      state.refunds = await selectTable("refunds", { orderBy: "created_at", ascending: false });
      renderActiveView();
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "complaints" }, async () => {
      state.complaints = await selectTable("complaints", { orderBy: "created_at", ascending: false });
      renderActiveView();
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "support_tickets" }, async () => {
      state.supportTickets = await selectTable("support_tickets", { orderBy: "created_at", ascending: false });
      renderActiveView();
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "reviews" }, async () => {
      state.reviews = await selectTable("reviews");
      renderActiveView();
    })
    .on("postgres_changes", { event: "*", schema: "public", table: "audit_log" }, async () => {
      state.auditLog = await selectTable("audit_log", { orderBy: "created_at", ascending: false });
      renderActiveView();
    })
    .subscribe((status) => {
      if (status === "SUBSCRIBED") {
        updateConnection("online", "Supabase live", "Realtime sync active");
      } else if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
        updateConnection("offline", "Sync paused", "Realtime channel error — refresh to retry");
      }
    });
}

function toast(message) {
  const element = $("#toast");
  element.textContent = message;
  element.classList.add("show");
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => element.classList.remove("show"), 3200);
}
