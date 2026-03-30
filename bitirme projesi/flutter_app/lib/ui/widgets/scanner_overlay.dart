import 'package:flutter/material.dart';

class ScannerOverlay extends StatefulWidget {
  final Widget child;
  final bool isScanning;
  final Color scannerColor;

  const ScannerOverlay({
    super.key,
    required this.child,
    required this.isScanning,
    this.scannerColor = const Color(0xFF1FAB89),
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ScannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.isScanning)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ScannerPainter(
                    progress: _animation.value,
                    color: widget.scannerColor,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ScannerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScannerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double yPos = size.height * progress;

    final Paint linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.stroke;

    // Draw glow
    canvas.drawLine(
      Offset(0, yPos),
      Offset(size.width, yPos),
      glowPaint,
    );

    // Draw sharp center line
    canvas.drawLine(
      Offset(0, yPos),
      Offset(size.width, yPos),
      linePaint,
    );

    // Draw fade gradient above the line
    final Rect rect = Rect.fromLTRB(0, yPos - 30, size.width, yPos);
    final Paint gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.0),
          color.withValues(alpha: 0.2),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
