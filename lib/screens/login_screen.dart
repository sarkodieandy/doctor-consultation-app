import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        // Brief delay so user sees the spinner
        await Future.delayed(Duration(milliseconds: 500));
        final user = _authService.currentUser;
        if (user != null && user.isDoctor) {
          // TODO: Restore approval check after testing
          // if (user.isDoctorApproved) {
          Get.offNamed('/doctor-home');
          // } else {
          //   Get.offNamed('/pending-approval');
          // }
        } else {
          Get.offNamed('/home');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
          // Full-screen watermark
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
          // Smaller inner blue circle — top left
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
                color: kBlueColor.withOpacity(0.15),
              ),
            ),
          ),
          // Smaller inner orange circle — bottom right
          Positioned(
            bottom: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kBlueColor.withOpacity(0.10),
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
                    SizedBox(height: 40),
                    // Header
                    Text(
                      'Welcome Back',
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
                      'Login to your account to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: kTitleTextColor.withOpacity(0.6),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: -0.2, end: 0),
                    SizedBox(height: 40),

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
                      ).animate().fadeIn(duration: 300.ms).shake(),

                    // Email / Username Field
                    Text(
                      'Email or Username',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: kTitleTextColor,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideX(begin: -0.2, end: 0),
                    SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Enter your email or username',
                        hintStyle: TextStyle(color: kSearchTextColor),
                        filled: true,
                        fillColor: Color(0xffEEF2FF),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              BorderSide(color: Color(0xffD0D7F5), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: kBlueColor, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              BorderSide(color: Color(0xffD0D7F5), width: 1.5),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 16, right: 12),
                          child: Icon(
                            Icons.email_outlined,
                            color: kBlueColor,
                            size: 20,
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(minWidth: 0),
                      ),
                      enabled: !_isLoading,
                    )
                        .animate()
                        .fadeIn(delay: 250.ms, duration: 500.ms)
                        .slideX(begin: -0.2, end: 0),
                    SizedBox(height: 20),

                    // Password Field
                    Text(
                      'Password',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: kTitleTextColor,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 350.ms, duration: 500.ms)
                        .slideX(begin: -0.2, end: 0),
                    SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(color: kSearchTextColor),
                        filled: true,
                        fillColor: Color(0xffEEF2FF),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              BorderSide(color: Color(0xffD0D7F5), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: kBlueColor, width: 2),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide:
                              BorderSide(color: Color(0xffD0D7F5), width: 1.5),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: kTitleTextColor.withOpacity(0.5),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      enabled: !_isLoading,
                    )
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 500.ms)
                        .slideX(begin: -0.2, end: 0),
                    SizedBox(height: 12),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                // TODO: Navigate to forgot password screen
                              },
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: kBlueColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
                    SizedBox(height: 30),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: MaterialButton(
                        onPressed: _isLoading ? null : _login,
                        color: kBlueColor,
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
                                'Login',
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

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: kTitleTextColor.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(
                              fontSize: 12,
                              color: kTitleTextColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: kTitleTextColor.withOpacity(0.2),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 580.ms, duration: 400.ms),
                    SizedBox(height: 20),

                    // Social Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIconButton(
                          icon: FontAwesomeIcons.google,
                          color: const Color(0xFFDB4437),
                          bgColor: const Color(0xFFFCE8E6),
                          borderColor: const Color(0xFFF5C6C2),
                        ),
                        SizedBox(width: 20),
                        _buildSocialIconButton(
                          icon: FontAwesomeIcons.facebook,
                          color: const Color(0xFF1877F2),
                          bgColor: const Color(0xFFE7F0FD),
                          borderColor: const Color(0xFFBDD3F8),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 650.ms, duration: 400.ms)
                        .slideY(begin: 0.3, end: 0),
                    SizedBox(height: 20),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: kTitleTextColor.withOpacity(0.6),
                          ),
                        ),
                        InkWell(
                          onTap: _isLoading
                              ? null
                              : () {
                                  Get.toNamed('/signup');
                                },
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              fontSize: 14,
                              color: kBlueColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 720.ms, duration: 400.ms),
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

  Widget _buildSocialIconButton({
    required FaIconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: FaIcon(
          icon,
          size: 26,
          color: color,
        ),
      ),
    );
  }
}
