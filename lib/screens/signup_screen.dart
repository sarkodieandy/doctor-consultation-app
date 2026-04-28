import 'dart:typed_data';
import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Doctor-specific controllers
  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _consultationFeeController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _errorMessage;
  bool _isDoctor = false;
  PlatformFile? _licenseDocumentFile;
  XFile? _profilePictureFile;
  Uint8List? _profilePictureBytes;

  final _authService = AuthService();
  final _imagePicker = ImagePicker();

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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specialtyController.dispose();
    _experienceController.dispose();
    _consultationFeeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        setState(() {
          _licenseDocumentFile = result.files.single;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Document selected: ${result.files.single.name}',
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: kBlueColor,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick document. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickProfilePicture() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxHeight: 512,
        maxWidth: 512,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _profilePictureFile = pickedFile;
          _profilePictureBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture selected'),
            backgroundColor: kBlueColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  void _signup() async {
    // Validate common fields
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the Terms & Conditions';
      });
      return;
    }

    // Validate doctor-specific fields
    if (_isDoctor) {
      if (_specialtyController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please select your specialty';
        });
        return;
      }
      if (_experienceController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your years of experience';
        });
        return;
      }
      if (_consultationFeeController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your consultation fee';
        });
        return;
      }
      if (_licenseDocumentFile == null) {
        setState(() {
          _errorMessage = 'Please upload your medical license document';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success;

      if (_isDoctor) {
        success = await _authService.signupDoctor(
          email: _emailController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          specialty: _specialtyController.text.trim(),
          experience: _experienceController.text.trim(),
          consultationFee:
              double.tryParse(_consultationFeeController.text.trim()) ?? 0.0,
          licenseDocumentPath:
              _licenseDocumentFile?.path ?? _licenseDocumentFile?.name ?? '',
          licenseDocumentFile: _licenseDocumentFile,
          bio: _bioController.text.trim(),
          profilePictureFile: _profilePictureFile,
        );

        if (success) {
          Get.offNamed('/pending-approval');
        }
      } else {
        success = await _authService.signup(
          _emailController.text.trim(),
          _firstNameController.text.trim(),
          _lastNameController.text.trim(),
          _phoneController.text.trim(),
          _passwordController.text,
          profilePictureFile: _profilePictureFile,
        );

        if (success) {
          Get.offNamed('/home');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: Image.asset(
                'assets/images/doctorbg.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Blue decorative circle — top left
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBlueColor.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBlueColor.withOpacity(0.10),
              ),
            ),
          ),
          // Orange decorative circle — bottom right
          Positioned(
            bottom: -70,
            right: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOrangeColor.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kOrangeColor.withOpacity(0.10),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 30),
                    // Header
                    Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        color: kTitleTextColor,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: -0.3, end: 0),
                    SizedBox(height: 10),
                    Text(
                      _isDoctor
                          ? 'Register as a doctor to start consultations'
                          : 'Join us today and get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: kTitleTextColor.withOpacity(0.6),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: -0.2, end: 0),
                    SizedBox(height: 24),

                    // Role Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: kSearchBackgroundColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => setState(() => _isDoctor = false),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: !_isDoctor
                                      ? kOrangeColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outlined,
                                      color: !_isDoctor
                                          ? kWhiteColor
                                          : kTitleTextColor,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Patient',
                                      style: TextStyle(
                                        color: !_isDoctor
                                            ? kWhiteColor
                                            : kTitleTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () => setState(() => _isDoctor = true),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _isDoctor
                                      ? kOrangeColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.medical_services_outlined,
                                      color: _isDoctor
                                          ? kWhiteColor
                                          : kTitleTextColor,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Doctor',
                                      style: TextStyle(
                                        color: _isDoctor
                                            ? kWhiteColor
                                            : kTitleTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .scaleXY(begin: 0.95, end: 1.0),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Color(0xffFF6B6B).withOpacity(0.1),
                          border:
                              Border.all(color: Color(0xffFF6B6B), width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Color(0xffFF6B6B),
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // First Name
                    _buildLabel('First Name'),
                    SizedBox(height: 10),
                    _buildTextField(
                      _firstNameController,
                      'Enter your first name',
                      Icons.person_outlined,
                    ),
                    SizedBox(height: 16),

                    // Last Name
                    _buildLabel('Last Name'),
                    SizedBox(height: 10),
                    _buildTextField(
                      _lastNameController,
                      'Enter your last name',
                      Icons.person_outlined,
                    ),
                    SizedBox(height: 16),

                    // Profile Picture
                    _buildLabel('Profile Picture'),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: _isLoading ? null : _pickProfilePicture,
                      child: Container(
                        decoration: BoxDecoration(
                          color: kSearchBackgroundColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _profilePictureFile != null
                                ? kOrangeColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        padding: EdgeInsets.all(20),
                        child: _profilePictureFile != null
                            ? Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: _profilePictureBytes != null
                                          ? DecorationImage(
                                              image: MemoryImage(
                                                  _profilePictureBytes!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Profile picture selected',
                                          style: TextStyle(
                                            color: kTitleTextColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          _profilePictureFile!.path
                                              .split(RegExp(r'[\\/]+'))
                                              .last,
                                          style: TextStyle(
                                            color: kSearchTextColor,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    color: kBlueColor,
                                    size: 24,
                                  ),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Upload profile picture',
                                        style: TextStyle(
                                          color: kTitleTextColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Tap to select an image',
                                        style: TextStyle(
                                          color: kSearchTextColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Email
                    _buildLabel('Email Address'),
                    SizedBox(height: 10),
                    _buildTextField(
                      _emailController,
                      'Enter your email',
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),

                    // Phone
                    _buildLabel('Phone Number'),
                    SizedBox(height: 10),
                    _buildTextField(
                      _phoneController,
                      'Enter your phone number',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),

                    // Doctor-specific fields
                    if (_isDoctor) ...[
                      // Specialty Dropdown
                      _buildLabel('Specialty'),
                      SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: kSearchBackgroundColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _specialtyController.text.isEmpty
                              ? null
                              : _specialtyController.text,
                          hint: Text(
                            'Select your specialty',
                            style: TextStyle(color: kSearchTextColor),
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.medical_services_outlined,
                                  color: kBlueColor, size: 20),
                            ),
                            prefixIconConstraints: BoxConstraints(minWidth: 0),
                          ),
                          items: _specialties.map((specialty) {
                            return DropdownMenuItem(
                              value: specialty,
                              child: Text(specialty),
                            );
                          }).toList(),
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _specialtyController.text = value ?? '';
                                  });
                                },
                        ),
                      ),
                      SizedBox(height: 16),

                      // Experience
                      _buildLabel('Years of Experience'),
                      SizedBox(height: 10),
                      _buildTextField(
                        _experienceController,
                        'e.g. 5 years',
                        Icons.work_outlined,
                      ),
                      SizedBox(height: 16),

                      // Consultation Fee
                      _buildLabel('Consultation Fee (GHS)'),
                      SizedBox(height: 10),
                      _buildTextField(
                        _consultationFeeController,
                        'e.g. 150.00',
                        Icons.attach_money,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                      ),
                      SizedBox(height: 16),

                      // Bio
                      _buildLabel('Short Bio'),
                      SizedBox(height: 10),
                      TextField(
                        controller: _bioController,
                        maxLines: 3,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          hintText: 'Tell patients about yourself...',
                          hintStyle: TextStyle(color: kSearchTextColor),
                          filled: true,
                          fillColor: Color(0xffEEF2FF),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color: Color(0xffD0D7F5), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: kBlueColor, width: 2),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                                color: Color(0xffD0D7F5), width: 1.5),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                        ),
                      ),
                      SizedBox(height: 16),

                      // License Upload
                      _buildLabel('Medical License Document'),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: _isLoading ? null : _pickLicenseDocument,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              vertical: 24, horizontal: 20),
                          decoration: BoxDecoration(
                            color: kSearchBackgroundColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _licenseDocumentFile != null
                                  ? kBlueColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _licenseDocumentFile != null
                                    ? Icons.check_circle
                                    : Icons.cloud_upload_outlined,
                                color: _licenseDocumentFile != null
                                    ? kBlueColor
                                    : kSearchTextColor,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                _licenseDocumentFile != null
                                    ? _licenseDocumentFile!.name
                                    : 'Tap to upload license (PDF/Image)',
                                style: TextStyle(
                                  color: _licenseDocumentFile != null
                                      ? kBlueColor
                                      : kSearchTextColor,
                                  fontSize: 13,
                                  fontWeight: _licenseDocumentFile != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              if (_licenseDocumentFile != null) ...[
                                SizedBox(height: 4),
                                Text(
                                  'Tap to change',
                                  style: TextStyle(
                                    color: kBlueColor.withOpacity(0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Info notice
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kBlueColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: kBlueColor, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your account will be reviewed by admin before you can start accepting patients.',
                                style: TextStyle(
                                  color: kBlueColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Password
                    _buildLabel('Password'),
                    SizedBox(height: 10),
                    _buildPasswordField(
                      _passwordController,
                      'Enter your password',
                      _obscurePassword,
                      (value) {
                        setState(() {
                          _obscurePassword = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    // Confirm Password
                    _buildLabel('Confirm Password'),
                    SizedBox(height: 10),
                    _buildPasswordField(
                      _confirmPasswordController,
                      'Confirm your password',
                      _obscureConfirmPassword,
                      (value) {
                        setState(() {
                          _obscureConfirmPassword = value;
                        });
                      },
                    ),
                    SizedBox(height: 20),

                    // Terms & Conditions
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _agreeToTerms = value ?? false;
                                  });
                                },
                          activeColor: kOrangeColor,
                          checkColor: kWhiteColor,
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: kTitleTextColor.withOpacity(0.7),
                              ),
                              children: [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: TextStyle(
                                    color: kBlueColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: MaterialButton(
                        onPressed: _isLoading ? null : _signup,
                        color: kOrangeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation(kWhiteColor),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isDoctor
                                    ? 'Register as Doctor'
                                    : 'Create Account',
                                style: TextStyle(
                                  color: kWhiteColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 500.ms)
                        .scaleXY(begin: 0.95, end: 1.0),
                    SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: kTitleTextColor.withOpacity(0.6),
                          ),
                        ),
                        InkWell(
                          onTap: _isLoading
                              ? null
                              : () {
                                  Get.offNamed('/login');
                                },
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 14,
                              color: kOrangeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: kTitleTextColor,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kSearchTextColor),
        filled: true,
        fillColor: Color(0xffEEF2FF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xffD0D7F5), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: kBlueColor, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xffD0D7F5), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Icon(icon, color: kBlueColor, size: 20),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String hint,
    bool obscure,
    Function(bool) onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: !_isLoading,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: kSearchTextColor),
        filled: true,
        fillColor: Color(0xffEEF2FF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xffD0D7F5), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: kBlueColor, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xffD0D7F5), width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIcon: Padding(
          padding: EdgeInsets.only(left: 16, right: 12),
          child: Icon(
            Icons.lock_outlined,
            color: kBlueColor,
            size: 20,
          ),
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 0),
        suffixIcon: InkWell(
          onTap: () => onToggle(!obscure),
          child: Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: kTitleTextColor.withOpacity(0.5),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
