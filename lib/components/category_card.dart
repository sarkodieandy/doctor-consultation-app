import 'package:doctor_consultation_app/constant.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String _title;
  final String _imageUrl;
  final Color _bgColor;
  final bool isSelected;
  final VoidCallback? onTap;

  CategoryCard(this._title, this._imageUrl, this._bgColor,
      {this.isSelected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 156,
        decoration: BoxDecoration(
          color: kWhiteColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? kBlueColor.withOpacity(0.35)
                : kTitleTextColor.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Stack(
                children: [
                  _buildImage(),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? kBlueColor : _bgColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      isSelected ? 'Selected' : 'Specialty',
                      style: TextStyle(
                        color: kWhiteColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _title,
                    style: TextStyle(
                      color: kTitleTextColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (_imageUrl.startsWith('http://') || _imageUrl.startsWith('https://')) {
      return _buildFallbackImage();
    }

    return Container(
      width: double.infinity,
      height: 104,
      color: _bgColor.withOpacity(0.12),
      child: Image.asset(
        _imageUrl,
        width: double.infinity,
        height: 104,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: double.infinity,
      height: 104,
      color: _bgColor.withOpacity(0.12),
      alignment: Alignment.center,
      child: Icon(Icons.medical_services_outlined, color: _bgColor, size: 28),
    );
  }
}
