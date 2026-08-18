import 'package:flutter/material.dart';

/// The only spinner in the app. Its colour comes from `progressIndicatorTheme`, which is
/// why an unstyled blue one cannot appear.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 28,
      height: 28,
      child: CircularProgressIndicator(strokeWidth: 2.5),
    ),
  );
}
