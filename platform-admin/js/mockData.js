// Mock Data for Admin Dashboard
const mockData = {
  // Users/Patients
  users: [
    {
      id: 'user_1',
      name: 'John Doe',
      email: 'john@example.com',
      phone: '+1234567890',
      registeredDate: '2025-01-15',
      status: 'active',
      totalAppointments: 5,
      profileImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'
    },
    {
      id: 'user_2',
      name: 'Sarah Smith',
      email: 'sarah@example.com',
      phone: '+1234567891',
      registeredDate: '2025-02-20',
      status: 'active',
      totalAppointments: 3,
      profileImage: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100'
    },
    {
      id: 'user_3',
      name: 'Mike Johnson',
      email: 'mike@example.com',
      phone: '+1234567892',
      registeredDate: '2025-03-10',
      status: 'inactive',
      totalAppointments: 0,
      profileImage: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100'
    },
  ],

  // Doctors
  doctors: [
    {
      id: 'doc_1',
      name: 'Dr. Stella Kane',
      specialty: 'Cardiologist',
      email: 'stella@hospital.com',
      phone: '+1234567900',
      experience: 8,
      rating: 4.8,
      patients: 150,
      consultationFee: 500,
      status: 'active',
      profileImage: 'https://images.unsplash.com/photo-1559839734033-6461efaf3cfd?w=100',
      joinedDate: '2020-05-10'
    },
    {
      id: 'doc_2',
      name: 'Dr. Joseph Cart',
      specialty: 'General Physician',
      email: 'joseph@hospital.com',
      phone: '+1234567901',
      experience: 12,
      rating: 4.9,
      patients: 220,
      consultationFee: 400,
      status: 'active',
      profileImage: 'https://images.unsplash.com/photo-1612349317453-3ad32c4a0b2f?w=100',
      joinedDate: '2018-08-22'
    },
    {
      id: 'doc_3',
      name: 'Dr. Emily Davis',
      specialty: 'Neurologist',
      email: 'emily@hospital.com',
      phone: '+1234567902',
      experience: 10,
      rating: 4.7,
      patients: 180,
      consultationFee: 600,
      status: 'active',
      profileImage: 'https://images.unsplash.com/photo-1438761681033-6461efaf3cfd?w=100',
      joinedDate: '2019-03-15'
    },
  ],

  // Appointments
  appointments: [
    {
      id: 'apt_1',
      patientName: 'John Doe',
      patientEmail: 'john@example.com',
      doctorName: 'Dr. Stella Kane',
      specialty: 'Cardiologist',
      date: '2026-04-20',
      time: '10:00 AM',
      status: 'scheduled',
      type: 'video',
      consultationFee: 500,
      notes: 'Regular checkup'
    },
    {
      id: 'apt_2',
      patientName: 'Sarah Smith',
      patientEmail: 'sarah@example.com',
      doctorName: 'Dr. Joseph Cart',
      specialty: 'General Physician',
      date: '2026-04-18',
      time: '2:30 PM',
      status: 'completed',
      type: 'in-clinic',
      consultationFee: 400,
      notes: 'Follow-up consultation'
    },
    {
      id: 'apt_3',
      patientName: 'Mike Johnson',
      patientEmail: 'mike@example.com',
      doctorName: 'Dr. Emily Davis',
      specialty: 'Neurologist',
      date: '2026-04-25',
      time: '3:00 PM',
      status: 'pending',
      type: 'video',
      consultationFee: 600,
      notes: 'Initial consultation'
    },
  ],

  // Payments
  payments: [
    {
      id: 'pay_1',
      appointmentId: 'apt_1',
      patientName: 'John Doe',
      amount: 500,
      method: 'Credit Card',
      status: 'completed',
      transactionId: 'TXN_001',
      date: '2026-04-19',
      receipt: 'RCP_001'
    },
    {
      id: 'pay_2',
      appointmentId: 'apt_2',
      patientName: 'Sarah Smith',
      amount: 400,
      method: 'Debit Card',
      status: 'completed',
      transactionId: 'TXN_002',
      date: '2026-04-18',
      receipt: 'RCP_002'
    },
    {
      id: 'pay_3',
      appointmentId: 'apt_3',
      patientName: 'Mike Johnson',
      amount: 600,
      method: 'UPI',
      status: 'pending',
      transactionId: 'TXN_003',
      date: '2026-04-17',
      receipt: null
    },
  ],

  // Dashboard Statistics
  statistics: {
    totalUsers: 150,
    totalDoctors: 25,
    totalAppointments: 342,
    totalRevenue: 85000,
    activeAppointments: 15,
    completedAppointments: 320,
    pendingPayments: 5,
    averageRating: 4.7,
    appointmentsThisMonth: 42,
    revenueThisMonth: 18500,
    newUsersThisMonth: 12,
    doctorUtilization: 78
  },

  // Chat/Messages
  messages: [
    {
      id: 'msg_1',
      senderId: 'user_1',
      senderName: 'John Doe',
      senderType: 'patient',
      recipientId: 'doc_1',
      recipientName: 'Dr. Stella Kane',
      message: 'Hello Doctor, I have some concerns about my medication.',
      timestamp: '2026-04-17 10:30 AM',
      read: false
    },
    {
      id: 'msg_2',
      senderId: 'doc_1',
      senderName: 'Dr. Stella Kane',
      senderType: 'doctor',
      recipientId: 'user_1',
      recipientName: 'John Doe',
      message: 'Sure, let me help you with that. Can you schedule a consultation?',
      timestamp: '2026-04-17 11:00 AM',
      read: true
    },
  ],

  // Reviews
  reviews: [
    {
      id: 'rev_1',
      doctorId: 'doc_1',
      doctorName: 'Dr. Stella Kane',
      patientName: 'John Doe',
      rating: 5,
      title: 'Excellent service',
      comment: 'Very professional and caring doctor',
      date: '2026-04-15',
      verified: true,
      helpful: 12
    },
    {
      id: 'rev_2',
      doctorId: 'doc_2',
      doctorName: 'Dr. Joseph Cart',
      patientName: 'Sarah Smith',
      rating: 4,
      title: 'Good consultation',
      comment: 'Helpful advice and diagnosis',
      date: '2026-04-14',
      verified: true,
      helpful: 8
    },
  ],

  // Health Records
  healthRecords: [
    {
      id: 'hr_1',
      patientId: 'user_1',
      patientName: 'John Doe',
      type: 'vital',
      title: 'Blood Pressure',
      value: '120/80',
      unit: 'mmHg',
      normalRange: '90-120 / 60-80',
      date: '2026-04-16',
      status: 'normal'
    },
    {
      id: 'hr_2',
      patientId: 'user_1',
      patientName: 'John Doe',
      type: 'lab',
      title: 'Blood Sugar',
      value: '95',
      unit: 'mg/dL',
      normalRange: '70-100',
      date: '2026-04-16',
      status: 'normal'
    },
  ],

  // Prescriptions
  prescriptions: [
    {
      id: 'presc_1',
      patientId: 'user_1',
      patientName: 'John Doe',
      doctorId: 'doc_1',
      doctorName: 'Dr. Stella Kane',
      medicines: [
        {
          name: 'Aspirin',
          dosage: '100mg',
          frequency: 'Once daily',
          duration: '30 days'
        }
      ],
      date: '2026-04-15',
      status: 'active'
    },
  ],

  // Video Consultations
  consultations: [
    {
      id: 'cons_1',
      patientId: 'user_1',
      patientName: 'John Doe',
      doctorId: 'doc_1',
      doctorName: 'Dr. Stella Kane',
      type: 'video',
      status: 'scheduled',
      scheduledTime: '2026-04-20 10:00 AM',
      duration: 30,
      roomId: 'ROOM_001',
      recordingUrl: null
    },
  ]
};
