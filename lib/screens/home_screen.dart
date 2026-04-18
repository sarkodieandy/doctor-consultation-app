import 'package:doctor_consultation_app/components/category_card.dart';
import 'package:doctor_consultation_app/components/search_bar.dart'
    as custom_search;
import 'package:doctor_consultation_app/components/sidebar_drawer.dart';
import 'package:doctor_consultation_app/constant.dart';
import 'package:doctor_consultation_app/controllers/appointment_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AppointmentController _controller;
  bool _isSidebarOpen = false;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AppointmentController>();
    _controller.fetchDoctors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isSidebarOpen = true;
                            });
                          },
                          child: SvgPicture.asset('assets/icons/menu.svg'),
                        ),
                        InkWell(
                          onTap: () {
                            Get.toNamed('/appointments');
                          },
                          child: SvgPicture.asset('assets/icons/profile.svg'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Find Your Desired\nDoctor',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                        color: kTitleTextColor,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: custom_search.SearchBar(),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  // Quick Access Features
                  buildQuickAccessFeatures(),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Categories',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTitleTextColor,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  buildCategoryList(),
                  SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'Top Doctors',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTitleTextColor,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  buildDoctorList(),
                ],
              ),
            ),
          ),
          if (_isSidebarOpen)
            SidebarDrawer(
              onClose: () {
                setState(() {
                  _isSidebarOpen = false;
                });
              },
            ),
        ],
      ),
    );
  }

  void _onCategoryTap(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
        _controller.fetchDoctors();
      } else {
        _selectedCategory = category;
        _controller.fetchDoctorsBySpecialty(category);
      }
    });
  }

  buildCategoryList() {
    final categories = [
      {
        'title': 'Dental\nSurgeon',
        'icon': 'assets/icons/dental_surgeon.png',
        'color': kBlueColor,
        'specialty': 'Dental Surgeon'
      },
      {
        'title': 'Heart\nSurgeon',
        'icon': 'assets/icons/heart_surgeon.png',
        'color': kYellowColor,
        'specialty': 'Heart Surgeon'
      },
      {
        'title': 'Eye\nSpecialist',
        'icon': 'assets/icons/eye_specialist.png',
        'color': kOrangeColor,
        'specialty': 'Eye Specialist'
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          SizedBox(width: 30),
          ...categories.map((cat) {
            final specialty = cat['specialty'] as String;
            return Padding(
              padding: EdgeInsets.only(right: 10),
              child: CategoryCard(
                cat['title'] as String,
                cat['icon'] as String,
                cat['color'] as Color,
                isSelected: _selectedCategory == specialty,
                onTap: () => _onCategoryTap(specialty),
              ),
            );
          }),
          SizedBox(width: 20),
        ],
      ),
    );
  }

  buildQuickAccessFeatures() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kTitleTextColor,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
            children: [
              _buildFeatureCard(
                'Messages',
                Icons.chat_bubble,
                kBlueColor,
                () => Get.toNamed('/chat'),
              ),
              _buildFeatureCard(
                'Prescriptions',
                Icons.description,
                kOrangeColor,
                () => Get.toNamed('/prescriptions'),
              ),
              _buildFeatureCard(
                'Health',
                Icons.favorite,
                Colors.red,
                () => Get.toNamed('/health-records'),
              ),
              _buildFeatureCard(
                'Consultations',
                Icons.videocam,
                kYellowColor,
                () => Get.toNamed('/consultations'),
              ),
              _buildFeatureCard(
                'Reviews',
                Icons.star,
                Colors.amber,
                () => Get.toNamed('/reviews'),
              ),
              _buildFeatureCard(
                'Appointments',
                Icons.calendar_today,
                Colors.teal,
                () => Get.toNamed('/appointments'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: kTitleTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildDoctorList() {
    return Obx(
      () {
        if (_controller.isLoading.value) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: CircularProgressIndicator(color: kOrangeColor),
            ),
          );
        }

        if (_controller.doctors.isEmpty) {
          return Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: Text('No doctors found'),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: List.generate(
              _controller.doctors.length,
              (index) {
                final doctor = _controller.doctors[index];
                return Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kWhiteColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: doctor.imageProvider,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doctor.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: kTitleTextColor,
                                      ),
                                    ),
                                    Text(
                                      doctor.specialty,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: kBlueColor,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: kYellowColor, size: 12),
                                        SizedBox(width: 5),
                                        Text(
                                          '${doctor.rating} (${doctor.reviewCount})',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'GHS ${doctor.consultationFee.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kOrangeColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: MaterialButton(
                              onPressed: () {
                                Get.toNamed('/booking', arguments: doctor);
                              },
                              color: kOrangeColor,
                              height: 40,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Book Appointment',
                                style: TextStyle(
                                  color: kWhiteColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
