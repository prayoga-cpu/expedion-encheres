import 'package:flutter/material.dart';

import 'ds_palette.dart';

/// The current EXPEDION mark.
///
/// A direct port of the markup the site draws it with: an amber ring holding a
/// blue dot, trailed by two stacked amber speed bars that tuck slightly under
/// the ring. The site renders it at four sizes — 26px on the group card, 28px
/// in the footer, 30px in the header, 64px in the app mockup — with every
/// dimension scaled from the ring, so this takes one [size] and derives the
/// rest from the ratios the 30px header instance establishes.
///
/// The mark keeps [XpdPalette.brandAmber] and [XpdPalette.blue] in both themes:
/// the site hard-codes those hex values here rather than reading `--amber`, so
/// the logo does not shift when the light toggle darkens amber *text*.
class XpdLogoMark extends StatelessWidget {
  const XpdLogoMark({super.key, this.size = 30.0});

  /// Diameter of the amber ring. Everything else is a ratio of it.
  final double size;

  // Ratios read off the 30px instance: 3.5px stroke, 9px dot, 10×4 and 6×4
  // bars, 3px between them, pulled 2px back under the ring.
  static const double _stroke = 3.5 / 30;
  static const double _dot = 9 / 30;
  static const double _barLong = 10 / 30;
  static const double _barShort = 6 / 30;
  static const double _barThick = 4 / 30;
  static const double _barGap = 3 / 30;
  static const double _overlap = 2 / 30;

  @override
  Widget build(BuildContext context) {
    final barHeight = size * _barThick;

    Widget bar(double widthRatio, double opacity) => Container(
          width: size * widthRatio,
          height: barHeight,
          decoration: BoxDecoration(
            color: XpdPalette.brandAmber.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(barHeight / 2),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: XpdPalette.brandAmber,
              width: size * _stroke,
            ),
          ),
          child: Center(
            child: Container(
              width: size * _dot,
              height: size * _dot,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: XpdPalette.blue,
              ),
            ),
          ),
        ),
        // `margin-left:-2px` — the bars overlap the ring's stroke.
        Transform.translate(
          offset: Offset(-size * _overlap, 0.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(_barLong, 1.0),
              SizedBox(height: size * _barGap),
              bar(_barShort, 0.45),
            ],
          ),
        ),
      ],
    );
  }
}

/// "EXPEDION" over a mono-spaced, wide-tracked "ENCHÈRES".
class XpdWordmark extends StatelessWidget {
  const XpdWordmark({super.key, this.size = 16.0, this.color});

  /// Cap height of the EXPEDION line; ENCHÈRES is drawn at half of it.
  final double size;

  /// Defaults to the ambient [XpdPalette.text].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EXPEDION',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: size,
            fontWeight: FontWeight.w700,
            letterSpacing: size * -0.02,
            height: 1.0,
            color: color ?? palette.text,
          ),
        ),
        SizedBox(height: size * 0.0625),
        Text(
          'ENCHÈRES',
          style: TextStyle(
            fontFamily: 'Geist Mono',
            fontSize: size * 0.5,
            letterSpacing: size * 0.1,
            height: 1.0,
            color: palette.amber,
          ),
        ),
      ],
    );
  }
}

/// Mark plus wordmark, the lockup used in the header and the footer.
class XpdLogo extends StatelessWidget {
  const XpdLogo({
    super.key,
    this.markSize = 30.0,
    this.wordmarkSize = 16.0,
    this.showWordmark = true,
    this.onTap,
  });

  final double markSize;
  final double wordmarkSize;
  final bool showWordmark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final lockup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        XpdLogoMark(size: markSize),
        if (showWordmark) ...[
          const SizedBox(width: 10.0),
          XpdWordmark(size: wordmarkSize),
        ],
      ],
    );

    if (onTap == null) return lockup;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: lockup,
    );
  }
}

/// The Expeditoo mark — a blue rounded square holding a white disc with a blue
/// chevron. Used wherever the page points at the carrier-side product.
class ExpeditooLogoMark extends StatelessWidget {
  const ExpeditooLogoMark({super.key, this.size = 26.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = XpdPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: XpdPalette.blue,
        borderRadius: BorderRadius.circular(size * 8 / 26),
      ),
      child: Center(
        child: Container(
          width: size * 14 / 26,
          height: size * 14 / 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.bg2,
          ),
          child: Center(
            child: Transform.translate(
              offset: Offset(-size / 26, size / 26),
              child: Transform.rotate(
                angle: 0.7853981634, // 45°
                child: Container(
                  width: size * 7 / 26,
                  height: size * 7 / 26,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: XpdPalette.blue,
                        width: size * 2 / 26,
                      ),
                      right: BorderSide(
                        color: XpdPalette.blue,
                        width: size * 2 / 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
