import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';

/// "Data from 14:32", shown when what is on screen came from the local database and the
/// refresh behind it did not land.
///
/// This is the whole offline story in one widget: the app does not show an error screen
/// for a missing connection, it shows the content it has and says how old it is.
class StaleBanner extends StatelessWidget {
  const StaleBanner({super.key, required this.fetchedAt});

  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final sameDay =
        fetchedAt.year == now.year &&
        fetchedAt.month == now.month &&
        fetchedAt.day == now.day;
    final formatted = sameDay
        ? DateFormat.Hm(locale).format(fetchedAt)
        : DateFormat.yMMMd(locale).add_Hm().format(fetchedAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surface,
      child: Text(
        context.l10n.feedStale(formatted),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
