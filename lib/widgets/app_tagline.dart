import 'package:flutter/material.dart';

/// App tagline/description
class AppTagline extends StatelessWidget {
  final String text;

  const AppTagline({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
    );
  }
}

