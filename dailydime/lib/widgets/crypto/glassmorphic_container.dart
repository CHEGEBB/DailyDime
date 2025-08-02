// lib/widgets/crypto/glassmorphic_container.dart

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double blur;
  final double border;
  final Alignment alignment;
  final LinearGradient linearGradient;
  final LinearGradient borderGradient;
  final Widget child;
  
  const GlassmorphicContainer({
    Key? key,
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.blur,
    required this.alignment,
    required this.border,
    required this.linearGradient,
    required this.borderGradient,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: borderGradient,
      ),
      child: Container(
        margin: EdgeInsets.all(border),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius - border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius - border),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius - border),
                gradient: linearGradient,
              ),
              alignment: alignment,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}