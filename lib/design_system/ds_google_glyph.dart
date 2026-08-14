import 'package:flutter/material.dart';

/// Google's "G", drawn rather than shipped as an asset so it needs no network
/// and stays crisp at any size. The four arcs use Google's brand colours in
/// their published order.
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

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.22;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Quadrant arcs, starting from the right and running clockwise.
    void arc(double startDeg, double sweepDeg, Color color) {
      canvas.drawArc(
        rect,
        startDeg * 3.1415926535 / 180.0,
        sweepDeg * 3.1415926535 / 180.0,
        false,
        paint..color = color,
      );
    }

    arc(-20.0, -70.0, _red); // top right
    arc(-90.0, -80.0, _yellow); // left upper — drawn anticlockwise
    arc(170.0, 80.0, _green); // bottom left
    arc(-20.0, 70.0, _blue); // right, into the bar

    // The horizontal bar of the G.
    final barPaint = Paint()..color = _blue;
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.5,
        size.height * 0.5 - stroke / 2,
        size.width * 0.5 - stroke / 2,
        stroke,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(_GoogleGlyphPainter oldDelegate) => false;
}
