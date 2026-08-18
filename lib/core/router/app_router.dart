import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/view/settings_screen.dart';
import '../../features/movies/view/movie_details_screen.dart';
import '../../features/movies/view/my_votes_screen.dart';
import '../../features/movies/view/now_playing_screen.dart';
import '../../features/movies/view/search_screen.dart';
import '../di/app_dependencies.dart';
import '../l10n/l10n.dart';
import '../widgets/error_view.dart';
import 'app_routes.dart';

/// The one route table.
///
/// Flat: the feed is the app, and everything else is pushed on top of it. There was a
/// tab bar here; it cost a third of the bottom of the screen to advertise two things the
/// feed can reach with one tap — search from the button that floats over it, the vote
/// history from the info screen.
///
/// Every builder closes over [AppDependencies], so screens stay constructor-injected and
/// nothing reaches for a global to find its repository. There is no `redirect` guard:
/// with no login screen there is nothing to guard against.
GoRouter createAppRouter({required AppDependencies deps}) => GoRouter(
  initialLocation: AppPath.feed,
  routes: [
    GoRoute(
      path: AppPath.feed,
      name: AppRoute.feed,
      builder: (context, state) =>
          NowPlayingScreen(repository: deps.movieRepository, locale: deps.locale),
      routes: [
        GoRoute(
          path: AppPath.search,
          name: AppRoute.search,
          builder: (context, state) =>
              SearchScreen(repository: deps.movieRepository, locale: deps.locale),
        ),
        GoRoute(
          path: AppPath.myVotes,
          name: AppRoute.myVotes,
          builder: (context, state) => MyVotesScreen(repository: deps.movieRepository),
        ),
        GoRoute(
          path: AppPath.settings,
          name: AppRoute.settings,
          builder: (context, state) =>
              SettingsScreen(cinemaMode: deps.cinemaMode, locale: deps.locale),
        ),
        GoRoute(
          path: AppPath.movie,
          name: AppRoute.movie,
          builder: (context, state) {
            // Path parameters are strings, and a deep link can carry anything at all.
            final tmdbId = int.tryParse(state.pathParameters['tmdbId'] ?? '');
            if (tmdbId == null) return const _RouteNotFound();
            return MovieDetailsScreen(
              key: ValueKey('movie-details-$tmdbId-${deps.locale.generation}'),
              tmdbId: tmdbId,
              repository: deps.movieRepository,
              locale: deps.locale,
            );
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => const _RouteNotFound(),
);

class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: ErrorView(message: context.l10n.errorNotFound),
  );
}
