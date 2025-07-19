import 'package:flutter/material.dart';

enum CustomMainAxisAlignment { start, end, center, spaceBetween, spaceAround, spaceEvenly }

class LinearPercentIndicator extends StatefulWidget {
  /// Width of the line indicator
  final double? width;
  
  /// Height of the progress line
  final double lineHeight;
  
  /// Progress percentage (0.0 to 1.0)
  final double percent;
  
  /// Widget to display on the left
  final Widget? leading;
  
  /// Widget to display on the right
  final Widget? trailing;
  
  /// Color of the progress line
  final Color progressColor;
  
  /// Color of the background line
  final Color? backgroundColor;
  
  /// Background color for the entire widget
  final Color? fillColor;
  
  /// Whether to animate the progress
  final bool animation;
  
  /// Duration of the animation in milliseconds
  final int animationDuration;
  
  /// Curve for the animation
  final Curve animationCurve;
  
  /// Radius for rounded corners
  final Radius? barRadius;
  
  /// Whether the progress should be from right to left
  final bool isRTL;
  
  /// Alignment of the main axis
  final MainAxisAlignment mainAxisAlignment;
  
  /// Padding around the entire widget
  final EdgeInsetsGeometry padding;
  
  /// Text to display in the center of the progress bar
  final Widget? center;
  
  /// Whether to clip the corners
  final bool clipLinearGradient;
  
  /// Gradient for the progress bar
  final LinearGradient? linearGradient;
  
  /// Gradient for the background
  final LinearGradient? backgroundGradient;

  const LinearPercentIndicator({
    Key? key,
    this.width,
    this.lineHeight = 5.0,
    this.percent = 0.0,
    this.leading,
    this.trailing,
    this.progressColor = Colors.blue,
    this.backgroundColor,
    this.fillColor,
    this.animation = false,
    this.animationDuration = 500,
    this.animationCurve = Curves.linear,
    this.barRadius,
    this.isRTL = false,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.padding = EdgeInsets.zero,
    this.center,
    this.clipLinearGradient = false,
    this.linearGradient,
    this.backgroundGradient,
  }) : super(key: key);

  @override
  State<LinearPercentIndicator> createState() => _LinearPercentIndicatorState();
}

class _LinearPercentIndicatorState extends State<LinearPercentIndicator>
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
        curve: widget.animationCurve,
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
  void didUpdateWidget(LinearPercentIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation && oldWidget.percent != widget.percent) {
      _animationController?.reset();
      _animation = Tween<double>(
        begin: _currentPercent,
        end: widget.percent,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: widget.animationCurve,
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
    return Padding(
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: _getMainAxisAlignment(),
        children: [
          if (widget.leading != null) ...[
            widget.leading!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Container(
              width: widget.width,
              height: widget.lineHeight,
              child: CustomPaint(
                painter: _LinearPercentPainter(
                  progress: _currentPercent,
                  progressColor: widget.progressColor,
                  backgroundColor: widget.backgroundColor ?? Colors.grey[300]!,
                  barRadius: widget.barRadius,
                  isRTL: widget.isRTL,
                  fillColor: widget.fillColor,
                  clipLinearGradient: widget.clipLinearGradient,
                  linearGradient: widget.linearGradient,
                  backgroundGradient: widget.backgroundGradient,
                ),
                child: widget.center != null
                    ? Center(child: widget.center)
                    : null,
              ),
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 10),
            widget.trailing!,
          ],
        ],
      ),
    );
  }

  MainAxisAlignment _getMainAxisAlignment() {
    switch (widget.mainAxisAlignment) {
      case MainAxisAlignment.start:
        return MainAxisAlignment.start;
      case MainAxisAlignment.end:
        return MainAxisAlignment.end;
      case MainAxisAlignment.center:
        return MainAxisAlignment.center;
      case MainAxisAlignment.spaceBetween:
        return MainAxisAlignment.spaceBetween;
      case MainAxisAlignment.spaceAround:
        return MainAxisAlignment.spaceAround;
      case MainAxisAlignment.spaceEvenly:
        return MainAxisAlignment.spaceEvenly;
    }
  }
}

class _LinearPercentPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final Radius? barRadius;
  final bool isRTL;
  final Color? fillColor;
  final bool clipLinearGradient;
  final LinearGradient? linearGradient;
  final LinearGradient? backgroundGradient;

  _LinearPercentPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    this.barRadius,
    required this.isRTL,
    this.fillColor,
    required this.clipLinearGradient,
    this.linearGradient,
    this.backgroundGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background if fillColor is provided
    if (fillColor != null) {
      final fillPaint = Paint()
        ..color = fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, fillPaint);
    }

    // Background paint
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Progress paint
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.fill;

    final backgroundRect = Offset.zero & size;
    
    // Draw background
    if (barRadius != null) {
      final backgroundRRect = RRect.fromRectAndRadius(backgroundRect, barRadius!);
      if (backgroundGradient != null) {
        backgroundPaint.shader = backgroundGradient!.createShader(backgroundRect);
      }
      canvas.drawRRect(backgroundRRect, backgroundPaint);
    } else {
      if (backgroundGradient != null) {
        backgroundPaint.shader = backgroundGradient!.createShader(backgroundRect);
      }
      canvas.drawRect(backgroundRect, backgroundPaint);
    }

    // Calculate progress width
    double progressWidth;
    if (isRTL) {
      progressWidth = size.width * (1.0 - progress);
    } else {
      progressWidth = size.width * progress;
    }

    // Draw progress
    if (progressWidth > 0) {
      Rect progressRect;
      if (isRTL) {
        progressRect = Rect.fromLTWH(
          size.width - progressWidth,
          0,
          progressWidth,
          size.height,
        );
      } else {
        progressRect = Rect.fromLTWH(0, 0, progressWidth, size.height);
      }

      if (linearGradient != null) {
        progressPaint.shader = linearGradient!.createShader(progressRect);
      }

      if (barRadius != null) {
        RRect progressRRect;
        if (clipLinearGradient || progress >= 1.0) {
          progressRRect = RRect.fromRectAndRadius(progressRect, barRadius!);
        } else {
          // Only round the appropriate corners for partial progress
          if (isRTL) {
            progressRRect = RRect.fromRectAndCorners(
              progressRect,
              topRight: barRadius!,
              bottomRight: barRadius!,
            );
          } else {
            progressRRect = RRect.fromRectAndCorners(
              progressRect,
              topLeft: barRadius!,
              bottomLeft: barRadius!,
            );
          }
        }
        canvas.drawRRect(progressRRect, progressPaint);
      } else {
        canvas.drawRect(progressRect, progressPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}