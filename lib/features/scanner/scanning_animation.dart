part of 'scanner_screen.dart';

class _ScanningAnimation extends StatefulWidget {
  final bool isScanning;

  const _ScanningAnimation({required this.isScanning});

  @override
  State<_ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<_ScanningAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _ScanningAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning) {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
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
    if (!widget.isScanning) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScannerPainter(
            progress: _animation.value,
            color: Theme.of(context).primaryColor,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _ScannerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScannerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cutOutSize = 300.0;
    final center = size.center(Offset.zero);
    final top = center.dy - cutOutSize / 2;
    final bottom = center.dy + cutOutSize / 2;
    final left = center.dx - cutOutSize / 2;
    final right = center.dx + cutOutSize / 2;

    final y = top + (bottom - top) * progress;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(left, y)
      ..lineTo(right, y);

    canvas.drawPath(path, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
