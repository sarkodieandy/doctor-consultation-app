import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  @override
  State<DoctorProfileEditScreen> createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final _authService = AuthService();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  late TextEditingController _feeController;
  String _selectedSpecialty = '';

  bool _isLoading = false;

  final List<String> _specialties = [
    'General Practitioner',
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Pediatrician',
    'Orthopedist',
    'Psychiatrist',
    'Gynecologist',
    'Ophthalmologist',
    'ENT Specialist',
    'Dentist',
    'Surgeon',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _experienceController = TextEditingController(text: user?.experience ?? '');
    _feeController = TextEditingController(
        text: user?.consultationFee?.toStringAsFixed(2) ?? '');
    _selectedSpecialty = user?.specialty ?? _specialties.first;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    setState(() => _isLoading = true);

    await Future.delayed(Duration(seconds: 1));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBlueColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kWhiteColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: kWhiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: kBlueColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: kWhiteColor,
                        child: Icon(Icons.person, size: 55, color: kBlueColor),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kOrangeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: kWhiteColor, width: 2),
                          ),
                          child: Icon(Icons.camera_alt,
                              color: kWhiteColor, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Personal Info Section
              _buildSectionCard(
                'Personal Information',
                [
                  _buildField('First Name', _firstNameController,
                      Icons.person_outlined),
                  SizedBox(height: 14),
                  _buildField(
                      'Last Name', _lastNameController, Icons.person_outlined),
                  SizedBox(height: 14),
                  _buildField(
                      'Phone Number', _phoneController, Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                ],
              ),
              SizedBox(height: 18),

              // Professional Info Section
              _buildSectionCard(
                'Professional Information',
                [
                  Text(
                    'Specialty',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kTitleTextColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: kWhiteColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: kBlueColor.withOpacity(0.25)),
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: _specialties.contains(_selectedSpecialty)
                          ? _selectedSpecialty
                          : null,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      items: _specialties.map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSpecialty = value ?? '';
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 14),
                  _buildField('Years of Experience', _experienceController,
                      Icons.work_outlined),
                  SizedBox(height: 14),
                  _buildField('Consultation Fee (GHS)', _feeController,
                      Icons.attach_money,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true)),
                  SizedBox(height: 14),
                  Text(
                    'Bio',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kTitleTextColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tell patients about yourself...',
                      hintStyle: TextStyle(color: kSearchTextColor),
                      filled: true,
                      fillColor: kWhiteColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            BorderSide(color: kBlueColor.withOpacity(0.25)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(color: kBlueColor, width: 1.8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide:
                            BorderSide(color: kBlueColor.withOpacity(0.25)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: MaterialButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  color: kBlueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(kWhiteColor),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: TextStyle(
                            color: kWhiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () async {
                    await _authService.logout();
                    Get.offAllNamed('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Color(0xffFF6B6B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xffFF6B6B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBlueColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: kTitleTextColor,
      ),
    );
  }

  Widget _buildField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: kTitleTextColor,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintStyle: TextStyle(color: kSearchTextColor),
            filled: true,
            fillColor: kWhiteColor,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: kBlueColor.withOpacity(0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: kBlueColor, width: 1.8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: kBlueColor.withOpacity(0.25)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: kBlueColor, size: 20),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0),
          ),
        ),
      ],
    );
  }
}
