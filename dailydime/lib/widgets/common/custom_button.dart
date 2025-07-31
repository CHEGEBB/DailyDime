// lib/widgets/common/custom_button.dart

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double width;
  final bool isSmall;
  final Color? buttonColor; // Changed from MaterialColor to Color

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width = double.infinity,
    required this.isSmall,
    this.buttonColor, // Made optional since it might not always be needed
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: buttonColor ?? theme.colorScheme.primary),
          minimumSize: Size(width, isSmall ? 40 : 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildButtonContent(theme),
      );
    }
    
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor, // Use the custom color if provided
        minimumSize: Size(width, isSmall ? 45 : 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _buildButtonContent(theme),
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        height: isSmall ? 20 : 24,
        width: isSmall ? 20 : 24,
        child: CircularProgressIndicator(
          color: isOutlined 
              ? (buttonColor ?? theme.colorScheme.primary) 
              : Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 18 : 20),
          const SizedBox(width: 8),
          Text(
            text, 
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 14 : 16,
            ),
          ),
        ],
      );
    }

    return Text(
      text, 
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: isSmall ? 14 : 16,
      ),
    );
  }
}