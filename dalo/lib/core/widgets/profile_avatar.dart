import 'dart:convert';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageBase64;
  final double radius;

  const ProfileAvatar({super.key, this.imageBase64, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        image = MemoryImage(base64Decode(imageBase64!));
      } on FormatException {
        image = null;
      }
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFFFE9E1),
      foregroundImage: image,
      child: image == null
          ? Icon(Icons.person_outline_rounded,
              size: radius, color: const Color(0xFFE86B4A))
          : null,
    );
  }
}
