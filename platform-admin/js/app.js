import { supabase } from './supabase.js';

// Admin Dashboard JS – Connected to Supabase
class AdminDashboard {
  constructor() {
    this.currentTab = 'dashboard';
    this.currentPage = {};
    this.adminUser = null;
    this.tabTitles = {
      dashboard: 'Admin Dashboard',
      users: 'User Management',
      doctors: 'Doctor Management',
      appointments: 'Appointment Management',
      payments: 'Payment History',
      reviews: 'Doctor Reviews',
      messages: 'Messages',
      'health-records': 'Health Records',
      prescriptions: 'Prescriptions',
      consultations: 'Consultations',
      settings: 'Settings',
    };
    this.init();
  }

  async init() {
    const { data: { session } } = await supabase.auth.getSession();
    if (!session) { this.showLogin(); return; }

    const { data: profile } = await supabase
      .from('profiles').select('*').eq('id', session.user.id).single();

    if (!profile || profile.role !== 'admin') {
      this.showLogin('Access denied. Admin role required.');
      await supabase.auth.signOut();
      return;
    }
    this.adminUser = profile;
    this.showDashboard();
  }

  showLogin(errorMsg = '') {
    document.getElementById('login-screen').style.display = 'flex';
    document.getElementById('app-screen').style.display = 'none';
    if (errorMsg) {
      document.getElementById('login-error').textContent = errorMsg;
      document.getElementById('login-error').style.display = 'block';
    }
    const btn = document.getElementById('login-btn');
    const newBtn = btn.cloneNode(true);
    btn.parentNode.replaceChild(newBtn, btn);

    newBtn.addEventListener('click', async () => {
      const email = document.getElementById('login-email').value.trim();
      const password = document.getElementById('login-password').value;
      const errorEl = document.getElementById('login-error');
      newBtn.disabled = true;
      newBtn.textContent = 'Signing in...';
      errorEl.style.display = 'none';

      try {
        const { data, error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
        const { data: profile, error: pErr } = await supabase
          .from('profiles').select('*').eq('id', data.user.id).single();
        if (pErr) throw pErr;
        if (profile.role !== 'admin') {
          await supabase.auth.signOut();
          throw new Error('Access denied. Admin role required.');
        }
        this.adminUser = profile;
        this.showDashboard();
      } catch (err) {
        errorEl.textContent = err.message || 'Login failed';
        errorEl.style.display = 'block';
        newBtn.disabled = false;
        newBtn.textContent = 'Sign In';
      }
    });
  }

  showDashboard() {
    document.getElementById('login-screen').style.display = 'none';
    document.getElementById('app-screen').style.display = 'flex';
    const up = document.querySelector('.user-profile');
    if (up && this.adminUser) {
      up.querySelector('div > div:first-child').textContent =
        `${this.adminUser.first_name} ${this.adminUser.last_name}`;
    }
    this.setupEventListeners();
    this.switchTab(this.getInitialTab(), { updateHash: false });
  }

  setupEventListeners() {
    // Tab buttons
    document.querySelectorAll('.tab-button').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const { tab } = e.currentTarget.dataset;
        if (tab) {
          this.switchTab(tab);
        }
      });
    });

    // Modal close buttons
    document.querySelectorAll('.modal-close').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.target.closest('.modal').classList.remove('active');
      });
    });

    // Search functionality
    const searchBox = document.querySelector('.search-box input');
    if (searchBox) {
      searchBox.addEventListener('input', (e) => this.handleSearch(e.target.value));
    }

    // Sidebar navigation
    document.querySelectorAll('.sidebar-nav a').forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        const currentLink = e.currentTarget;
        const { tab, action } = currentLink.dataset;

        if (action === 'logout') {
          this.handleLogout();
          return;
        }

        if (tab) {
          this.switchTab(tab);
        }
      });
    });

    window.addEventListener('hashchange', () => {
      const tab = this.getInitialTab();
      if (tab !== this.currentTab) {
        this.switchTab(tab, { updateHash: false });
      }
    });
  }

  getInitialTab() {
    const hashTab = window.location.hash.replace(/^#/, '');
    const tabExists = document.querySelector(`#tab-${hashTab}`);
    return tabExists ? hashTab : 'dashboard';
  }

  switchTab(tab, options = {}) {
    const { updateHash = true } = options;
    if (!document.querySelector(`#tab-${tab}`)) {
      return;
    }

    this.currentTab = tab;
    
    // Update sidebar links
    document.querySelectorAll('.sidebar-nav a').forEach(link => {
      link.classList.toggle('active', link.dataset.tab === tab);
    });

    // Update tab buttons
    document.querySelectorAll('.tab-button').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.tab === tab);
    });

    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
      content.classList.toggle('active', content.id === `tab-${tab}`);
    });

    // Update header title
    const headerTitle = document.querySelector('.header-title');
    if (headerTitle) {
      headerTitle.textContent = this.tabTitles[tab] || 'Admin Dashboard';
    }

    if (updateHash) {
      window.location.hash = tab;
    }

    // Load tab data
    switch(tab) {
      case 'dashboard':
        this.loadDashboard();
        break;
      case 'users':
        this.loadUsers();
        break;
      case 'doctors':
        this.loadDoctors();
        break;
      case 'appointments':
        this.loadAppointments();
        break;
      case 'payments':
        this.loadPayments();
        break;
      case 'reviews':
        this.loadReviews();
        break;
      case 'messages':
        this.loadMessages();
        break;
      case 'health-records':
        this.loadHealthRecords();
        break;
      case 'prescriptions':
        this.loadPrescriptions();
        break;
      case 'consultations':
        this.loadConsultations();
        break;
      case 'settings':
        this.loadSettings();
        break;
    }
  }

  // ========== DASHBOARD ==========
  async loadDashboard() {
    const container = document.querySelector('#dashboard-stats');
    container.innerHTML = '<div class="loading">Loading dashboard...</div>';
    try {
      const [
        { count: totalPatients },
        { count: totalDoctors },
        { count: pendingDoctors },
        { count: totalAppointments },
        { count: completedAppointments },
        { data: recentAppointments },
        { data: payments },
      ] = await Promise.all([
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'patient'),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'doctor').eq('approval_status', 'approved'),
        supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'doctor').eq('approval_status', 'pending'),
        supabase.from('appointments').select('*', { count: 'exact', head: true }),
        supabase.from('appointments').select('*', { count: 'exact', head: true }).eq('status', 'completed'),
        supabase.from('appointments').select('*').order('created_at', { ascending: false }).limit(5),
        supabase.from('payments').select('amount, status'),
      ]);
      const totalRevenue = (payments || []).filter(p => p.status === 'completed').reduce((s, p) => s + (p.amount || 0), 0);
      const pendingPayments = (payments || []).filter(p => p.status === 'pending').length;

      container.innerHTML = `
        <div class="stats-grid">
          ${this.createStatCard('Total Patients', totalPatients || 0, 'registered', 'success')}
          ${this.createStatCard('Approved Doctors', totalDoctors || 0, 'active', 'success')}
          ${this.createStatCard('Pending Approval', pendingDoctors || 0, 'doctors awaiting review', pendingDoctors > 0 ? 'warning' : 'success')}
          ${this.createStatCard('Total Appointments', totalAppointments || 0, (completedAppointments || 0) + ' completed', 'info')}
          ${this.createStatCard('Total Revenue', 'GHS ' + (totalRevenue || 0).toLocaleString(), 'from payments', 'success')}
          ${this.createStatCard('Pending Payments', pendingPayments, 'awaiting completion', pendingPayments > 0 ? 'warning' : 'success')}
        </div>
        <div class="mt-20">
          <h3 class="chart-title">Recent Appointments</h3>
          ${this.createAppointmentsList(recentAppointments || [])}
        </div>`;
    } catch (err) {
      container.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error loading dashboard</div><p>' + err.message + '</p></div>';
    }
  }

  // ========== USERS ==========
  async loadUsers() {
    const c = document.querySelector('#tab-users');
    c.innerHTML = '<div class="loading">Loading users...</div>';
    try {
      const { data, error } = await supabase.from('profiles').select('*').eq('role', 'patient').order('created_at', { ascending: false });
      if (error) throw error;
      c.innerHTML = '<div class="flex-between mb-20"><h3>Patients (' + (data || []).length + ')</h3></div>' + this.createUsersTable(data || []);
    } catch (err) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error: ' + err.message + '</div></div>'; }
  }

  // ========== DOCTORS ==========
  async loadDoctors() {
    const c = document.querySelector('#tab-doctors');
    c.innerHTML = '<div class="loading">Loading doctors...</div>';
    try {
      const { data, error } = await supabase.from('profiles').select('*').eq('role', 'doctor').order('created_at', { ascending: false });
      if (error) throw error;
      const pending = (data || []).filter(d => d.approval_status === 'pending');
      const approved = (data || []).filter(d => d.approval_status === 'approved');
      const rejected = (data || []).filter(d => d.approval_status === 'rejected');
      c.innerHTML = '<div class="flex-between mb-20"><h3>Doctor Management</h3></div>'
        + (pending.length ? '<h4 style="color:var(--accent-color);margin-bottom:12px">⏳ Pending Approval (' + pending.length + ')</h4>' + this.createDoctorsTable(pending, true) + '<div style="margin-bottom:24px"></div>' : '')
        + '<h4 style="color:var(--success-color);margin-bottom:12px">✅ Approved (' + approved.length + ')</h4>' + this.createDoctorsTable(approved, false)
        + (rejected.length ? '<div style="margin-top:24px"></div><h4 style="color:var(--danger-color);margin-bottom:12px">❌ Rejected (' + rejected.length + ')</h4>' + this.createDoctorsTable(rejected, false) : '');
    } catch (err) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error: ' + err.message + '</div></div>'; }
  }

  // ========== APPOINTMENTS ==========
  async loadAppointments() {
    const c = document.querySelector('#tab-appointments');
    c.innerHTML = '<div class="loading">Loading appointments...</div>';
    try {
      const { data, error } = await supabase.from('appointments').select('*').order('appointment_date', { ascending: false });
      if (error) throw error;
      c.innerHTML = '<div class="flex-between mb-20"><h3>Appointments (' + (data || []).length + ')</h3></div>' + this.createAppointmentsTable(data || []);
    } catch (err) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error: ' + err.message + '</div></div>'; }
  }

  // ========== PAYMENTS ==========
  async loadPayments() {
    const c = document.querySelector('#tab-payments');
    c.innerHTML = '<div class="loading">Loading payments...</div>';
    try {
      const { data, error } = await supabase.from('payments').select('*').order('created_at', { ascending: false });
      if (error) throw error;
      c.innerHTML = '<h3 class="mb-20">Payments (' + (data || []).length + ')</h3>' + this.createPaymentsTable(data || []);
    } catch (err) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error: ' + err.message + '</div></div>'; }
  }

  // ========== REVIEWS ==========
  async loadReviews() {
    const c = document.querySelector('#tab-reviews');
    c.innerHTML = '<div class="loading">Loading reviews...</div>';
    try {
      const { data, error } = await supabase.from('reviews').select('*').order('created_at', { ascending: false });
      if (error) throw error;
      c.innerHTML = '<h3 class="mb-20">Reviews (' + (data || []).length + ')</h3>' + this.createReviewsList(data || []);
    } catch (err) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error: ' + err.message + '</div></div>'; }
  }

  // ========== MESSAGES ==========
  async loadMessages() {
    const c = document.querySelector('#tab-messages');
    c.innerHTML = '<div class="loading">Loading messages...</div>';
    try {
      const { data, error } = await supabase.from('messages').select('*').order('created_at', { ascending: false }).limit(50);
      if (error) throw error;
      c.innerHTML = '<h3 class="mb-20">Messages (' + (data || []).length + ')</h3>' + this.createMessagesTable(data || []);
    } catch (err) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error: ' + err.message + '</div></div>'; }
  }

  // ========== HEALTH RECORDS ==========
  async loadHealthRecords() {
    const c = document.querySelector('#tab-health-records');
    c.innerHTML = '<div class="loading">Loading health records...</div>';
    try {
      const { data, error } = await supabase.from('health_records').select('*').order('created_at', { ascending: false });
      if (error) throw error;
      c.innerHTML = '<h3 class="mb-20">Health Records (' + (data || []).length + ')</h3>' + this.createHealthRecordsTable(data || []);
    } catch (err) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error: ' + err.message + '</div></div>'; }
  }

  // ========== PRESCRIPTIONS ==========
  async loadPrescriptions() {
    const c = document.querySelector('#tab-prescriptions');
    c.innerHTML = '<div class="loading">Loading prescriptions...</div>';
    try {
      const { data, error } = await supabase.from('prescriptions').select('*, medicines(*)').order('created_at', { ascending: false });
      if (error) throw error;
      c.innerHTML = '<h3 class="mb-20">Prescriptions (' + (data || []).length + ')</h3>' + this.createPrescriptionsTable(data || []);
    } catch (err) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error: ' + err.message + '</div></div>'; }
  }

  // ========== CONSULTATIONS ==========
  async loadConsultations() {
    const c = document.querySelector('#tab-consultations');
    c.innerHTML = '<div class="loading">Loading consultations...</div>';
    try {
      const { data, error } = await supabase.from('consultations').select('*').order('created_at', { ascending: false });
      if (error) throw error;
      c.innerHTML = '<h3 class="mb-20">Consultations (' + (data || []).length + ')</h3>' + this.createConsultationsTable(data || []);
    } catch (err) { c.innerHTML = '<div class="empty-state"><div class="empty-state-icon">⚠️</div><div class="empty-state-title">Error: ' + err.message + '</div></div>'; }
  }

  // ========== SETTINGS ==========
  loadSettings() {
    document.querySelector('#tab-settings').innerHTML = `
      <div class="table-container"><div style="padding:24px">
        <h3 class="mb-20">Platform Settings</h3>
        <p style="color:var(--gray-600);margin-bottom:20px">Connected to Supabase: <strong style="color:var(--success-color)">✓ Live</strong></p>
        <div class="stats-grid">
          ${this.createStatCard('Doctor Approval', 'Manual', 'Admin review required', 'info')}
          ${this.createStatCard('Currency', 'GHS', 'Ghana Cedis', 'info')}
          ${this.createStatCard('Database', 'Supabase', 'PostgreSQL', 'success')}
          ${this.createStatCard('Auth', 'Supabase Auth', 'Email + Password', 'success')}
        </div>
      </div></div>`;
  }

  // ========== TABLE / LIST RENDERERS ==========

  createUsersTable(users) {
    if (!users || users.length === 0) return '<div class="empty-state"><div class="empty-state-icon">👥</div><div class="empty-state-title">No patients found</div></div>';
    const rows = users.map(u => `<tr>
      <td><strong>${u.first_name} ${u.last_name}</strong></td>
      <td>${u.email}</td><td>${u.phone || '—'}</td>
      <td>${new Date(u.created_at).toLocaleDateString()}</td>
      <td><span class="badge ${u.is_online ? 'badge-success' : 'badge-danger'}">${u.is_online ? 'online' : 'offline'}</span></td>
      <td><button class="btn btn-small btn-danger" onclick="dashboard.deleteUser('${u.id}')">Delete</button></td>
    </tr>`).join('');
    return `<div class="table-container"><table>
      <thead><tr><th>Name</th><th>Email</th><th>Phone</th><th>Registered</th><th>Status</th><th>Actions</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
  }

  createDoctorsTable(doctors, showApproval = false) {
    if (!doctors || doctors.length === 0) return '<div class="empty-state"><div class="empty-state-icon">⚕️</div><div class="empty-state-title">No doctors found</div></div>';
    const rows = doctors.map(d => `<tr>
      <td><strong>${d.first_name} ${d.last_name}</strong></td>
      <td>${d.specialty || '—'}</td><td>${d.email}</td><td>${d.experience || '—'}</td>
      <td>GHS ${d.consultation_fee || 0}</td>
      <td><span class="badge ${d.approval_status === 'approved' ? 'badge-success' : d.approval_status === 'pending' ? 'badge-pending' : 'badge-danger'}">${d.approval_status || 'unknown'}</span></td>
      <td>${showApproval
        ? `<button class="btn btn-small btn-primary" onclick="dashboard.approveDoctor('${d.id}')">✓ Approve</button> <button class="btn btn-small btn-danger" onclick="dashboard.rejectDoctor('${d.id}')">✗ Reject</button>`
        : `<button class="btn btn-small btn-secondary" onclick="dashboard.viewDoctor('${d.id}')">View</button>`}</td>
    </tr>`).join('');
    return `<div class="table-container"><table>
      <thead><tr><th>Name</th><th>Specialty</th><th>Email</th><th>Experience</th><th>Fee</th><th>Status</th><th>Actions</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
  }

  createAppointmentsTable(appointments) {
    if (!appointments || appointments.length === 0) return '<div class="empty-state"><div class="empty-state-icon">📅</div><div class="empty-state-title">No appointments found</div></div>';
    const rows = appointments.map(a => `<tr>
      <td>${a.doctor_name || '—'}</td><td>${a.speciality || '—'}</td>
      <td>${new Date(a.appointment_date).toLocaleDateString()}</td><td>${a.time_slot}</td>
      <td><span class="badge badge-${a.status === 'completed' ? 'success' : a.status === 'confirmed' ? 'info' : 'pending'}">${a.status}</span></td>
      <td>GHS ${a.consultation_fee || 0}</td>
    </tr>`).join('');
    return `<div class="table-container"><table>
      <thead><tr><th>Doctor</th><th>Specialty</th><th>Date</th><th>Time</th><th>Status</th><th>Fee</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
  }

  createPaymentsTable(payments) {
    if (!payments || payments.length === 0) return '<div class="empty-state"><div class="empty-state-icon">💳</div><div class="empty-state-title">No payments found</div></div>';
    const rows = payments.map(p => `<tr>
      <td>${p.transaction_id || '—'}</td><td>GHS ${(p.amount || 0).toLocaleString()}</td>
      <td>${p.payment_method || '—'}</td>
      <td><span class="badge ${p.status === 'completed' ? 'badge-success' : 'badge-pending'}">${p.status}</span></td>
      <td>${p.created_at ? new Date(p.created_at).toLocaleDateString() : '—'}</td>
    </tr>`).join('');
    return `<div class="table-container"><table>
      <thead><tr><th>Transaction ID</th><th>Amount</th><th>Method</th><th>Status</th><th>Date</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
  }

  createReviewsList(reviews) {
    if (!reviews || reviews.length === 0) return '<div class="empty-state"><div class="empty-state-icon">⭐</div><div class="empty-state-title">No reviews found</div></div>';
    return reviews.map(r => `<div class="table-container" style="margin-bottom:15px"><div style="padding:20px">
      <div class="flex-between mb-20"><div><h4>${r.doctor_name || 'Doctor'}</h4>
        <p style="font-size:12px;color:var(--gray-500)">By ${r.patient_name || 'Patient'} • ${r.created_at ? new Date(r.created_at).toLocaleDateString() : ''}</p></div>
        <div style="text-align:right"><div style="color:var(--accent-color);font-size:18px">${'⭐'.repeat(Math.round(r.rating || 0))}</div>
        <p style="font-size:12px;color:var(--gray-500)">${r.helpful_count || 0} found helpful</p></div></div>
      <h5>${r.title || ''}</h5><p style="color:var(--gray-600);font-size:14px;margin:10px 0">${r.review_text || ''}</p>
      ${r.is_verified_appointment ? '<span class="badge badge-success">✓ Verified</span>' : ''}
    </div></div>`).join('');
  }

  createMessagesTable(messages) {
    if (!messages || messages.length === 0) return '<div class="empty-state"><div class="empty-state-icon">💬</div><div class="empty-state-title">No messages found</div></div>';
    const rows = messages.map(m => `<tr>
      <td><strong>${m.sender_name || '—'}</strong></td><td>${m.is_doctor ? 'Doctor' : 'Patient'}</td>
      <td>${(m.message || '').substring(0, 60)}${(m.message || '').length > 60 ? '...' : ''}</td>
      <td>${m.created_at ? new Date(m.created_at).toLocaleString() : '—'}</td>
      <td><span class="badge ${m.is_read ? 'badge-success' : 'badge-pending'}">${m.is_read ? 'read' : 'unread'}</span></td>
    </tr>`).join('');
    return `<div class="table-container"><table>
      <thead><tr><th>Sender</th><th>Role</th><th>Message</th><th>Time</th><th>Status</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
  }

  createHealthRecordsTable(records) {
    if (!records || records.length === 0) return '<div class="empty-state"><div class="empty-state-icon">📋</div><div class="empty-state-title">No health records found</div></div>';
    const rows = records.map(r => `<tr>
      <td>${r.type || '—'}</td><td><strong>${r.title}</strong></td><td>${r.value} ${r.unit || ''}</td>
      <td>${r.normal_range || '—'}</td><td>${r.record_date ? new Date(r.record_date).toLocaleDateString() : '—'}</td>
      <td><span class="badge ${r.status === 'normal' ? 'badge-success' : 'badge-pending'}">${r.status || '—'}</span></td>
    </tr>`).join('');
    return `<div class="table-container"><table>
      <thead><tr><th>Type</th><th>Record</th><th>Value</th><th>Normal Range</th><th>Date</th><th>Status</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
  }

  createPrescriptionsTable(prescriptions) {
    if (!prescriptions || prescriptions.length === 0) return '<div class="empty-state"><div class="empty-state-icon">📝</div><div class="empty-state-title">No prescriptions found</div></div>';
    const rows = prescriptions.map(p => `<tr>
      <td><strong>${p.doctor_name || '—'}</strong></td>
      <td>${(p.medicines || []).map(m => m.name).join(', ') || '—'}</td>
      <td>${p.prescribed_date ? new Date(p.prescribed_date).toLocaleDateString() : '—'}</td>
      <td><span class="badge ${p.status === 'active' ? 'badge-success' : 'badge-pending'}">${p.status}</span></td>
    </tr>`).join('');
    return `<div class="table-container"><table>
      <thead><tr><th>Doctor</th><th>Medicines</th><th>Date</th><th>Status</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
  }

  createConsultationsTable(consultations) {
    if (!consultations || consultations.length === 0) return '<div class="empty-state"><div class="empty-state-icon">🎥</div><div class="empty-state-title">No consultations found</div></div>';
    const rows = consultations.map(c => `<tr>
      <td><strong>${c.doctor_name || '—'}</strong></td><td>${c.consultation_type || '—'}</td>
      <td>${c.scheduled_time ? new Date(c.scheduled_time).toLocaleString() : '—'}</td>
      <td>${c.duration_minutes || 0} min</td>
      <td><span class="badge ${c.status === 'completed' ? 'badge-success' : c.status === 'scheduled' ? 'badge-info' : 'badge-pending'}">${c.status}</span></td>
    </tr>`).join('');
    return `<div class="table-container"><table>
      <thead><tr><th>Doctor</th><th>Type</th><th>Scheduled</th><th>Duration</th><th>Status</th></tr></thead>
      <tbody>${rows}</tbody></table></div>`;
  }

  createAppointmentsList(appointments) {
    if (!appointments || appointments.length === 0) return '<div class="empty-state"><div class="empty-state-icon">📅</div><div class="empty-state-title">No recent appointments</div></div>';
    return appointments.map(a => `<div class="table-container" style="margin-bottom:15px">
      <div style="padding:16px;display:flex;justify-content:space-between;align-items:center">
        <div><strong>${a.doctor_name || 'Doctor'}</strong> — ${a.speciality || ''}
          <p style="font-size:12px;color:var(--gray-500);margin-top:4px">${a.appointment_date ? new Date(a.appointment_date).toLocaleDateString() : ''} at ${a.time_slot || ''}</p></div>
        <span class="badge badge-${a.status === 'completed' ? 'success' : a.status === 'confirmed' ? 'info' : 'pending'}">${a.status}</span>
      </div></div>`).join('');
  }

  createStatCard(label, value, change, type = 'success') {
    return `<div class="stat-card"><div class="stat-label">${label}</div><div class="stat-value">${value}</div><div class="stat-change ${type === 'danger' ? 'negative' : ''}">${change}</div></div>`;
  }

  // ========== ADMIN ACTIONS ==========

  async approveDoctor(doctorId) {
    if (!confirm('Approve this doctor?')) return;
    try {
      const { error } = await supabase.from('profiles').update({ approval_status: 'approved' }).eq('id', doctorId);
      if (error) throw error;
      const { data: profile } = await supabase.from('profiles').select('*').eq('id', doctorId).single();
      if (profile) {
        await supabase.from('doctors').insert({
          profile_id: doctorId,
          name: profile.first_name + ' ' + profile.last_name,
          specialty: profile.specialty || 'General Practice',
          description: profile.bio || '',
          consultation_fee: profile.consultation_fee || 0,
          experience: profile.experience || '',
          available: true,
          available_times: ['09:00 AM','10:00 AM','11:00 AM','02:00 PM','03:00 PM'],
        });
      }
      alert('Doctor approved successfully!');
      this.loadDoctors();
      this.loadDashboard();
    } catch (err) { alert('Error: ' + err.message); }
  }

  async rejectDoctor(doctorId) {
    const reason = prompt('Reason for rejection:');
    if (reason === null) return;
    try {
      const { error } = await supabase.from('profiles').update({ approval_status: 'rejected', approval_note: reason }).eq('id', doctorId);
      if (error) throw error;
      alert('Doctor rejected.');
      this.loadDoctors();
    } catch (err) { alert('Error: ' + err.message); }
  }

  viewDoctor(doctorId) {
    alert('Doctor ID: ' + doctorId + '\nView profile in the Supabase dashboard.');
  }

  async deleteUser(userId) {
    if (!confirm('Delete this user? This cannot be undone.')) return;
    try {
      const { error } = await supabase.from('profiles').delete().eq('id', userId);
      if (error) throw error;
      alert('User deleted.');
      this.loadUsers();
    } catch (err) { alert('Error: ' + err.message); }
  }

  handleSearch(query) { console.log('Search:', query); }

  async handleLogout() {
    if (!confirm('Log out of the admin dashboard?')) return;
    await supabase.auth.signOut();
    this.adminUser = null;
    this.showLogin();
  }
}

const dashboard = new AdminDashboard();
window.dashboard = dashboard;
