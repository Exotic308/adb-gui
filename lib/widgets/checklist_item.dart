import 'package:flutter/material.dart';

/// Checklist item widget showing progress state
class ChecklistItem extends StatelessWidget {
  final String title;
  final bool isCompleted;
  final bool isCurrent;

  const ChecklistItem({
    super.key,
    required this.title,
    required this.isCompleted,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(context),
          const SizedBox(width: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    if (isCompleted) {
      return Icon(
        Icons.check_circle,
        color: Theme.of(context).colorScheme.primary,
        size: 24,
      );
    } else if (isCurrent) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      return Icon(
        Icons.radio_button_unchecked,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        size: 24,
      );
    }
  }
}

