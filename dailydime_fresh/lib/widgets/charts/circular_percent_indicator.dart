import 'package:flutter/material.dart';
import 'dart:math' as math;

enum CircularStrokeCap { round, butt, square }

class CircularPercentIndicator extends StatefulWidget {
  /// Radius of the circular indicator
  final double radius;
  
  /// Width of the progress line
  final double lineWidth;
  
  /// Progress percentage (0.0 to 1.0)
  final double percent;
  
  /// Widget to display in the center
  final Widget? center;
  
  /// Widget to display below the indicator
  final Widget? footer;
  
  /// Color of the progress line
  final Color progressColor;
  
  /// Color of the background line
  final Color backgroundColor;
  
  /// Whether to animate the progress
  final bool animation;
  
  /// Duration of the animation in milliseconds
  final int animationDuration;
  
  /// Type of stroke cap for the progress line
  final CircularStrokeCap circularStrokeCap;
  
  /// Starting angle for the progress (in radians)
  final double startAngle;
  
  /// Whether the progress should be clockwise
  final bool reverse;
  
  /// Curve for the animation
  final Curve curve;
  
  /// Background color for the entire widget
  final Color? fillColor;
  
  /// Additional rotation for the entire indicator
  final double rotateLinearGradient;

  const CircularPercentIndicator({
    Key? key,
    this.radius = 60.0,
    this.lineWidth = 5.0,
    this.percent = 0.0,
    this.center,
    this.footer,
    this.progressColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    this.animation = false,
    this.animationDuration = 500,
    this.circularStrokeCap = CircularStrokeCap.round,
    this.startAngle = 0.0,
    this.reverse = false,
    this.curve = Curves.linear,
    this.fillColor,
    this.rotateLinearGradient = 0.0,
  }) : super(key: key);

  @override
  State<CircularPercentIndicator> createState() => _CircularPercentIndicatorState();
}

class _CircularPercentIndicatorState extends State<CircularPercentIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;
  double _currentPercent = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.animation) {
      _animationController = AnimationController(
        duration: Duration(milliseconds: widget.animationDuration),
        vsync: this,
      );
      
      _animation = Tween<double>(
        begin: 0.0,
        end: widget.percent,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: widget.curve,
      ));
      
      _animation!.addListener(() {
        setState(() {
          _currentPercent = _animation!.value;
        });
      });
      
      _animationController!.forward();
    } else {
      _currentPercent = widget.percent;
    }
  }

  @override
  void didUpdateWidget(CircularPercentIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation && oldWidget.percent != widget.percent) {
      _animationController?.reset();
      _animation = Tween<double>(
        begin: _currentPercent,
        end: widget.percent,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: widget.curve,
      ));
      _animationController?.forward();
    } else if (!widget.animation) {
      _currentPercent = widget.percent;
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          child: CustomPaint(
            painter: _CircularPercentPainter(
              progress: _currentPercent,
              progressColor: widget.progressColor,
              backgroundColor: widget.backgroundColor,
              strokeWidth: widget.lineWidth,
              strokeCap: widget.circularStrokeCap,
              startAngle: widget.startAngle,
              reverse: widget.reverse,
              fillColor: widget.fillColor,
              rotateLinearGradient: widget.rotateLinearGradient,
            ),
            child: widget.center != null
                ? Center(child: widget.center)
                : null,
          ),
        ),
        if (widget.footer != null) ...[
          const SizedBox(height: 10),
          widget.footer!,
        ],
      ],
    );
  }
}

class _CircularPercentPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;
  final CircularStrokeCap strokeCap;
  final double startAngle;
  final bool reverse;
  final Color? fillColor;
  final double rotateLinearGradient;

  _CircularPercentPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
    required this.strokeCap,
    required this.startAngle,
    required this.reverse,
    this.fillColor,
    required this.rotateLinearGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle if fillColor is provided
    if (fillColor != null) {
      final fillPaint = Paint()
        ..color = fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + strokeWidth / 2, fillPaint);
    }

    // Background arc paint
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = _getStrokeCap(strokeCap);

    // Progress arc paint
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = _getStrokeCap(strokeCap);

    // Draw background circle
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final sweepAngle = 2 * math.pi * progress;
    final actualStartAngle = startAngle + rotateLinearGradient;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      actualStartAngle,
      reverse ? -sweepAngle : sweepAngle,
      false,
      progressPaint,
    );
  }

  StrokeCap _getStrokeCap(CircularStrokeCap cap) {
    switch (cap) {
      case CircularStrokeCap.round:
        return StrokeCap.round;
      case CircularStrokeCap.butt:
        return StrokeCap.butt;
      case CircularStrokeCap.square:
        return StrokeCap.square;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}