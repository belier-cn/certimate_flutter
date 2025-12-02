import "dart:math" as math;

import "package:flutter/material.dart";

class PolygonBorder extends StatelessWidget {
  final BorderRadius borderRadius;

  final BorderSide borderSide;
  final Widget? child;

  final bool border;

  const PolygonBorder({
    super.key,
    required this.borderRadius,
    required this.borderSide,
    this.child,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!border) {
      return child ?? const SizedBox.shrink();
    }
    return CustomPaint(
      painter: PolygonBorderPainter(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      child: child != null
          ? ClipPath(
              clipper: PolygonClipper(borderRadius: borderRadius),
              child: child,
            )
          : null,
    );
  }
}

class PolygonClipper extends CustomClipper<Path> {
  final BorderRadius borderRadius;

  const PolygonClipper({required this.borderRadius});

  @override
  Path getClip(Size size) {
    final RRect borderRect = borderRadius.toRRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    return _getPolygonBorderPath(borderRect);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class PolygonBorderPainter extends CustomPainter {
  final BorderRadius borderRadius;

  final BorderSide borderSide;

  const PolygonBorderPainter({
    required this.borderRadius,
    required this.borderSide,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = borderSide.color
      ..strokeWidth = borderSide.width
      ..style = PaintingStyle.stroke;
    final RRect borderRect = borderRadius.toRRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    canvas.drawPath(_getPolygonBorderPath(borderRect), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Path _getPolygonBorderPath(RRect rRect) {
  final double tlInset =
      math.min(rRect.tlRadius.x + rRect.tlRadius.y, rRect.height) / 2;
  final double trInset =
      math.min(rRect.trRadius.x + rRect.trRadius.y, rRect.height) / 2;
  final double blInset =
      math.min(rRect.blRadius.x + rRect.blRadius.y, rRect.height) / 2;
  final double brInset =
      math.min(rRect.brRadius.x + rRect.brRadius.y, rRect.height) / 2;
  final left = rRect.left;
  final top = rRect.top;
  final right = rRect.right;
  final bottom = rRect.bottom;

  return Path()
    ..moveTo(left + tlInset, top)
    ..lineTo(right - trInset, top)
    ..lineTo(right, top + trInset)
    ..lineTo(right, bottom - brInset)
    ..lineTo(right - brInset, bottom)
    ..lineTo(left + blInset, bottom)
    ..lineTo(left, bottom - blInset)
    ..lineTo(left, top + tlInset)
    ..close();
}
