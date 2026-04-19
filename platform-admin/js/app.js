const localAdminData = {
  admin: {
    id: 'local-admin',
    email: 'admin@test.com',
    first_name: 'Platform',
    last_name: 'Admin',
  },
  users: [
    { id: 'patient-1', name: 'Test Patient', email: 'patient@test.com', phone: '+233501234567', status: 'active', createdAt: '2026-04-01' },
    { id: 'patient-2', name: 'Ama Serwaa', email: 'ama@example.com', phone: '+233500000001', status: 'active', createdAt: '2026-04-10' },
  ],
  doctors: [
    { id: 'doctor-1', name: 'Dr. Ama Mensah', specialty: 'Cardiologist', email: 'doctor@test.com', status: 'approved', fee: 'GHS 180', experience: '8 years' },
    { id: 'doctor-2', name: 'Dr. Kojo Asare', specialty: 'Dermatologist', email: 'kojo@example.com', status: 'pending', fee: 'GHS 150', experience: '6 years' },
  ],
  appointments: [
    { id: 'apt-1', patient: 'Test Patient', doctor: 'Dr. Ama Mensah', date: 'Apr 20, 2026', time: '10:00 AM', status: 'confirmed' },
    { id: 'apt-2', patient: 'Ama Serwaa', doctor: 'Dr. Kojo Asare', date: 'Apr 18, 2026', time: '02:00 PM', status: 'completed' },
  ],
  payments: [
    { id: 'pay-1', patient: 'Test Patient', doctor: 'Dr. Ama Mensah', amount: 'GHS 180', commission: 'GHS 27', status: 'completed' },
    { id: 'pay-2', patient: 'Ama Serwaa', doctor: 'Dr. Kojo Asare', amount: 'GHS 150', commission: 'GHS 22.50', status: 'pending' },
  ],
  reviews: [
    { id: 'review-1', doctor: 'Dr. Ama Mensah', patient: 'Test Patient', rating: '5.0', comment: 'Very clear and reassuring consultation.' },
    { id: 'review-2', doctor: 'Dr. Kojo Asare', patient: 'Ama Serwaa', rating: '4.0', comment: 'Helpful but I wanted a longer follow-up.' },
  ],
  messages: [
    { id: 'msg-1', sender: 'Dr. Ama Mensah', preview: 'Please bring your latest blood pressure log.', status: 'Unread' },
    { id: 'msg-2', sender: 'Test Patient', preview: 'Thank you, I will upload it today.', status: 'Read' },
  ],
  healthRecords: [
    { id: 'record-1', patient: 'Test Patient', type: 'Vital', title: 'Blood Pressure', value: '120/80 mmHg' },
    { id: 'record-2', patient: 'Ama Serwaa', type: 'Allergy', title: 'Peanut Allergy', value: 'Severe' },
  ],
  prescriptions: [
    { id: 'rx-1', patient: 'Test Patient', doctor: 'Dr. Ama Mensah', medicine: 'Amlodipine 5mg', status: 'active' },
  ],
  consultations: [
    { id: 'con-1', patient: 'Test Patient', doctor: 'Dr. Ama Mensah', mode: 'Video', status: 'scheduled' },
    { id: 'con-2', patient: 'Ama Serwaa', doctor: 'Dr. Kojo Asare', mode: 'Video', status: 'completed' },
  ],
  verification: [
    { id: 'ver-1', doctorId: 'doctor-2', doctor: 'Dr. Kojo Asare', specialty: 'Dermatologist', status: 'pending', confidence: '65%' },
    { id: 'ver-2', doctorId: 'doctor-1', doctor: 'Dr. Ama Mensah', specialty: 'Cardiologist', status: 'approved', confidence: '100%' },
  ],
  commissionSettings: {
    doctorRate: 85,
    platformRate: 15,
    minCommission: 20,
    paymentFrequency: 'weekly',
  },
  commissionTiers: [
    { id: 'tier-1', name: 'Starter', minConsultations: 0, rate: '15%', bonus: 'GHS 0' },
    { id: 'tier-2', name: 'Growth', minConsultations: 50, rate: '12%', bonus: 'GHS 200' },
  ],
};

class AdminDashboard {
  constructor() {
    this.currentTab = 'dashboard';
    this.sessionKey = 'docconsult-local-admin-session';
    this.tabTitles = {
      dashboard: 'Admin Dashboard',
      users: 'User Management',
      doctors: 'Doctor Management',
      verification: 'Document Verification',
      commissions: 'Commission Settings',
      appointments: 'Appointment Management',
      payments: 'Payment History',
      reviews: 'Doctor Reviews',
      messages: 'Messages',
      'health-records': 'Health Records',
      prescriptions: 'Prescriptions',
      consultations: 'Consultations',
      settings: 'Settings',
    };
  }

  init() {
    if (window.localStorage.getItem(this.sessionKey) === 'true') {
      this.showDashboard();
      return;
    }
    this.showLogin();
  }

  showLogin(errorMsg = '') {
    document.getElementById('login-screen').style.display = 'flex';
    document.getElementById('app-screen').style.display = 'none';

    const errorEl = document.getElementById('login-error');
    errorEl.textContent = errorMsg;
    errorEl.style.display = errorMsg ? 'block' : 'none';

    const btn = document.getElementById('login-btn');
    const freshBtn = btn.cloneNode(true);
    btn.parentNode.replaceChild(freshBtn, btn);
    freshBtn.addEventListener('click', () => this.handleLogin(freshBtn));
  }

  handleLogin(btn) {
    const email = document.getElementById('login-email').value.trim().toLowerCase();
    const password = document.getElementById('login-password').value;

    if (email !== 'admin@test.com' || password !== 'Test1234!') {
      this.showLogin('Use admin@test.com / Test1234! to open the local admin shell.');
      return;
    }

    btn.disabled = true;
    btn.textContent = 'Signing in...';
    window.localStorage.setItem(this.sessionKey, 'true');
    this.showDashboard();
  }

  showDashboard() {
    document.getElementById('login-screen').style.display = 'none';
    document.getElementById('app-screen').style.display = 'block';
    document.querySelector('.header-title').textContent = this.tabTitles[this.currentTab];
    this.bindNavigation();
    this.renderAllTabs();
    this.setTab(this.currentTab);
  }

  bindNavigation() {
    document.querySelectorAll('[data-tab]').forEach((element) => {
      element.onclick = (event) => {
        event.preventDefault();
        this.setTab(element.dataset.tab);
      };
    });

    document.querySelectorAll('[data-action="logout"]').forEach((element) => {
      element.onclick = (event) => {
        event.preventDefault();
        this.logout();
      };
    });

    document.querySelectorAll('.verification-tab-btn').forEach((button) => {
      button.onclick = () => this.switchVerificationSection(button.dataset.verificationTab);
    });
  }

  setTab(tab) {
    this.currentTab = tab;
    document.querySelector('.header-title').textContent = this.tabTitles[tab] || 'Admin Dashboard';

    document.querySelectorAll('.tab-content').forEach((section) => {
      section.classList.toggle('active', section.id === `tab-${tab}`);
    });

    document.querySelectorAll('.tab-button').forEach((button) => {
      button.classList.toggle('active', button.dataset.tab === tab);
    });

    document.querySelectorAll('.sidebar-nav a[data-tab]').forEach((link) => {
      link.classList.toggle('active', link.dataset.tab === tab);
    });
  }

  renderAllTabs() {
    this.renderDashboard();
    this.renderSimpleTable('tab-users', 'Users', ['Name', 'Email', 'Phone', 'Status'], localAdminData.users.map((user) => [user.name, user.email, user.phone, this.badge(user.status)]));
    this.renderSimpleTable('tab-doctors', 'Doctors', ['Name', 'Specialty', 'Email', 'Status', 'Fee'], localAdminData.doctors.map((doctor) => [doctor.name, doctor.specialty, doctor.email, this.badge(doctor.status), doctor.fee]));
    this.renderVerification();
    this.renderCommissions();
    this.renderSimpleTable('tab-appointments', 'Appointments', ['Patient', 'Doctor', 'Date', 'Time', 'Status'], localAdminData.appointments.map((item) => [item.patient, item.doctor, item.date, item.time, this.badge(item.status)]));
    this.renderSimpleTable('tab-payments', 'Payments', ['Patient', 'Doctor', 'Amount', 'Commission', 'Status'], localAdminData.payments.map((item) => [item.patient, item.doctor, item.amount, item.commission, this.badge(item.status)]));
    this.renderSimpleTable('tab-reviews', 'Reviews', ['Doctor', 'Patient', 'Rating', 'Comment'], localAdminData.reviews.map((item) => [item.doctor, item.patient, item.rating, item.comment]));
    this.renderSimpleTable('tab-messages', 'Messages', ['Sender', 'Preview', 'Status'], localAdminData.messages.map((item) => [item.sender, item.preview, this.badge(item.status.toLowerCase())]));
    this.renderSimpleTable('tab-health-records', 'Health Records', ['Patient', 'Type', 'Title', 'Value'], localAdminData.healthRecords.map((item) => [item.patient, item.type, item.title, item.value]));
    this.renderSimpleTable('tab-prescriptions', 'Prescriptions', ['Patient', 'Doctor', 'Medicine', 'Status'], localAdminData.prescriptions.map((item) => [item.patient, item.doctor, item.medicine, this.badge(item.status)]));
    this.renderSimpleTable('tab-consultations', 'Consultations', ['Patient', 'Doctor', 'Mode', 'Status'], localAdminData.consultations.map((item) => [item.patient, item.doctor, item.mode, this.badge(item.status)]));
    this.renderSettings();
  }

  renderDashboard() {
    const pendingDoctors = localAdminData.doctors.filter((doctor) => doctor.status === 'pending').length;
    const totalRevenue = localAdminData.payments.reduce((sum, payment) => {
      return sum + Number(payment.amount.replace(/[^\d.]/g, ''));
    }, 0);

    document.getElementById('dashboard-stats').innerHTML = `
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;">
        ${this.statCard('Patients', localAdminData.users.length, 'Active local preview users')}
        ${this.statCard('Doctors', localAdminData.doctors.length, 'Approved and pending providers')}
        ${this.statCard('Pending Reviews', pendingDoctors, 'Doctor accounts awaiting review')}
        ${this.statCard('Revenue Preview', `GHS ${totalRevenue.toFixed(2)}`, 'Local sample payment data')}
      </div>
      <div style="margin-top:24px;background:white;border-radius:12px;padding:20px;">
        <h3 style="margin-top:0;">Local Shell Status</h3>
        <p style="color:var(--gray-500);margin-bottom:0;">Backend access has been removed. This admin dashboard now runs entirely from local sample data so you can rebuild the management flow without Supabase dependencies.</p>
      </div>
    `;
  }

  renderVerification() {
    const total = localAdminData.verification.length;
    const approved = localAdminData.verification.filter((item) => item.status === 'approved').length;
    const rejected = localAdminData.verification.filter((item) => item.status === 'rejected').length;
    const pending = localAdminData.verification.filter((item) => item.status === 'pending').length;

    document.getElementById('stat-total-verifications').textContent = total;
    document.getElementById('stat-auto-approved').textContent = approved;
    document.getElementById('stat-manual-review').textContent = pending;
    document.getElementById('stat-rejected').textContent = rejected;

    const renderSection = (status, elementId) => {
      const rows = localAdminData.verification
        .filter((item) => item.status === status)
        .map((item) => `
          <tr>
            <td>${item.doctor}</td>
            <td>${item.specialty}</td>
            <td>${item.confidence}</td>
            <td>${this.badge(item.status)}</td>
            <td>${status === 'pending' ? `<button class="btn btn-primary" onclick="approveDoctor('${item.doctorId}')">Approve</button> <button class="btn btn-outline" onclick="rejectDoctor('${item.doctorId}')">Reject</button>` : 'Local preview only'}</td>
          </tr>
        `)
        .join('');

      document.getElementById(elementId).innerHTML = this.tableMarkup(
        ['Doctor', 'Specialty', 'Confidence', 'Status', 'Actions'],
        rows || '<tr><td colspan="5" style="text-align:center;padding:20px;color:var(--gray-500);">No records</td></tr>'
      );
    };

    renderSection('pending', 'verification-pending');
    renderSection('approved', 'verification-approved');
    renderSection('rejected', 'verification-rejected');
    this.switchVerificationSection('pending');
  }

  switchVerificationSection(status) {
    document.querySelectorAll('.verification-section').forEach((section) => {
      section.style.display = section.id === `verification-${status}` ? 'block' : 'none';
    });

    document.querySelectorAll('.verification-tab-btn').forEach((button) => {
      const active = button.dataset.verificationTab === status;
      button.classList.toggle('active', active);
      button.style.color = active ? 'var(--primary-color)' : 'var(--gray-500)';
      button.style.borderBottom = active ? '2px solid var(--primary-color)' : 'none';
    });
  }

  renderCommissions() {
    const settings = localAdminData.commissionSettings;
    document.getElementById('stat-commission-rate').textContent = `${settings.platformRate}%`;
    document.getElementById('stat-total-commission').textContent = 'GHS 49.50';
    document.getElementById('stat-pending-commission').textContent = 'GHS 22.50';
    document.getElementById('stat-paid-commission').textContent = 'GHS 27.00';

    document.getElementById('doctor-commission-rate').value = settings.doctorRate;
    document.getElementById('platform-commission-rate').value = settings.platformRate;
    document.getElementById('min-commission-amount').value = settings.minCommission;
    document.getElementById('payment-frequency').value = settings.paymentFrequency;

    document.getElementById('commission-tiers').innerHTML = localAdminData.commissionTiers.map((tier) => `
      <tr>
        <td>${tier.name}</td>
        <td>${tier.minConsultations}</td>
        <td>${tier.rate}</td>
        <td>${tier.bonus}</td>
        <td><button class="btn btn-outline" onclick="removeCommissionTier('${tier.id}')">Remove</button></td>
      </tr>
    `).join('');
  }

  renderSettings() {
    const element = document.getElementById('tab-settings');
    element.innerHTML = `
      <div style="background:white;border-radius:12px;padding:20px;">
        <h3 style="margin-top:0;">Local Platform State</h3>
        <p style="color:var(--gray-500);">This admin workspace is now a UI shell. Use it to redesign flows, navigation, and state management without any live database dependency.</p>
        <ul style="color:var(--gray-600);line-height:1.8;">
          <li>Login uses a local-only session stored in localStorage.</li>
          <li>All dashboard tabs render seeded preview data.</li>
          <li>Doctor approval and commission tools update only local in-memory state.</li>
        </ul>
      </div>
    `;
  }

  renderSimpleTable(containerId, title, headers, rows) {
    const container = document.getElementById(containerId);
    const rowMarkup = rows.map((row) => `<tr>${row.map((cell) => `<td>${cell}</td>`).join('')}</tr>`).join('');
    container.innerHTML = `
      <div style="background:white;border-radius:12px;padding:20px;">
        <h3 style="margin-top:0;">${title}</h3>
        ${this.tableMarkup(headers, rowMarkup || `<tr><td colspan="${headers.length}" style="text-align:center;padding:20px;color:var(--gray-500);">No records</td></tr>`)}
      </div>
    `;
  }

  tableMarkup(headers, bodyRows) {
    return `
      <table class="data-table" style="width:100%;">
        <thead><tr>${headers.map((header) => `<th>${header}</th>`).join('')}</tr></thead>
        <tbody>${bodyRows}</tbody>
      </table>
    `;
  }

  statCard(label, value, helper) {
    return `
      <div class="stat-card">
        <div class="stat-value">${value}</div>
        <div class="stat-label">${label}</div>
        <div style="margin-top:8px;color:var(--gray-500);font-size:12px;">${helper}</div>
      </div>
    `;
  }

  badge(status) {
    const normalized = String(status).toLowerCase();
    const colors = {
      approved: '#16a34a',
      active: '#16a34a',
      completed: '#16a34a',
      confirmed: '#2563eb',
      pending: '#d97706',
      unread: '#d97706',
      rejected: '#dc2626',
    };
    const color = colors[normalized] || '#475569';
    return `<span style="display:inline-block;padding:4px 10px;border-radius:999px;background:${color}15;color:${color};font-size:12px;font-weight:600;">${status}</span>`;
  }

  logout() {
    window.localStorage.removeItem(this.sessionKey);
    window.location.reload();
  }

  approveDoctor(doctorId) {
    const doctor = localAdminData.doctors.find((item) => item.id === doctorId);
    const verification = localAdminData.verification.find((item) => item.doctorId === doctorId);
    if (doctor) doctor.status = 'approved';
    if (verification) verification.status = 'approved';
    this.renderAllTabs();
    this.setTab('verification');
  }

  rejectDoctor(doctorId) {
    const doctor = localAdminData.doctors.find((item) => item.id === doctorId);
    const verification = localAdminData.verification.find((item) => item.doctorId === doctorId);
    if (doctor) doctor.status = 'rejected';
    if (verification) verification.status = 'rejected';
    this.renderAllTabs();
    this.setTab('verification');
  }

  saveCommissionSettings() {
    localAdminData.commissionSettings.doctorRate = Number(document.getElementById('doctor-commission-rate').value || 85);
    localAdminData.commissionSettings.platformRate = Number(document.getElementById('platform-commission-rate').value || 15);
    localAdminData.commissionSettings.minCommission = Number(document.getElementById('min-commission-amount').value || 20);
    localAdminData.commissionSettings.paymentFrequency = document.getElementById('payment-frequency').value || 'weekly';
    this.renderCommissions();
    alert('Commission settings saved locally.');
  }

  addCommissionTier() {
    const name = document.getElementById('tier-name').value.trim();
    const minConsultations = document.getElementById('tier-min-consultations').value.trim();
    const rate = document.getElementById('tier-rate').value.trim();
    const bonus = document.getElementById('tier-bonus').value.trim();

    if (!name || !minConsultations || !rate || !bonus) {
      alert('Fill all tier fields first.');
      return;
    }

    localAdminData.commissionTiers.push({
      id: `tier-${Date.now()}`,
      name,
      minConsultations,
      rate: `${rate}%`,
      bonus: `GHS ${bonus}`,
    });

    document.getElementById('tier-modal').classList.remove('active');
    document.getElementById('tier-name').value = '';
    document.getElementById('tier-min-consultations').value = '';
    document.getElementById('tier-rate').value = '';
    document.getElementById('tier-bonus').value = '';
    this.renderCommissions();
  }

  removeCommissionTier(tierId) {
    localAdminData.commissionTiers = localAdminData.commissionTiers.filter((tier) => tier.id !== tierId);
    this.renderCommissions();
  }
}

const adminDashboard = new AdminDashboard();
window.addEventListener('DOMContentLoaded', () => adminDashboard.init());
window.saveCommissionSettings = () => adminDashboard.saveCommissionSettings();
window.addCommissionTier = () => adminDashboard.addCommissionTier();
window.removeCommissionTier = (tierId) => adminDashboard.removeCommissionTier(tierId);
window.approveDoctor = (doctorId) => adminDashboard.approveDoctor(doctorId);
window.rejectDoctor = (doctorId) => adminDashboard.rejectDoctor(doctorId);
