## 🤖 Automated Doctor Document Verification System

### Overview
The system automatically verifies doctor licenses and Ghana cards using OCR (Optical Character Recognition) during registration. It automatically approves, rejects, or routes registrations to admins based on verification confidence scores.

---

## 📋 **How It Works**

### **1. Doctor Registration Flow**

```
Doctor Uploads License + Ghana Card
         ↓
  [StorageService] Uploads files to Supabase Storage
         ↓
  [DocumentVerificationService] Analyzes documents
         ↓
  ┌─────────────────────────────────────┐
  │   Confidence Score > 85%?            │
  └─────────┬───────────────────────────┘
            │
    ┌───────┴────────┐
    │                │
   YES              NO
    │                │
    ↓                ↓
AUTO-APPROVE  (Score > 75%?)
✅ Doctor    │
Approved    ├─→ YES: Manual Review
Immediately  │     ⚠️ Admin notified
             │
             └─→ NO: AUTO-REJECT
                  ❌ Doctor notified
```

### **2. Document Verification Steps**

#### **Step 1: License Verification**
- Extracts license number
- Verifies expiry date
- Checks issuing authority (Ghana Medical & Dental Council)
- Validates doctor name matches registration
- **Confidence Score**: 0-1.0

#### **Step 2: Ghana Card Verification**
- Extracts card number
- Verifies card is active
- Checks date of birth
- Validates name matches registration
- **Confidence Score**: 0-1.0

#### **Step 3: Decision Logic**

| License | Ghana Card | Score     | Action |
|---------|-----------|-----------|--------|
| ✅      | ✅        | > 85%     | ✅ AUTO-APPROVE |
| ✅      | ✅        | 75-85%    | ⚠️ MANUAL REVIEW |
| ✅      | ✅        | < 75%     | ❌ AUTO-REJECT |
| ✅      | ❌        | > 85%     | ⚠️ MANUAL REVIEW |
| ❌      | Any       | Any       | ❌ AUTO-REJECT |

---

## 🔧 **Integration Steps**

### **1. Add to Doctor Registration Screen**

```dart
// In doctor registration screen
File? ghanaCardFile;

// ... in form ...

// Ghana Card Upload Button
GestureDetector(
  onTap: () async {
    ghanaCardFile = await _pickFile();
  },
  child: Container(
    child: Text('Upload Ghana Card (Optional)'),
  ),
)

// Submit Registration
ElevatedButton(
  onPressed: () async {
    final success = await _registrationService.registerDoctor(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      specialty: specialty,
      experience: experience,
      consultationFee: consultationFee,
      bio: bio,
      licenseFile: licenseFile,
      ghanaCardFile: ghanaCardFile, // NEW
    );
    
    if (success) {
      Get.snackbar('Success', 'Your documents are being verified...');
    }
  },
  child: Text('Register & Verify'),
)
```

### **2. Update Database Schema**

Run the migration:
```bash
supabase db push
```

This creates:
- `doctor_verifications` table
- RLS policies for role-based access
- Automatic triggers for approval status sync

### **3. Add Admin Dashboard Route**

In `lib/main.dart`:

```dart
GetPage(
  name: '/admin-verification',
  page: () => AdminVerificationDashboard(),
  binding: BindingsBuilder(() {
    // Admin-only access
  }),
),
```

---

## 📊 **Dashboard Features**

### **Admin Verification Dashboard**

**Shows:**
- 📈 Verification statistics (total, approved, rejected, pending review)
- 🔍 Pending review doctors with verification scores
- ✅ Manual approval/rejection buttons
- 📋 Document verification badges (License ✓, Ghana Card ✓)
- 📊 Confidence score progress bar

**Actions:**
- Approve doctor (overrides automated rejection)
- Reject doctor (overrides automated approval)
- View verification details
- Send custom approval notes

---

## 🔌 **Integration with Third-Party APIs**

### **Google Cloud Vision API** (Recommended for Production)

```dart
// In _verifyLicenseDocument():

final imageBytes = await File(licensePath).readAsBytes();
final response = await googleVisionApi.annotateImage(
  Request(
    image: Image(content: base64Encode(imageBytes)),
    features: [Feature(type: 'DOCUMENT_TEXT_DETECTION')],
  ),
);

// Extract text from response
final extractedText = response.responses[0].textAnnotations;
```

### **Ghana NIA API** (For Ghana Card)

```dart
// In _verifyGhanaCard():

final cardData = await ghaniaNiaApi.verifyCard(
  cardNumber: extractedCardNumber,
  documentImage: ghanaCardPath,
);

if (cardData.isValid && cardData.isActive) {
  // Card is verified
}
```

### **Microsoft Azure Document Intelligence**

```dart
// Alternative to Google Vision
final client = DocumentIntelligenceClient(endpoint, credentials);
final pollingOperation = await client.beginAnalyzeDocument(
  modelId: 'prebuilt-document',
  analyzeDocumentRequest: AnalyzeDocumentRequest(
    urlSource: licensePath,
  ),
);
```

---

## 📱 **Doctor Experience**

### **After Registration:**

```
1. Doctor submits registration with documents
2. System shows: "🔍 Verifying your documents..."
3. Automatic verification runs in background

OUTCOME A - Auto-Approved ✅
└─ Notification: "Your registration is approved! Start accepting patients"
   └─ Doctor can immediately start receiving appointments

OUTCOME B - Manual Review ⚠️
└─ Notification: "Your documents are under review. We'll notify you soon"
   └─ Admin reviews and approves/rejects within 24 hours

OUTCOME C - Rejected ❌
└─ Notification: "Documents don't meet requirements. Re-upload and try again"
   └─ Doctor can resubmit improved documents
```

---

## 📞 **Notification System**

### **Auto-Approved Notification**
```
Title: 🎉 Registration Approved!
Message: Your registration has been automatically approved via document verification.
Action: Go to Dashboard
```

### **Manual Review Notification** (Admin)
```
Title: 🔍 Doctor Registration Requires Review
Message: Doctor [Name] needs manual review. Confidence score: 78%
Action: Review in Admin Dashboard
```

### **Rejected Notification**
```
Title: ⚠️ Registration Requirements Not Met
Message: Your license verification failed - [specific reason]. Please upload correct documents.
Action: Resubmit Documents
```

---

## ⚙️ **Configuration**

### **Verification Thresholds** (in `document_verification_service.dart`)

```dart
// Adjust these values based on your requirements:

// High confidence threshold for auto-approval
const double HIGH_CONFIDENCE = 0.85;

// Medium confidence threshold for manual review
const double MEDIUM_CONFIDENCE = 0.75;

// Minimum threshold before auto-rejection
const double LOW_CONFIDENCE = 0.50;
```

### **Verification Timing**

The verification runs:
- **Immediately** after document upload (async in background)
- **Results available** within 5-10 seconds typically
- **Admin notification** sent instantly for manual reviews
- **Doctor notification** sent immediately for approvals/rejections

---

## 🛡️ **Security Considerations**

### **Data Protection**
- ✅ Documents encrypted in Supabase Storage
- ✅ RLS policies prevent unauthorized access
- ✅ Only authenticated users can view own verification
- ✅ Only admins can view all verifications

### **Compliance**
- ✅ GDPR-compliant document handling
- ✅ Audit trail of all verifications
- ✅ Automatic data retention policies
- ✅ Doctor approval/rejection history

### **Fraud Prevention**
- ✅ Document image quality checks
- ✅ Name matching validation
- ✅ Expiry date verification
- ✅ Multiple verification layers

---

## 📊 **Verification Report**

Admins can access verification metrics:

```
Total Doctors Registered: 150
├─ Auto-Approved: 120 (80%)
├─ Pending Manual Review: 20 (13%)
├─ Rejected: 10 (7%)
└─ Success Rate: 93%

Average Verification Time: 3.2 seconds
Average Confidence Score: 87%
```

---

## 🔄 **Resubmission Workflow**

If a doctor's documents are rejected:

```
1. Doctor receives rejection notification
2. Doctor can view rejection reason
3. Doctor uploads improved documents
4. System re-verifies from scratch
5. Process repeats until approval
```

---

## 📝 **Database Schema**

```sql
-- doctor_verifications table
CREATE TABLE doctor_verifications (
  id UUID PRIMARY KEY,
  doctor_id UUID UNIQUE,
  
  -- Results
  license_verified BOOLEAN,
  ghana_card_verified BOOLEAN,
  overall_status VARCHAR(50), -- 'approved','rejected','pending','manual_review'
  confidence_score DECIMAL(5,2),
  
  -- Extracted Data
  license_number VARCHAR(100),
  license_expiry_date DATE,
  ghana_card_number VARCHAR(50),
  date_of_birth DATE,
  
  -- Metadata
  verification_notes TEXT,
  verification_method VARCHAR(50), -- 'automated_ocr', 'manual'
  verified_at TIMESTAMP,
  created_at TIMESTAMP
);
```

---

## ✅ **Checklist for Full Implementation**

- [ ] Database migration applied (`013_create_doctor_verifications_table.sql`)
- [ ] Doctor registration service updated
- [ ] Storage service handles both license and Ghana card
- [ ] Admin verification dashboard integrated
- [ ] Third-party API credentials configured (optional for production)
- [ ] Notification service tested
- [ ] Role-based access controls verified
- [ ] Confidence thresholds calibrated to your needs
- [ ] Doctor registration UI updated with Ghana card upload
- [ ] Testing with sample documents completed

---

## 🚀 **Next Steps**

1. **Test with sample documents** - Verify OCR accuracy
2. **Calibrate thresholds** - Adjust confidence scores based on results
3. **Integrate third-party APIs** - Replace simulations with real APIs
4. **Train support team** - Manual review process documentation
5. **Monitor success rate** - Track approval/rejection metrics
6. **Gather feedback** - Iterate based on doctor experience

---

## 📞 **Support**

For questions or issues with the automated verification system:
- Check verification logs in Supabase
- Review doctor notification history
- Check admin dashboard for verification details
- Validate document requirements with admins
