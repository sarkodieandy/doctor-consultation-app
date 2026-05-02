const SUPABASE_URL = "https://mkfcyhfmbncuoswyurgh.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1rZmN5aGZtYm5jdW9zd3l1cmdoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxNjc0ODQsImV4cCI6MjA3ODc0MzQ4NH0.rvZEtonSpYD32l3vraU_pNkfcV6uLg0Coo5N9-hpDDY";

const db = window.supabase
  ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;

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
  payments: [],
  reviews: [],
  notifications: [],
  settings: [],
  specialties: [],
};

const preview = {
  profiles: [
    {
      id: "user_patient_1",
      first_name: "Akua",
      last_name: "Boateng",
      email: "akua.boateng@example.com",
      phone: "+233 50 123 4567",
      role: "patient",
      created_at: "2026-04-18T10:20:00Z",
    },
    {
      id: "user_patient_2",
      first_name: "Kwame",
      last_name: "Mensah",
      email: "kwame.mensah@example.com",
      phone: "+233 54 233 8831",
      role: "patient",
      created_at: "2026-04-23T09:30:00Z",
    },
    {
      id: "doctor_ama",
      first_name: "Dr. Ama",
      last_name: "Mensah",
      email: "ama.mensah@kazhealth.com",
      phone: "+233 24 445 9012",
      role: "doctor",
      specialty: "Cardiologist",
      consultation_fee: 180,
      experience: "8 years",
      approval_status: "approved",
      mobile_money_provider: "mtn",
      mobile_money_number: "0244459012",
      created_at: "2026-03-20T08:00:00Z",
    },
    {
      id: "doctor_esi",
      first_name: "Dr. Esi",
      last_name: "Addo",
      email: "esi.addo@kazhealth.com",
      phone: "+233 20 881 4433",
      role: "doctor",
      specialty: "Dermatologist",
      consultation_fee: 140,
      experience: "6 years",
      approval_status: "pending",
      created_at: "2026-04-27T12:15:00Z",
    },
  ],
  appointments: [
    {
      id: "appt_1001",
      user_id: "user_patient_1",
      doctor_id: "doctor_ama",
      patient_name: "Akua Boateng",
      doctor_name: "Dr. Ama Mensah",
      speciality: "Cardiologist",
      appointment_date: new Date(Date.now() + 86400000).toISOString(),
      time_slot: "10:00 AM",
      consultation_fee: 180,
      status: "confirmed",
      created_at: new Date(Date.now() - 3600000).toISOString(),
    },
    {
      id: "appt_1002",
      user_id: "user_patient_2",
      doctor_id: "doctor_esi",
      patient_name: "Kwame Mensah",
      doctor_name: "Dr. Esi Addo",
      speciality: "Dermatologist",
      appointment_date: new Date(Date.now() + 172800000).toISOString(),
      time_slot: "2:00 PM",
      consultation_fee: 140,
      status: "pending",
      created_at: new Date(Date.now() - 7200000).toISOString(),
    },
    {
      id: "appt_1003",
      user_id: "user_patient_1",
      doctor_id: "doctor_ama",
      patient_name: "Akua Boateng",
      doctor_name: "Dr. Ama Mensah",
      speciality: "Cardiologist",
      appointment_date: new Date(Date.now() - 86400000).toISOString(),
      time_slot: "4:00 PM",
      consultation_fee: 180,
      status: "completed",
      created_at: new Date(Date.now() - 172800000).toISOString(),
    },
  ],
  payments: [
    {
      id: "pay_001",
      user_id: "user_patient_1",
      doctor_id: "doctor_ama",
      amount: 180,
      status: "completed",
      payment_method: "mobile_money",
      created_at: new Date(Date.now() - 5400000).toISOString(),
    },
    {
      id: "pay_002",
      user_id: "user_patient_2",
      doctor_id: "doctor_esi",
      amount: 140,
      status: "pending",
      payment_method: "card",
      created_at: new Date(Date.now() - 7200000).toISOString(),
    },
  ],
  reviews: [
    {
      id: "rev_1",
      doctor_id: "doctor_ama",
      patient_name: "Akua Boateng",
      rating: 5,
      review_text: "Very clear consultation and good follow up.",
      status: "approved",
      created_at: "2026-04-22T16:00:00Z",
    },
    {
      id: "rev_2",
      doctor_id: "doctor_esi",
      patient_name: "Kwame Mensah",
      rating: 4,
      review_text: "Helpful advice. Waiting time could be better.",
      status: "pending",
      created_at: "2026-04-25T11:00:00Z",
    },
  ],
  notifications: [
    {
      id: "note_1",
      message: "Doctor verification queue reviewed at 9:00 AM.",
      created_at: new Date(Date.now() - 1800000).toISOString(),
    },
  ],
  settings: [{ id: 1, default_fee: 150 }],
  specialties: [
    { id: "spec_1", name: "Cardiologist", active: true },
    { id: "spec_2", name: "Dermatologist", active: true },
    { id: "spec_3", name: "Paediatrician", active: true },
  ],
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
      state.view = view;
      render();
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
  $("#notificationForm").addEventListener("submit", sendNotification);
  $("#settingsForm").addEventListener("submit", saveSettings);
  $("#specialtyForm").addEventListener("submit", addSpecialty);
}

function setInitialView() {
  const view = hashView();
  if (view) state.view = view;
}

function hashView() {
  const value = window.location.hash.replace(/^#\/?/, "");
  return $(`.nav-item[data-view="${value}"]`) ? value : "";
}

function navigate(view) {
  if (!view) return;
  state.view = view;
  window.location.hash = view;
  $("#sidebar").classList.remove("sidebar-open");
  render();
}

async function signIn(event) {
  event.preventDefault();
  const email = resolveLoginEmail($("#adminEmail").value.trim());
  const password = $("#adminPassword").value;
  if (!db) {
    toast("Supabase client unavailable. Check your internet connection and try again.");
    return;
  }
  if (!email || !password) {
    toast("Enter admin username/email and password");
    return;
  }

  const { data, error } = await db.auth.signInWithPassword({ email, password });
  if (error) {
    toast(error.message);
    return;
  }

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
}

function resolveLoginEmail(identifier) {
  const value = identifier.toLowerCase();
  if (value === "superadmin") return "superadmin@docconsult.app";
  return identifier;
}

async function isAdminSession() {
  const email = state.session?.user?.email?.toLowerCase();
  if (email === "superadmin@docconsult.app") return true;

  try {
    const { data, error } = await db
      .from("profiles")
      .select("role,username,email")
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
  state.view = "dashboard";
  window.location.hash = "dashboard";
  await loadData();
  render();
  if (db) subscribeRealtime();
}

function showLogin() {
  document.body.classList.add("logged-out");
  state.view = "dashboard";
  updateConnection("offline", "Signed out", "Login with superadmin");
}

async function loadData() {
  state.usingPreview = false;
  if (!db) {
    state.profiles = [];
    state.doctors = [];
    state.appointments = [];
    state.payments = [];
    state.reviews = [];
    state.notifications = [];
    state.settings = [];
    state.specialties = [];
    return;
  }
  const [profiles, doctors, appointments, payments, reviews, notifications, settings, specialties] =
    await Promise.all([
      selectTable("profiles"),
      selectTable("doctors"),
      selectTable("appointments"),
      selectTable("payments"),
      selectTable("reviews"),
      selectTable("notifications"),
      selectTable("settings"),
      selectTable("specialties"),
    ]);

  state.profiles = profiles;
  state.doctors = mergeDoctorRows(profiles, doctors);
  state.appointments = appointments;
  state.payments = payments;
  state.reviews = reviews;
  state.notifications = notifications;
  state.settings = settings;
  state.specialties = specialties;

}

async function selectTable(table) {
  try {
    const { data, error } = await db.from(table).select("*").limit(500);
    if (error) throw error;
    return data || [];
  } catch (_) {
    return [];
  }
}

function hydratePreview(silent = false) {
  state.usingPreview = true;
  state.profiles = [...preview.profiles];
  state.doctors = doctorsFromProfiles(preview.profiles);
  state.appointments = [...preview.appointments];
  state.payments = [...preview.payments];
  state.reviews = [...preview.reviews];
  state.notifications = [...preview.notifications];
  state.settings = [...preview.settings];
  state.specialties = [...preview.specialties];
  if (!silent) updateConnection("offline", "Preview data", "Supabase tables are empty or blocked");
}

function render() {
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
    payments: renderPayments,
    patients: renderPatients,
    reviews: renderReviews,
    notifications: renderNotifications,
    settings: renderSettings,
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
  const patients = state.profiles.filter((profile) => profile.role !== "doctor");
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
  const suspended = state.doctors.filter((doctor) => doctor.deactivated).length;
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
                  <span class="status ${doctor.deactivated ? "cancelled" : status}">${doctor.deactivated ? "Suspended" : capitalize(status)}</span>
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
              <button class="small-button danger" onclick="toggleDoctor('${doctor.id}')">${doctor.deactivated ? "Reactivate" : "Suspend"}</button>
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
  const completed = state.payments.filter((payment) => normalizeStatus(payment.status) === "completed");
  const pending = state.payments.filter((payment) => normalizeStatus(payment.status) === "pending");
  const completedTotal = completed.reduce((sum, payment) => sum + Number(payment.amount || 0), 0);
  const pendingTotal = pending.reduce((sum, payment) => sum + Number(payment.amount || 0), 0);

  $("#paymentSummary").innerHTML = [
    listItem("Completed revenue", `GHS ${completedTotal.toFixed(2)}`, statusPill("completed")),
    listItem("Pending collection", `GHS ${pendingTotal.toFixed(2)}`, statusPill("pending")),
    listItem("Transactions", `${state.payments.length} payment records`, statusPill("confirmed")),
  ].join("");

  $("#payoutList").innerHTML =
    state.doctors
      .map((doctor) => {
        const ready = doctor.mobile_money_number || doctor.payout_recipient_code;
        return listItem(
          fullDoctorName(doctor),
          ready ? "Payout details ready" : "Needs payout details",
          statusPill(ready ? "approved" : "pending"),
        );
      })
      .join("") || emptyState("No payout records yet.");

  $("#paymentsTable").innerHTML =
    filterRows(state.payments, ["status", "payment_method", "payout_status"])
      .map((payment) => `
        <tr>
          <td>${patientName(payment.user_id)}</td>
          <td>${doctorName(payment.doctor_id)}</td>
          <td>GHS ${Number(payment.amount || 0).toFixed(2)}</td>
          <td>${statusPill(payment.status)}<br><span>${payment.payment_method || "Not set"}</span></td>
          <td>${statusPill(payment.payout_status || "not_ready")}</td>
          <td>
            <button class="small-button" onclick="updatePayment('${payment.id}', { status: 'completed' })">Mark paid</button>
            <button class="small-button" onclick="updatePayment('${payment.id}', { payout_status: 'processed' })">Payout done</button>
            <button class="small-button danger" onclick="updatePayment('${payment.id}', { status: 'failed' })">Fail</button>
          </td>
        </tr>
      `)
      .join("") || `<tr><td colspan="6">${emptyState("No payment records found.")}</td></tr>`;
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
        `<button class="small-button danger" onclick="toggleSpecialty('${specialty.id}')">${specialty.active === false ? "Enable" : "Disable"}</button>`,
      ),
    ),
  ].join("");
}

async function updateDoctorStatus(id, status) {
  const doctor = state.doctors.find((item) => item.id === id);
  if (!doctor) return;
  if (status === "approved" && !doctor.license_document_path) {
    toast("Doctor has no verification document uploaded");
    return;
  }
  const approvalNote =
    status === "approved"
      ? "Document reviewed and approved by KazHealth admin."
      : prompt("Reason for rejecting this doctor?", doctor.approval_note || "Document could not be verified.") ||
        "Document could not be verified.";

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const table = doctor.source === "profiles" ? "profiles" : "doctors";
    const { error } = await db
      .from(table)
      .update({ approval_status: status, approval_note: approvalNote })
      .eq("id", id);
    if (error) return toast(error.message);
  }

  doctor.approval_status = status;
  doctor.approval_note = approvalNote;
  const profile = state.profiles.find((item) => item.id === id);
  if (profile) {
    profile.approval_status = status;
    profile.approval_note = approvalNote;
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
  
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const table = doctor.source === "profiles" ? "profiles" : "doctors";
    
    // 1. Update approval status
    const { error: updateError } = await db
      .from(table)
      .update({ 
        approval_status: "approved", 
        is_doctor_approved: true,
        approval_note: notes,
        is_active: true
      })
      .eq("id", _reviewingDoctorId);
    if (updateError) return toast(updateError.message);

    // 2. Create notification for doctor
    const { error: notifError } = await db
      .from("notifications")
      .insert({
        user_id: _reviewingDoctorId,
        title: "✓ Your profile is approved!",
        message: "Your license has been verified. You're now visible to patients in the app and can accept consultation requests.",
        target_role: "doctor"
      });
    if (notifError) console.warn("Notification insert failed:", notifError);

    // 3. Create audit log entry
    const adminEmail = state.session?.user?.email || "superadmin@docconsult.app";
    const { error: auditError } = await db
      .from("audit_log")
      .insert({
        admin_id: state.session?.user?.id,
        action: "approved_doctor",
        target_table: "profiles",
        target_id: _reviewingDoctorId,
        details: {
          doctor_name: fullDoctorName(doctor),
          doctor_email: doctor.email,
          admin_email: adminEmail,
          approval_note: notes,
          timestamp: new Date().toISOString()
        }
      });
    if (auditError) console.warn("Audit log insert failed:", auditError);
  }

  doctor.approval_status = "approved";
  doctor.is_doctor_approved = true;
  doctor.is_active = true;
  doctor.approval_note = notes;
  const profile = state.profiles.find((p) => p.id === _reviewingDoctorId);
  if (profile) {
    profile.approval_status = "approved";
    profile.is_doctor_approved = true;
    profile.is_active = true;
    profile.approval_note = notes;
  }

  closeDoctorReview();
  render();
  toast("✓ Doctor approved! Notification sent. Now visible to patients.");
}

async function rejectFromReview() {
  if (!_reviewingDoctorId) return;
  const reason = $("#reviewNotes").value || "Document could not be verified. Please resubmit.";
  const doctor = state.doctors.find((d) => d.id === _reviewingDoctorId);

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const table = doctor.source === "profiles" ? "profiles" : "doctors";
    
    // 1. Update rejection status
    const { error: updateError } = await db
      .from(table)
      .update({ 
        approval_status: "rejected", 
        approval_note: reason
      })
      .eq("id", _reviewingDoctorId);
    if (updateError) return toast(updateError.message);

    // 2. Create notification for doctor
    const { error: notifError } = await db
      .from("notifications")
      .insert({
        user_id: _reviewingDoctorId,
        title: "✗ Document needs revision",
        message: "Your license document couldn't be verified. Please review the feedback and submit a new document.",
        target_role: "doctor"
      });
    if (notifError) console.warn("Notification insert failed:", notifError);

    // 3. Create audit log entry
    const adminEmail = state.session?.user?.email || "superadmin@docconsult.app";
    const { error: auditError } = await db
      .from("audit_log")
      .insert({
        admin_id: state.session?.user?.id,
        action: "rejected_doctor",
        target_table: "profiles",
        target_id: _reviewingDoctorId,
        details: {
          doctor_name: fullDoctorName(doctor),
          doctor_email: doctor.email,
          admin_email: adminEmail,
          rejection_reason: reason,
          timestamp: new Date().toISOString()
        }
      });
    if (auditError) console.warn("Audit log insert failed:", auditError);
  }

  doctor.approval_status = "rejected";
  doctor.approval_note = reason;
  const profile = state.profiles.find((p) => p.id === _reviewingDoctorId);
  if (profile) {
    profile.approval_status = "rejected";
    profile.approval_note = reason;
  }

  closeDoctorReview();
  render();
  toast("✗ Doctor rejected. They can resubmit a new document.");
}

async function updateAppointmentStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("appointments").update({ status }).eq("id", id);
    if (error) return toast(error.message);
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
  }

  const payment = state.payments.find((item) => item.id === id);
  if (payment) Object.assign(payment, updates);
  render();
  toast("Payment updated");
}

async function updateReviewStatus(id, status) {
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("reviews").update({ status }).eq("id", id);
    if (error) return toast(error.message);
  }

  const review = state.reviews.find((item) => item.id === id);
  if (review) review.status = status;
  renderReviews();
  toast(`Review ${status}`);
}

async function deleteReview(id) {
  if (!confirm("Delete this review?")) return;
  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("reviews").delete().eq("id", id);
    if (error) return toast(error.message);
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
  }

  patient.deactivated = deactivated;
  renderPatients();
  toast(deactivated ? "Patient deactivated" : "Patient reactivated");
}

async function toggleDoctor(id) {
  const doctor = state.doctors.find((item) => item.id === id);
  const profile = state.profiles.find((item) => item.id === id);
  if (!doctor && !profile) return;
  const deactivated = !(doctor?.deactivated || profile?.deactivated);

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("profiles").update({ deactivated }).eq("id", id);
    if (error) return toast(error.message);
  }

  if (doctor) doctor.deactivated = deactivated;
  if (profile) profile.deactivated = deactivated;
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
  const notification = {
    id: crypto.randomUUID(),
    title: "Platform announcement",
    message,
    target_role: $("#notificationTarget").value,
    created_at: new Date().toISOString(),
  };

  if (!state.usingPreview) {
    if (!db) return toast("Supabase client unavailable");
    const { error } = await db.from("notifications").insert(notification);
    if (error) return toast(error.message);
  }

  state.notifications.unshift(notification);
  event.target.reset();
  renderNotifications();
  toast("Notification sent");
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
    const { error } = await db.from("settings").upsert(settings);
    if (error) return toast(error.message);
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
  }

  specialty.active = active;
  renderSettings();
  toast(active ? "Specialty enabled" : "Specialty disabled");
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
    updateConnection("online", "Supabase connected", state.session ? "Authenticated session" : "Anon access active");
  }
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
  if (state.doctorFilter === "suspended") return Boolean(doctor.deactivated);
  return normalizeStatus(doctor.approval_status) === state.doctorFilter && !doctor.deactivated;
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
    payments: "Payments & Payouts",
    patients: "Patient Accounts",
    reviews: "Review Moderation",
    notifications: "Notifications",
    settings: "Platform Settings",
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
    .on("postgres_changes", { event: "*", schema: "public", table: "reviews" }, async () => {
      state.reviews = await selectTable("reviews");
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
