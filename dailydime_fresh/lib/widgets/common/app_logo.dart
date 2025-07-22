// lib/widgets/common/app_logo.dart

import 'package:flutter/material.dart';
import 'package:dailydime/config/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    Key? key,
    this.size = 60,
    this.showText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryEmerald,
                AppTheme.primaryTeal,
                AppTheme.primaryBlue,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              Icons.monetization_on_outlined,
              color: Colors.white,
              size: size * 0.6,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Daily',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryEmerald,
                ),
              ),
              Text(
                'Dime',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}