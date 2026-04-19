import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/models/doctor_model.dart';
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
  UserModel? _user;
  bool _isEditing = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _user = _authService.currentUser;

    if (_user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      });
    }

    _firstNameController = TextEditingController(text: _user?.firstName ?? '');
    _lastNameController = TextEditingController(text: _user?.lastName ?? '');
    _phoneController = TextEditingController(text: _user?.phone ?? '');
    _bioController = TextEditingController(text: _user?.bio ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = _user;
    if (user == null) {
      return;
    }

    final updatedUser = user.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      bio: _bioController.text.trim(),
    );

    await _authService.updateCurrentUser(updatedUser);

    if (!mounted) {
      return;
    }

    setState(() {
      _user = updatedUser;
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
    final user = _user;
    if (user == null) {
      return Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: kOrangeColor),
        ),
      );
    }

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
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(user),
            SizedBox(height: 18),
            if (_isEditing)
              _buildEditSection(user)
            else
              _buildProfileSections(user),
            SizedBox(height: 24),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(UserModel user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundImage: _profileImageProvider(user.profileImage),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTitleTextColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: kTitleTextColor.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kBlueColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Patient account',
                    style: TextStyle(
                      color: kWhiteColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection(UserModel user) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('First Name'),
          SizedBox(height: 10),
          _buildEditTextField(_firstNameController),
          SizedBox(height: 18),
          _buildLabel('Last Name'),
          SizedBox(height: 10),
          _buildEditTextField(_lastNameController),
          SizedBox(height: 18),
          _buildLabel('Email Address'),
          SizedBox(height: 10),
          _buildReadonlyField(user.email),
          SizedBox(height: 18),
          _buildLabel('Phone Number'),
          SizedBox(height: 10),
          _buildEditTextField(_phoneController),
          SizedBox(height: 18),
          _buildLabel('Bio'),
          SizedBox(height: 10),
          _buildEditTextField(_bioController, maxLines: 4),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: MaterialButton(
              onPressed: _saveProfile,
              color: kBlueColor,
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
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _firstNameController.text = user.firstName;
                  _lastNameController.text = user.lastName;
                  _phoneController.text = user.phone;
                  _bioController.text = user.bio;
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
        ],
      ),
    );
  }

  Widget _buildProfileSections(UserModel user) {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Account Information',
          children: [
            _buildProfileInfoCard(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user.phone.isEmpty ? 'Add your phone number' : user.phone,
            ),
            SizedBox(height: 12),
            _buildProfileInfoCard(
              icon: Icons.info_outline,
              label: 'Bio',
              value: user.bio.isEmpty
                  ? 'Add a short profile note for your doctors.'
                  : user.bio,
            ),
            SizedBox(height: 12),
            _buildProfileInfoCard(
              icon: Icons.event_available_outlined,
              label: 'Member Since',
              value: _formatDate(user.createdAt),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 14),
          _buildActionTile(
            icon: Icons.calendar_month_outlined,
            title: 'My Appointments',
            subtitle: 'Review upcoming and completed visits',
            onTap: () => Get.toNamed('/appointments'),
          ),
          _buildActionTile(
            icon: Icons.folder_outlined,
            title: 'Health Records',
            subtitle: 'Keep visit notes and reports accessible',
            onTap: () => Get.toNamed('/health-records'),
          ),
          _buildActionTile(
            icon: Icons.medication_outlined,
            title: 'Prescriptions',
            subtitle: 'Track active medication instructions',
            onTap: () => Get.toNamed('/prescriptions'),
          ),
          _buildActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Review reminders and updates',
            onTap: () => Get.toNamed('/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kWhiteColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: kTitleTextColor,
            ),
          ),
          SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kBlueColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kWhiteColor),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTitleTextColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: kTitleTextColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
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

  Widget _buildReadonlyField(String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: kSearchBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: kTitleTextColor,
        ),
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
        color: kBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: kBlueColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: kWhiteColor, size: 24),
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
    return '${months[date.month - 1]} ${date.year}';
  }

  ImageProvider<Object> _profileImageProvider(String imagePath) {
    if (imagePath.trim().isEmpty) {
      return const AssetImage(DoctorModel.fallbackImagePath);
    }
    if (imagePath.startsWith('assets/')) {
      return AssetImage(imagePath);
    }
    return NetworkImage(imagePath);
  }
}
