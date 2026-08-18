import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_locale_controller.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/cinema_mode.dart';

/// Settings, and the doors that are not worth a permanent place on screen.
///
/// Cinema mode lives here and only here. It used to be a button on every film, which
/// asked the question in the wrong place: it is not a property of a film, it is how the
/// whole app should behave for the next two hours, and being asked once per film is
/// being asked once too often.
///
/// The TMDb line is not optional: their terms require the acknowledgement wherever their
/// data is used, and this app's entire film catalogue is theirs.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.cinemaMode, required this.locale});

  final CinemaMode cinemaMode;
  final AppLocaleController locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final languageMenuKey = GlobalKey<PopupMenuButtonState<Locale?>>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListenableBuilder(
                    listenable: cinemaMode,
                    builder: (context, _) => SwitchListTile(
                      secondary: Icon(
                        cinemaMode.enabled
                            ? Icons.nightlight_round
                            : Icons.nightlight_outlined,
                      ),
                      title: Text(l10n.settingsCinemaMode),
                      subtitle: Text(l10n.settingsCinemaModeHint),
                      value: cinemaMode.enabled,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        cinemaMode.setEnabled(value);
                      },
                    ),
                  ),
                  const Divider(),
                  ListenableBuilder(
                    listenable: locale,
                    builder: (context, _) => SizedBox(
                      width: double.infinity,
                      child: PopupMenuButton<Locale?>(
                        key: languageMenuKey,
                        padding: EdgeInsets.zero,
                        initialValue: locale.locale,
                        position: PopupMenuPosition.under,
                        onSelected: locale.setLocale,
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.sizeOf(context).width,
                          maxWidth: MediaQuery.sizeOf(context).width,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem<Locale>(
                            value: const Locale('en'),
                            child: Text(l10n.settingsLanguageEnglish),
                          ),
                          PopupMenuItem<Locale>(
                            value: const Locale('ru'),
                            child: Text(l10n.settingsLanguageRussian),
                          ),
                        ],
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          leading: const Icon(Icons.language),
                          title: Text(l10n.settingsLanguage),
                          subtitle: Text(
                            locale.locale == null
                                ? l10n.settingsLanguageSystem
                                : locale.locale?.languageCode == 'ru'
                                ? l10n.settingsLanguageRussian
                                : l10n.settingsLanguageEnglish,
                          ),
                          trailing: const Icon(Icons.arrow_drop_down),
                          onTap: () => languageMenuKey.currentState?.showButtonMenu(),
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.how_to_vote_outlined),
                    title: Text(l10n.settingsMyVotes),
                    subtitle: Text(l10n.settingsMyVotesHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.pushNamed(AppRoute.myVotes),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              l10n.aboutTmdbAttribution,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
