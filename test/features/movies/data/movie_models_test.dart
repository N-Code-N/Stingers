import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/features/movies/data/movie_models.dart';

void main() {
  group('Movie.fromJson', () {
    test('parses a complete TMDb object', () {
      final movie = Movie.fromJson({
        'id': 693134,
        'title': 'Dune: Part Two',
        'original_title': 'Dune: Part Two',
        'poster_path': '/abc.jpg',
        'release_date': '2024-02-27',
        'overview': 'Paul Atreides unites with the Fremen.',
      });

      expect(movie.tmdbId, 693134);
      expect(movie.title, 'Dune: Part Two');
      expect(movie.posterPath, '/abc.jpg');
      expect(movie.releaseDate, DateTime(2024, 2, 27));
      expect(movie.releaseYear, 2024);
    });

    test('accepts a null poster_path', () {
      final movie = Movie.fromJson({'id': 1, 'title': 'A', 'poster_path': null});
      expect(movie.posterPath, isNull);
    });

    test('treats an empty poster_path as absent', () {
      final movie = Movie.fromJson({'id': 1, 'title': 'A', 'poster_path': ''});
      expect(movie.posterPath, isNull);
    });

    test('accepts a missing release_date', () {
      final movie = Movie.fromJson({'id': 1, 'title': 'A'});
      expect(movie.releaseDate, isNull);
      expect(movie.releaseYear, isNull);
    });

    test('treats an empty release_date as absent — TMDb sends "" for unscheduled', () {
      final movie = Movie.fromJson({'id': 1, 'title': 'A', 'release_date': ''});
      expect(movie.releaseDate, isNull);
    });

    test('keeps a non-ASCII title intact', () {
      final movie = Movie.fromJson({'id': 1, 'title': 'Приключения Электроника'});
      expect(movie.title, 'Приключения Электроника');
    });

    test('falls back to original_title when the localised title is absent', () {
      final movie = Movie.fromJson({'id': 1, 'original_title': 'Le Samouraï'});
      expect(movie.title, 'Le Samouraï');
    });

    test('reads an id that decoded as a double', () {
      // JSON numbers decode as whichever of int/double fits; `as int` would throw.
      final movie = Movie.fromJson({'id': 693134.0, 'title': 'A'});
      expect(movie.tmdbId, 693134);
    });

    test('does not shift a release date into the previous day', () {
      // A calendar day, not an instant. `toLocal()` here would move a release west
      // of UTC back by one day.
      final movie = Movie.fromJson({'id': 1, 'title': 'A', 'release_date': '2024-02-27'});
      expect(movie.releaseDate!.day, 27);
    });
  });

  group('MoviesPage.fromJson', () {
    test('parses results and paging', () {
      final page = MoviesPage.fromJson({
        'page': 2,
        'total_pages': 5,
        'results': [
          {'id': 1, 'title': 'A'},
          {'id': 2, 'title': 'B'},
        ],
      });

      expect(page.movies.map((m) => m.tmdbId), [1, 2]);
      expect(page.page, 2);
      expect(page.hasMore, isTrue);
    });

    test('has no more pages on the last one', () {
      final page = MoviesPage.fromJson({'page': 5, 'total_pages': 5, 'results': []});
      expect(page.hasMore, isFalse);
    });

    test('survives a response with no results key', () {
      final page = MoviesPage.fromJson({'page': 1, 'total_pages': 1});
      expect(page.movies, isEmpty);
    });
  });

  group('SceneStats percentages', () {
    SceneStats stats({
      int raw = 0,
      double total = 0,
      double scene = 0,
      double worth = 0,
      double worthTotal = 0,
    }) => SceneStats(
      rawVotes: raw,
      totalWeight: total,
      sceneWeight: scene,
      worthWeight: worth,
      worthTotal: worthTotal,
    );

    test('divides by zero weight without throwing', () {
      final s = stats();
      expect(s.scenePercent, 0);
      expect(s.worthPercent, 0);
      expect(s.hasVerdict, isFalse);
    });

    test('has no verdict just below the threshold', () {
      // Relative to the constant, not to a number: the threshold is calibrated against
      // what a device is currently worth and is expected to move.
      const just = SceneStats.minWeightForVerdict - 0.01;
      expect(stats(raw: 3, total: just, scene: just).hasVerdict, isFalse);
    });

    test('has a verdict exactly at the threshold', () {
      const at = SceneStats.minWeightForVerdict;
      expect(stats(raw: 3, total: at, scene: at).hasVerdict, isTrue);
    });

    test('three ordinary voters are a verdict; one is not', () {
      // The calibration that matters in the product. Attestation is unimplemented, so
      // every real device weighs 0.3 — if the threshold does not agree with that, every
      // film reads "unknown" no matter how many people have answered.
      const ordinary = 0.3;
      expect(stats(raw: 1, total: ordinary, scene: ordinary).hasVerdict, isFalse);
      expect(stats(raw: 2, total: ordinary * 2, scene: ordinary * 2).hasVerdict, isFalse);
      expect(stats(raw: 3, total: ordinary * 3, scene: ordinary * 3).hasVerdict, isTrue);
    });

    test('one trusted device is a verdict on its own', () {
      // A device whose trust has been locked to 1 exists so a film can be answered
      // before there is a crowd. That only works if 1 clears the threshold.
      expect(stats(raw: 1, total: 1, scene: 1).hasVerdict, isTrue);
    });

    test('a farm of weightless votes produces no verdict', () {
      // Ten rows, zero weight: raw_votes is high and total_weight is not. This is the
      // whole point of aggregating weights instead of counting rows.
      final s = stats(raw: 10, total: 0, scene: 0);
      expect(s.rawVotes, 10);
      expect(s.hasVerdict, isFalse);
    });

    test('reports the share backing the verdict, not always the yes share', () {
      final s = stats(raw: 14, total: 14, scene: 2);
      expect(s.hasScene, isFalse);
      expect(s.scenePercent, 14);
      expect(s.verdictPercent, 86); // "86% say: no scene"
    });

    test('rounds the yes share as expected', () {
      final s = stats(raw: 14, total: 14, scene: 12);
      expect(s.hasScene, isTrue);
      expect(s.verdictPercent, 86);
    });

    test('an exact split is not a verdict of yes', () {
      final s = stats(raw: 4, total: 4, scene: 2);
      expect(s.hasScene, isFalse);
    });

    test('worth-it needs its own threshold, counted only among those who saw it', () {
      const below = SceneStats.minWeightForVerdict - 0.01;
      final withFew = stats(
        raw: 10,
        total: 10,
        scene: 10,
        worth: below,
        worthTotal: below,
      );
      expect(withFew.hasWorthVerdict, isFalse);

      final withEnough = stats(raw: 10, total: 10, scene: 10, worth: 5, worthTotal: 8);
      expect(withEnough.hasWorthVerdict, isTrue);
      expect(withEnough.worthIt, isTrue);
      expect(withEnough.worthVerdictPercent, 63);
    });

    test('there is no worth-it verdict when there is no scene', () {
      final s = stats(raw: 10, total: 10, scene: 1, worth: 5, worthTotal: 8);
      expect(s.hasScene, isFalse);
      expect(s.hasWorthVerdict, isFalse);
    });
  });

  group('SceneStats.withOwnVote', () {
    test('a single vote does not manufacture a verdict the server will not back', () {
      // The server weights an unattested vote from a fresh device at 0.3 x 0.4 = 0.12
      // (supabase/functions/_shared/trust.ts). Folding it in at a weight the server would
      // never grant is what made the card read "there is a scene, 100%" on the tap and
      // "not enough votes yet" the next time it was opened.
      final next = SceneStats.empty.withOwnVote(
        previous: null,
        hasScene: true,
        worthIt: true,
      );

      expect(next.hasVerdict, isFalse);
      expect(next.hasWorthVerdict, isFalse);
      expect(next.rawVotes, 1);
    });

    final base = SceneStats(
      rawVotes: 9,
      totalWeight: 9,
      sceneWeight: 6,
      worthWeight: 3,
      worthTotal: 6,
    );

    test('a first vote adds one row and one unit of weight', () {
      final next = base.withOwnVote(
        previous: null,
        hasScene: true,
        worthIt: null,
        weight: 1,
      );
      expect(next.rawVotes, 10);
      expect(next.totalWeight, 10);
      expect(next.sceneWeight, 7);
      expect(next.worthTotal, 6); // the second question is unanswered
    });

    test('changing an existing vote moves weight instead of adding it', () {
      final previous = MyVote(
        tmdbId: 1,
        hasScene: true,
        worthIt: true,
        updatedAt: DateTime(2026),
      );
      final next = base.withOwnVote(
        previous: previous,
        hasScene: false,
        worthIt: null,
        weight: 1,
      );

      expect(next.rawVotes, 9, reason: 'the row already existed');
      expect(next.totalWeight, 9);
      expect(next.sceneWeight, 5);
      expect(next.worthWeight, 2);
      expect(next.worthTotal, 5);
    });

    test('never produces a negative weight from a stale aggregate', () {
      final previous = MyVote(
        tmdbId: 1,
        hasScene: true,
        worthIt: true,
        updatedAt: DateTime(2026),
      );
      final next = SceneStats.empty.withOwnVote(
        previous: previous,
        hasScene: true,
        worthIt: true,
      );
      expect(next.sceneWeight, greaterThanOrEqualTo(0));
      expect(next.worthWeight, greaterThanOrEqualTo(0));
    });
  });
}
