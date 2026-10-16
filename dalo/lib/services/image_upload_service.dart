import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Firestore documents are limited to 1 MiB. Keep photos small enough to leave
/// room for the rest of each event/profile record; this is a Spark-friendly
/// prototype strategy, not a replacement for object storage at scale.
class ImageUploadService {
  static const maxBase64Characters = 280000;
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickPhoto({required bool profilePhoto}) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: profilePhoto ? 640 : 1280,
      maxHeight: profilePhoto ? 640 : 1280,
      imageQuality: 65,
    );
    if (image == null) return null;

    final encoded = base64Encode(await image.readAsBytes());
    if (encoded.length > maxBase64Characters) {
      throw const ImageUploadTooLargeException();
    }
    return encoded;
  }
}

class ImageUploadTooLargeException implements Exception {
  const ImageUploadTooLargeException();

  @override
  String toString() =>
      'This image is still too large after compression. Please choose a smaller photo.';
}
