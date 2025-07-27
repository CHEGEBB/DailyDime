// lib/widgets/common/glass_kit.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassKit extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;
  final double blur;
  final LinearGradient linearGradient;
  final Border? border;
  final LinearGradient? borderGradient;
  final EdgeInsets? padding;

  const GlassKit({
    Key? key,
    required this.child,
    this.height,
    this.width,
    required this.borderRadius,
    required this.blur,
    required this.linearGradient,
    this.border,
    this.borderGradient,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: border,
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              gradient: linearGradient,
              borderRadius: borderRadius,
              border: border,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}