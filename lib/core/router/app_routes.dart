/// Route names and paths, kept apart from the router itself so a screen can navigate
/// without importing the whole dependency graph.
///
/// There is no auth guard here and there should not be one: the app has no login
/// screen, so there is nothing to protect a route from.
abstract final class AppRoute {
  static const String feed = 'feed';
  static const String search = 'search';
  static const String myVotes = 'myVotes';
  static const String movie = 'movie';
  static const String settings = 'settings';
}

abstract final class AppPath {
  static const String feed = '/';
  static const String search = '/search';
  static const String myVotes = '/my-votes';
  static const String movie = '/movie/:tmdbId';
  static const String settings = '/settings';
}
