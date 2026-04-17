import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _errorMessage;

  final _authService = AuthService();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signup() async {
    // Validate
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success = await _authService.signup(
        _emailController.text.trim(),
        _firstNameController.text.trim(),
        _lastNameController.text.trim(),
        _phoneController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        Get.offNamed('/home');
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
      body: SafeArea(
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
                ),
                SizedBox(height: 10),
                Text(
                  'Join us today and get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTitleTextColor.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 30),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Color(0xffFF6B6B).withOpacity(0.1),
                      border: Border.all(color: Color(0xffFF6B6B), width: 1),
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
                              valueColor: AlwaysStoppedAnimation(kWhiteColor),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Create Account',
                            style: TextStyle(
                              color: kWhiteColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
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
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
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
        fillColor: kSearchBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
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
        fillColor: kSearchBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
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
