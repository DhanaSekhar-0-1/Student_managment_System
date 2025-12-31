import 'package:flutter/material.dart';
import '../../config/theme.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'OK',
    this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color ?? AppTheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onPressed?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? AppTheme.primary,
          ),
          child: Text(buttonText),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
    Color? color,
    IconData? icon,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onPressed: onPressed,
        color: color,
        icon: icon,
      ),
    );
  }

  // Success dialog
  static Future<void> success({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
      color: AppTheme.success,
      icon: Icons.check_circle,
    );
  }

  // Error dialog
  static Future<void> error({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
      color: AppTheme.error,
      icon: Icons.error,
    );
  }

  // Warning dialog
  static Future<void> warning({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onPressed,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      buttonText: buttonText,
      onPressed: onPressed,
      color: AppTheme.warning,
      icon: Icons.warning,
    );
  }
}