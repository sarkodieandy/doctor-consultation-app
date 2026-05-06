import 'dart:typed_data';

import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:doctor_consultation_app/utils/profile_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  @override
  State<DoctorProfileEditScreen> createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  late TextEditingController _feeController;
  String _selectedSpecialty = '';
  XFile? _selectedProfileImageFile;
  Uint8List? _selectedProfileImageBytes;

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

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kWhiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: kTitleTextColor,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: kBlueColor.withOpacity(0.12),
                    child:
                        Icon(Icons.photo_library_outlined, color: kBlueColor),
                  ),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickProfilePicture(ImageSource.gallery);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: kBlueColor.withOpacity(0.12),
                    child: Icon(Icons.photo_camera_outlined, color: kBlueColor),
                  ),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickProfilePicture(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickProfilePicture(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxHeight: 1024,
        maxWidth: 1024,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedProfileImageFile = pickedFile;
        _selectedProfileImageBytes = bytes;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture selected'),
          backgroundColor: kBlueColor,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to pick image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider<Object>? _profileImageProvider(String imagePath) {
    if (_selectedProfileImageBytes != null) {
      return MemoryImage(_selectedProfileImageBytes!);
    }
    return profileImageProvider(imagePath);
  }

  Future<void> _saveProfile() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      return;
    }

    setState(() => _isLoading = true);

    final parsedFee = double.tryParse(_feeController.text.trim());
    final updatedUser = currentUser.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
      specialty: _selectedSpecialty.trim().isEmpty ? null : _selectedSpecialty,
      experience: _experienceController.text.trim(),
      consultationFee: parsedFee ?? currentUser.consultationFee,
      profileImage: _selectedProfileImageFile?.path ?? currentUser.profileImage,
    );

    await _authService.updateCurrentUser(
      updatedUser,
      profilePictureFile: _selectedProfileImageFile,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xffE8F1FF),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kTitleTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/images/doctorbg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeroCard(user),
                  SizedBox(height: 24),

                  // Personal Info Section
                  _buildSectionCard(
                    'Personal Information',
                    Icons.badge_outlined,
                    [
                      _buildField('First Name', _firstNameController,
                          Icons.person_outlined),
                      SizedBox(height: 14),
                      _buildField('Last Name', _lastNameController,
                          Icons.person_outlined),
                      SizedBox(height: 14),
                      _buildField('Phone Number', _phoneController,
                          Icons.phone_outlined,
                          keyboardType: TextInputType.phone),
                    ],
                  ),
                  SizedBox(height: 18),

                  // Professional Info Section
                  _buildSectionCard(
                    'Professional Information',
                    Icons.medical_services_outlined,
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
                          color: const Color(0xffF8FBFF),
                          borderRadius: BorderRadius.circular(15),
                          border:
                              Border.all(color: kBlueColor.withOpacity(0.18)),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              _specialties.contains(_selectedSpecialty)
                                  ? _selectedSpecialty
                                  : null,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
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
                          fillColor: const Color(0xffF8FBFF),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                BorderSide(color: kBlueColor.withOpacity(0.18)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                BorderSide(color: kBlueColor, width: 1.8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide:
                                BorderSide(color: kBlueColor.withOpacity(0.18)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
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
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeroCard(user) {
    final profileImage = _profileImageProvider(user?.profileImage ?? '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff3B6FEC), Color(0xff2351C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff2351C1).withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white,
                  backgroundImage: profileImage,
                  child: profileImage == null
                      ? Icon(Icons.person, size: 56, color: kBlueColor)
                      : null,
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xff0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Doctor Profile',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user?.specialty ?? 'Specialist',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the profile photo to upload a new image',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.72),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBlueColor.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kBlueColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: kBlueColor, size: 18),
              ),
              SizedBox(width: 12),
              _buildSectionTitle(title),
            ],
          ),
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
            fillColor: const Color(0xffF8FBFF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: kBlueColor.withOpacity(0.18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: kBlueColor, width: 1.8),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: kBlueColor.withOpacity(0.18)),
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
