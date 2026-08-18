import 'package:flutter/material.dart';

/// Deliberately distinct from [ErrorView]: an empty result must never read as a broken
/// app. No retry button, no alarm — a title and, when there is something useful to say,
/// one line telling the user what would fill it.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
