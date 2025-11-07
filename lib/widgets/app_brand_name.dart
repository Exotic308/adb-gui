import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// App brand name with stylized text
class AppBrandName extends StatelessWidget {
  const AppBrandName({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppConstants.appTitle,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
    );
  }
}

