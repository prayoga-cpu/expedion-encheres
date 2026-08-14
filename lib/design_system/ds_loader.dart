import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import 'ds_tokens.dart';

/// Equivalent of `expeditoo-ship/src/components/ui/page-loader.tsx`.
///
/// The roadmap's rule is "no spinner-in-place": a loading surface takes the
/// whole region and centres one indicator, rather than swapping individual
/// widgets for small spinners as they resolve.
class DSPageLoader extends StatelessWidget {
  const DSPageLoader({
    super.key,
    this.message,
    this.size = DSLoaderSize.md,
    this.minHeight = 400.0,
  });

  final String? message;
  final DSLoaderSize size;
  final double minHeight;

  double get _diameter {
    switch (size) {
      case DSLoaderSize.sm:
        return 28.0;
      case DSLoaderSize.md:
        return 40.0;
      case DSLoaderSize.lg:
        return 56.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _diameter,
            height: _diameter,
            child: CircularProgressIndicator(
              strokeWidth: size == DSLoaderSize.sm ? 2.0 : 3.0,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
              backgroundColor: theme.alternate,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16.0),
            Text(message!,
                textAlign: TextAlign.center, style: theme.labelMedium),
          ],
        ],
      ),
    );
  }
}

enum DSLoaderSize { sm, md, lg }

/// Skeleton block for content-shaped placeholders — `skeleton.tsx`.
class DSSkeleton extends StatefulWidget {
  const DSSkeleton({
    super.key,
    this.width,
    this.height = 16.0,
    this.radius = DSShape.small,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<DSSkeleton> createState() => _DSSkeletonState();
}

class _DSSkeletonState extends State<DSSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: DSMotion.curve),
      ),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: theme.secondary.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
