import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ds_palette.dart';

/// The feedback a form owes the person filling it in: that something is wrong,
/// and that something worked.
///
/// The landing page's two quote forms both submit into the same place — a
/// draft parked for the devis flow to pick up — and both have to answer the
/// same two questions before they get there. Keeping the answers here rather
/// than inside `accueil_widget.dart` means the express card and the full form
/// shake, complain and confirm identically, which is what makes the second one
/// feel familiar after the first.
///
/// Nothing here fires on its own: each widget animates in response to a value
/// the form owns, so the form decides *when* and this file decides *how*.

/// Shakes its child once, every time [trigger] changes.
///
/// The motion is the standard "no" gesture: a decaying horizontal oscillation,
/// not a bounce. It is driven by a counter rather than a bool because two
/// failed submissions in a row must shake twice — a bool would already be
/// `true` the second time and nothing would move.
class XpdShake extends StatefulWidget {
  const XpdShake({
    super.key,
    required this.trigger,
    required this.child,
    this.distance = 8.0,
    this.duration = const Duration(milliseconds: 420),
  });

  /// Increment to shake. The first build never shakes, whatever the value.
  final int trigger;

  final Widget child;

  /// Peak travel either side of rest, in logical pixels.
  final double distance;

  final Duration duration;

  @override
  State<XpdShake> createState() => _XpdShakeState();
}

class _XpdShakeState extends State<XpdShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didUpdateWidget(XpdShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      // Built once and passed through: the subtree under a quote form is the
      // whole panel, and rebuilding it on every frame of the shake would be
      // paying for a repaint to move something sideways.
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        if (t == 0.0 || t == 1.0) return child!;
        // Three passes, each shorter than the last.
        final offset = math.sin(t * math.pi * 3) * widget.distance * (1.0 - t);
        return Transform.translate(
          offset: Offset(offset, 0.0),
          child: child,
        );
      },
    );
  }
}

/// A one-line problem that belongs to a control rather than to a field —
/// a rejected upload, mainly, where there is no [TextFormField] to carry it.
///
/// Collapses to nothing when [message] is null, so the layout does not hold a
/// gap open for an error that is not there.
class XpdInlineError extends StatelessWidget {
  const XpdInlineError({super.key, required this.message, this.topPadding = 8.0});

  final String? message;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final message = this.message;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: message == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: ValueKey(message),
                padding: EdgeInsets.only(top: topPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 15.0, color: palette.red),
                    const SizedBox(width: 7.0),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13.0,
                          height: 1.4,
                          color: palette.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// The tick that draws itself, inside a ring that scales in behind it.
///
/// Drawn rather than an [Icon] because the point is the drawing: a check that
/// is simply *there* reads as a state, and a check that is struck reads as
/// something having just happened, which is what a submitted form wants to
/// say.
class XpdAnimatedCheck extends StatefulWidget {
  const XpdAnimatedCheck({super.key, this.size = 46.0, this.color});

  final double size;

  /// Defaults to the palette's green.
  final Color? color;

  @override
  State<XpdAnimatedCheck> createState() => _XpdAnimatedCheckState();
}

class _XpdAnimatedCheckState extends State<XpdAnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final color = widget.color ?? palette.green;

    // The ring lands first, the stroke follows it in.
    final ring = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );
    final stroke = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Transform.scale(
        scale: ring.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.42)),
          ),
          child: CustomPaint(
            painter: _CheckPainter(progress: stroke.value, color: color),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    // The three points of a tick, as fractions of the box, so the mark scales
    // with whatever diameter the caller asked for.
    final start = Offset(size.width * 0.28, size.height * 0.52);
    final elbow = Offset(size.width * 0.44, size.height * 0.68);
    final end = Offset(size.width * 0.73, size.height * 0.35);

    final down = (elbow - start).distance;
    final up = (end - elbow).distance;
    final drawn = (down + up) * progress;

    final path = Path()..moveTo(start.dx, start.dy);
    if (drawn <= down) {
      final point = Offset.lerp(start, elbow, drawn / down)!;
      path.lineTo(point.dx, point.dy);
    } else {
      path.lineTo(elbow.dx, elbow.dy);
      final point = Offset.lerp(elbow, end, (drawn - down) / up)!;
      path.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// What a quote form shows in place of its fields once they have been accepted.
///
/// It replaces the form rather than sitting above it: the answers are parked
/// and the next step is elsewhere, so leaving the fields on screen would invite
/// a second submission of the same thing. [onEdit] is the way back for someone
/// who spots a typo in the two seconds before the redirect.
class XpdFormSuccess extends StatefulWidget {
  const XpdFormSuccess({
    super.key,
    required this.title,
    required this.message,
    this.footnote,
    this.editLabel,
    this.onEdit,
    this.compact = false,
  });

  final String title;
  final String message;

  /// Fine print under the message — what happens next, typically.
  final String? footnote;

  final String? editLabel;
  final VoidCallback? onEdit;

  /// Tightens the type and spacing for the hero card, which is narrow.
  final bool compact;

  @override
  State<XpdFormSuccess> createState() => _XpdFormSuccessState();
}

class _XpdFormSuccessState extends State<XpdFormSuccess>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    final compact = widget.compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        XpdAnimatedCheck(size: compact ? 44.0 : 54.0),
        SizedBox(height: compact ? 18.0 : 24.0),
        FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            // A short lift, so the copy arrives after the tick rather than
            // with it.
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.16),
              end: Offset.zero,
            ).animate(_fade),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: compact ? 19.0 : 26.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: (compact ? 19.0 : 26.0) * -0.025,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 10.0),
                Text(
                  widget.message,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: compact ? 14.5 : 16.0,
                    height: 1.6,
                    color: palette.muted,
                  ),
                ),
                if (widget.footnote != null) ...[
                  SizedBox(height: compact ? 14.0 : 18.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: palette.greenBg,
                      border: Border.all(
                        color: palette.green.withValues(alpha: 0.28),
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      widget.footnote!,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13.0,
                        height: 1.5,
                        color: palette.green,
                      ),
                    ),
                  ),
                ],
                if (widget.onEdit != null && widget.editLabel != null) ...[
                  SizedBox(height: compact ? 14.0 : 18.0),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.onEdit,
                      child: Text(
                        widget.editLabel!,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13.5,
                          color: palette.blueLink,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
