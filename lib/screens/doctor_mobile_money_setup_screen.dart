import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorMobileMoneySetupScreen extends StatefulWidget {
  @override
  State<DoctorMobileMoneySetupScreen> createState() =>
      _DoctorMobileMoneySetupScreenState();
}

class _DoctorMobileMoneySetupScreenState
    extends State<DoctorMobileMoneySetupScreen> {
  final _authService = AuthService();
  final TextEditingController mobileNumberController = TextEditingController();

  String selectedProvider = 'mtn';
  bool isLoading = false;

  final List<Map<String, String>> providers = [
    {'name': 'MTN Ghana', 'code': 'mtn'},
    {'name': 'Vodafon Ghana', 'code': 'vodafon'},
    {'name': 'Airtel Ghana', 'code': 'airtel'},
    {'name': 'Tigo Ghana', 'code': 'tigo'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      mobileNumberController.text = user.mobileMoneyNumber ?? '';
      selectedProvider = user.mobileMoneyProvider ?? selectedProvider;
    });
  }

  Future<void> _setupMobileMoneyAccount() async {
    if (mobileNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your mobile number')),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first')),
      );
      return;
    }

    setState(() => isLoading = true);

    final updatedUser = user.copyWith(
      mobileMoneyNumber: mobileNumberController.text.trim(),
      mobileMoneyProvider: selectedProvider,
      payoutRecipientCode:
          'recipient_${user.id}_${selectedProvider.toLowerCase()}',
    );

    try {
      await _authService.updateCurrentUser(updatedUser);
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile money account saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Get.back(result: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save mobile money details.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Setup Mobile Money'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Text(
                'Enter the mobile money number you want to use for doctor payouts.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Mobile Money Provider',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedProvider,
                isExpanded: true,
                underline: const SizedBox(),
                items: providers.map((provider) {
                  return DropdownMenuItem(
                    value: provider['code'],
                    child: Text(provider['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => selectedProvider = value!);
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mobile Number',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: mobileNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'e.g., 0501234567',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your ${selectedProvider.toUpperCase()} mobile number without the country code',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'How it works',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Text('1. Patient payment is shown in the UI preview.'),
                  SizedBox(height: 8),
                  Text('2. Platform commission is calculated by the platform.'),
                  SizedBox(height: 8),
                  Text(
                      '3. Your payout destination will be used for doctor payouts.'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _setupMobileMoneyAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Mobile Money Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
