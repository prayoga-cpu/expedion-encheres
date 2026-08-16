import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// The two ways in to a quote, drawn rather than iconified.
///
/// A single glyph could not carry the distinction the page exists to make —
/// both routes end in "we send you a quote", and both were previously shown
/// with the same generic button, so nothing on screen told a client which one
/// applied to them. What actually differs is the *input*: a machine-readable
/// PDF we can read for you, versus details you type in yourself.
///
/// These are painted with the theme's own tokens instead of shipped as images,
/// so they follow light/dark without a second asset and cost nothing to
/// download.
class DevisRouteIllustration extends StatelessWidget {
  const DevisRouteIllustration({
    super.key,
    required this.kind,
    this.height = 132.0,
  });

  final DevisRouteKind kind;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _RoutePainter(
          kind: kind,
          ink: theme.primaryText,
          muted: theme.secondaryText,
          accent: theme.primary,
          surface: theme.secondaryBackground,
          line: theme.alternate,
        ),
      ),
    );
  }
}

enum DevisRouteKind {
  /// A PDF slip the extractor can read.
  pdfSlip,

  /// Anything else — a photo, a scan, a paper slip, or no slip at all.
  manualDetails,
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.kind,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.surface,
    required this.line,
  });

  final DevisRouteKind kind;
  final Color ink;
  final Color muted;
  final Color accent;
  final Color surface;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    // Everything is laid out against a 200x120 grid and scaled, so the drawing
    // keeps its proportions at whatever height the card gives it.
    final scale = size.height / 120.0;
    canvas.save();
    canvas.translate((size.width - 200.0 * scale) / 2, 0);
    canvas.scale(scale);

    switch (kind) {
      case DevisRouteKind.pdfSlip:
        _paintPdf(canvas);
      case DevisRouteKind.manualDetails:
        _paintManual(canvas);
    }
    canvas.restore();
  }

  /// A slip being read: the document, its folded PDF corner, and a scan band
  /// crossing it with the extracted fields lifting off to the right.
  void _paintPdf(Canvas canvas) {
    final sheet = Paint()..color = surface;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = line;

    const w = 74.0, h = 92.0, x = 30.0, y = 14.0;
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(x, y, w, h),
      const Radius.circular(8.0),
    );
    canvas.drawRRect(body, sheet);
    canvas.drawRRect(body, stroke);

    // Folded corner.
    final fold = Path()
      ..moveTo(x + w - 22.0, y)
      ..lineTo(x + w, y + 22.0)
      ..lineTo(x + w - 22.0, y + 22.0)
      ..close();
    canvas.drawPath(fold, Paint()..color = accent.withValues(alpha: 0.25));
    canvas.drawPath(fold, stroke);

    // Text lines on the slip.
    final rule = Paint()..color = muted.withValues(alpha: 0.45);
    for (var i = 0; i < 5; i++) {
      final ly = y + 34.0 + i * 11.0;
      final lw = i == 4 ? 28.0 : 46.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 12.0, ly, lw, 4.0),
          const Radius.circular(2.0),
        ),
        rule,
      );
    }

    // The scan band — the thing that makes this route the automatic one.
    final band = Rect.fromLTWH(x - 8.0, y + 52.0, w + 16.0, 12.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(band, const Radius.circular(6.0)),
      Paint()..color = accent.withValues(alpha: 0.22),
    );
    canvas.drawLine(
      Offset(band.left, band.center.dy),
      Offset(band.right, band.center.dy),
      Paint()
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = accent,
    );

    // Fields lifting off, already filled in.
    final chip = Paint()..color = accent.withValues(alpha: 0.9);
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(122.0, 34.0 + i * 18.0, 46.0 - i * 8.0, 8.0),
          const Radius.circular(4.0),
        ),
        chip,
      );
    }
    // Arrow from slip to fields.
    final arrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..color = accent;
    canvas.drawLine(const Offset(110.0, 58.0), const Offset(118.0, 58.0), arrow);
    canvas.drawPath(
      Path()
        ..moveTo(114.0, 53.0)
        ..lineTo(119.0, 58.0)
        ..lineTo(114.0, 63.0),
      arrow,
    );
  }

  /// A form being filled in by hand: empty fields, a pen, and the photo or
  /// paper slip it is being copied from.
  void _paintManual(Canvas canvas) {
    final sheet = Paint()..color = surface;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = line;

    // The form.
    const w = 86.0, h = 92.0, x = 22.0, y = 14.0;
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(x, y, w, h),
      const Radius.circular(8.0),
    );
    canvas.drawRRect(body, sheet);
    canvas.drawRRect(body, stroke);

    // Empty input rows — outlined, not filled, because nothing is known yet.
    for (var i = 0; i < 3; i++) {
      final fy = y + 18.0 + i * 24.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 12.0, fy, 62.0, 14.0),
          const Radius.circular(4.0),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = muted.withValues(alpha: 0.55),
      );
      if (i < 2) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 17.0, fy + 5.0, 26.0 - i * 8.0, 4.0),
            const Radius.circular(2.0),
          ),
          Paint()..color = ink.withValues(alpha: 0.55),
        );
      }
    }

    // The source the client is reading from: a photo of a paper slip.
    final photo = RRect.fromRectAndRadius(
      const Rect.fromLTWH(124.0, 22.0, 54.0, 44.0),
      const Radius.circular(6.0),
    );
    canvas.drawRRect(photo, Paint()..color = accent.withValues(alpha: 0.18));
    canvas.drawRRect(photo, stroke);
    // A little mountain-and-sun, the universal "this is an image".
    canvas.drawCircle(
      const Offset(140.0, 36.0),
      5.0,
      Paint()..color = accent.withValues(alpha: 0.8),
    );
    canvas.drawPath(
      Path()
        ..moveTo(128.0, 60.0)
        ..lineTo(146.0, 42.0)
        ..lineTo(160.0, 56.0)
        ..lineTo(168.0, 48.0)
        ..lineTo(174.0, 60.0)
        ..close(),
      Paint()..color = accent.withValues(alpha: 0.55),
    );

    // The pen, angled over the form's last field.
    final pen = Path()
      ..moveTo(96.0, 104.0)
      ..lineTo(140.0, 74.0)
      ..lineTo(148.0, 84.0)
      ..lineTo(104.0, 114.0)
      ..close();
    canvas.drawPath(pen, Paint()..color = accent);
    canvas.drawPath(
      Path()
        ..moveTo(96.0, 104.0)
        ..lineTo(104.0, 114.0)
        ..lineTo(92.0, 116.0)
        ..close(),
      Paint()..color = ink,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.kind != kind ||
      old.ink != ink ||
      old.muted != muted ||
      old.accent != accent ||
      old.surface != surface ||
      old.line != line;
}
