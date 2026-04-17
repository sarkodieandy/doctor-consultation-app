import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/models/user_model.dart';
import 'package:doctor_consultation_app/screens/login_screen.dart';
import 'package:doctor_consultation_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  late UserModel _user;
  bool _isEditing = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _user = _authService.currentUser!;
    _firstNameController = TextEditingController(text: _user.firstName);
    _lastNameController = TextEditingController(text: _user.lastName);
    _phoneController = TextEditingController(text: _user.phone);
    _bioController = TextEditingController(text: _user.bio);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    // Update user in service
    _user = _user.copyWith(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      bio: _bioController.text,
    );

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: kBlueColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: kTitleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        leading: InkWell(
          onTap: () => Get.back(),
          child: Icon(Icons.arrow_back, color: kTitleTextColor),
        ),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Text(
                'Edit',
                style: TextStyle(
                  color: kBlueColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: kBlueColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kBlueColor,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: kBlueColor,
                  ),
                ),
              ),
              SizedBox(height: 20),

              if (_isEditing) ...[
                // First Name
                _buildLabel('First Name'),
                SizedBox(height: 10),
                _buildEditTextField(_firstNameController),
                SizedBox(height: 20),

                // Last Name
                _buildLabel('Last Name'),
                SizedBox(height: 10),
                _buildEditTextField(_lastNameController),
                SizedBox(height: 20),

                // Email (Read-only)
                _buildLabel('Email Address'),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: kSearchBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: kTitleTextColor,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(height: 20),

                // Phone
                _buildLabel('Phone Number'),
                SizedBox(height: 10),
                _buildEditTextField(_phoneController),
                SizedBox(height: 20),

                // Bio
                _buildLabel('Bio'),
                SizedBox(height: 10),
                _buildEditTextField(_bioController, maxLines: 4),
                SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: MaterialButton(
                    onPressed: _saveProfile,
                    color: kOrangeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(
                        color: kWhiteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: BorderSide(color: kTitleTextColor, width: 1),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: kTitleTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Display Mode
                Text(
                  _user.fullName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  _user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: kTitleTextColor.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 30),

                // Profile Info Cards
                _buildProfileInfoCard(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: _user.phone,
                ),
                SizedBox(height: 15),

                _buildProfileInfoCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Member Since',
                  value: _formatDate(_user.createdAt),
                ),
                SizedBox(height: 15),

                if (_user.bio.isNotEmpty)
                  _buildProfileInfoCard(
                    icon: Icons.info_outlined,
                    label: 'Bio',
                    value: _user.bio,
                  ),
              ],

              SizedBox(height: 40),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: MaterialButton(
                  onPressed: () {
                    _showLogoutConfirmation();
                  },
                  color: Color(0xffFF6B6B).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Color(0xffFF6B6B)),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xffFF6B6B),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildEditTextField(
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        filled: true,
        fillColor: kSearchBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  Widget _buildProfileInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: kBlueColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: kBlueColor, size: 24),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: kTitleTextColor.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: kTitleTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: kTitleTextColor)),
          ),
          TextButton(
            onPressed: () {
              _authService.logout();
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text('Logout', style: TextStyle(color: Color(0xffFF6B6B))),
          ),
        ],
      ),
    );
  }
}
