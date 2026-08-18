import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../motion/app_motion.dart';
import '../theme/app_theme.dart';

/// A poster, and the one place image loading is allowed to happen.
///
/// Two rules it exists to enforce: `cached_network_image` shows a light placeholder by
/// default, which flashes white in a dark room; and a full-resolution decode of a list
/// thumbnail is the single biggest avoidable image-memory cost in this app.
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    required this.path,
    required this.width,
    required this.height,
    this.size = AppConfig.posterListSize,
    this.borderRadius = 10,
  });

  final String? path;
  final double width;
  final double height;
  final String size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extras = CinemaExtras.of(context);
    final url = AppConfig.posterUrl(path, size: size);
    // A poster brightening into view is exactly the motion to avoid in the dark, so this
    // obeys the same rule as every other animation in the app.
    final fadeIn = AppMotion.duration(context, const Duration(milliseconds: 160));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              _PosterFallback(colors: colors)
            else
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                // Decode at display size, not at TMDb's.
                memCacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
                fadeInDuration: fadeIn,
                placeholder: (context, _) => ColoredBox(color: colors.surface),
                errorWidget: (context, _, _) => _PosterFallback(colors: colors),
              ),
            if (extras.posterVeil > 0)
              IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: extras.posterVeil),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: colors.surface,
    child: Center(
      child: Icon(Icons.movie_outlined, color: colors.onSurfaceVariant, size: 28),
    ),
  );
}
