import 'package:flutter/material.dart';

/// Google's "G", drawn rather than shipped as an asset so it needs no network
/// and stays crisp at any size. The four filled shapes are the official brand
/// mark's outlines, traced on Google's 48x48 artboard and scaled to [size].
class GoogleGlyph extends StatelessWidget {
  const GoogleGlyph({super.key, this.size = 20.0});

  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _GoogleGlyphPainter());
}

class _GoogleGlyphPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  /// The artboard the paths below are expressed in.
  static const _viewBox = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBox, size.height / _viewBox);

    final paint = Paint()..style = PaintingStyle.fill;

    // Right side: the upper arm and the horizontal bar of the G.
    canvas.drawPath(
      Path()
        ..moveTo(45.12, 24.5)
        ..relativeCubicTo(0, -1.56, -0.14, -3.06, -0.4, -4.5)
        ..lineTo(24, 20)
        ..relativeLineTo(0, 8.51)
        ..relativeLineTo(11.84, 0)
        ..relativeCubicTo(-0.51, 2.75, -2.06, 5.08, -4.39, 6.64)
        ..relativeLineTo(0, 5.52)
        ..relativeLineTo(7.11, 0)
        ..relativeCubicTo(4.16, -3.83, 6.56, -9.47, 6.56, -16.17)
        ..close(),
      paint..color = _blue,
    );

    // Bottom: the sweep under the bowl.
    canvas.drawPath(
      Path()
        ..moveTo(24, 46)
        ..relativeCubicTo(5.94, 0, 10.92, -1.97, 14.56, -5.33)
        ..relativeLineTo(-7.11, -5.52)
        ..relativeCubicTo(-1.97, 1.32, -4.49, 2.1, -7.45, 2.1)
        ..relativeCubicTo(-5.73, 0, -10.58, -3.87, -12.31, -9.07)
        ..lineTo(4.34, 28.18)
        ..relativeLineTo(0, 5.7)
        ..cubicTo(7.96, 41.07, 15.4, 46, 24, 46)
        ..close(),
      paint..color = _green,
    );

    // Left: the outer edge of the bowl.
    canvas.drawPath(
      Path()
        ..moveTo(11.69, 28.18)
        ..cubicTo(11.25, 26.86, 11, 25.45, 11, 24)
        ..cubicTo(11, 22.55, 11.25, 21.14, 11.69, 19.82)
        ..relativeLineTo(0, -5.7)
        ..lineTo(4.34, 14.12)
        ..cubicTo(2.85, 17.09, 2, 20.45, 2, 24)
        ..cubicTo(2, 27.55, 2.85, 30.91, 4.34, 33.88)
        ..relativeLineTo(7.35, -5.7)
        ..close(),
      paint..color = _yellow,
    );

    // Top: the opening sweep.
    canvas.drawPath(
      Path()
        ..moveTo(24, 10.75)
        ..relativeCubicTo(3.23, 0, 6.13, 1.11, 8.41, 3.29)
        ..relativeLineTo(6.31, -6.31)
        ..cubicTo(34.91, 4.18, 29.93, 2, 24, 2)
        ..cubicTo(15.4, 2, 7.96, 6.93, 4.34, 14.12)
        ..relativeLineTo(7.35, 5.7)
        ..relativeCubicTo(1.73, -5.2, 6.58, -9.07, 12.31, -9.07)
        ..close(),
      paint..color = _red,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_GoogleGlyphPainter oldDelegate) => false;
}
