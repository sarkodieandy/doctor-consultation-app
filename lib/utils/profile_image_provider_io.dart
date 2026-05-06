import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider<Object>? localProfileImageProvider(String imagePath) {
  final file = File(imagePath);
  if (!file.existsSync()) {
    return null;
  }
  return FileImage(file);
}
