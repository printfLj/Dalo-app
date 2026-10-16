import 'package:flutter/material.dart';

/// Daló's shared wordmark for the loading and sign-in screens.
class DaloBrandMark extends StatelessWidget {
  final double width;

  const DaloBrandMark({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/dalo_logo.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'Daló',
    );
  }
}
