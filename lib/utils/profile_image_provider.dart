import 'package:flutter/material.dart';

import 'profile_image_provider_stub.dart'
    if (dart.library.io) 'profile_image_provider_io.dart';

ImageProvider<Object>? profileImageProvider(String? imagePath) {
  final trimmedPath = imagePath?.trim() ?? '';
  if (trimmedPath.isEmpty || trimmedPath.toLowerCase().contains('.svg')) {
    return null;
  }
  if (trimmedPath.startsWith('assets/')) {
    return AssetImage(trimmedPath);
  }
  if (trimmedPath.startsWith('http://') || trimmedPath.startsWith('https://')) {
    return NetworkImage(trimmedPath);
  }

  return localProfileImageProvider(trimmedPath);
}
