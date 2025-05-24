import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isAnimated;

  const AppLogo({
    super.key,
    this.size = 200,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue[900]!,
                width: 4,
              ),
            ),
          ),
          // Inner circle with gradient
          Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[900]!,
                  Colors.blue[700]!,
                ],
              ),
            ),
          ),
          // Custom binoculars icon
          CustomPaint(
            size: Size(size * 0.6, size * 0.6),
            painter: BinocularsPainter(
              color: Colors.white,
              strokeWidth: size * 0.08,
            ),
          ),
          // Sound waves
          if (isAnimated) ...[
            _buildSoundWave(size * 0.5, 0.0),
            _buildSoundWave(size * 0.6, 0.2),
            _buildSoundWave(size * 0.7, 0.4),
          ],
        ],
      ),
    );
  }

  Widget _buildSoundWave(double size, double delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: (1500 + (delay * 1000)).toInt()),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3 * (1 - value)),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}

class BinocularsPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  BinocularsPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final lensRadius = size.width * 0.15;
    final bridgeWidth = size.width * 0.1;
    final bridgeHeight = size.height * 0.15;

    // Left lens
    canvas.drawCircle(
      Offset(center.dx - lensRadius - bridgeWidth / 2, center.dy),
      lensRadius,
      paint,
    );

    // Right lens
    canvas.drawCircle(
      Offset(center.dx + lensRadius + bridgeWidth / 2, center.dy),
      lensRadius,
      paint,
    );

    // Bridge
    final bridgePath = Path()
      ..moveTo(center.dx - bridgeWidth / 2, center.dy - bridgeHeight / 2)
      ..lineTo(center.dx + bridgeWidth / 2, center.dy - bridgeHeight / 2)
      ..lineTo(center.dx + bridgeWidth / 2, center.dy + bridgeHeight / 2)
      ..lineTo(center.dx - bridgeWidth / 2, center.dy + bridgeHeight / 2)
      ..close();

    canvas.drawPath(bridgePath, paint);

    // Visual impairment symbol (small dots in lenses)
    final dotRadius = strokeWidth * 0.5;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Left lens dot
    canvas.drawCircle(
      Offset(center.dx - lensRadius - bridgeWidth / 2, center.dy),
      dotRadius,
      dotPaint,
    );

    // Right lens dot
    canvas.drawCircle(
      Offset(center.dx + lensRadius + bridgeWidth / 2, center.dy),
      dotRadius,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
