import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isFullWidth;
  final bool isprimaryLight;
  final bool isOutlined;
  final bool isDisabled;
  final Widget? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = false,
    this.isprimaryLight = false,
    this.isOutlined = false,
    this.isDisabled = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getForegroundColor(),
          disabledBackgroundColor: AppColors.grey.withOpacity(0.3),
          disabledForegroundColor: AppColors.grey,
          side: isOutlined
              ? BorderSide(color: isprimaryLight ? AppColors.primaryLight : AppColors.primary)
              : null,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 14,
          ),
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }
    return Text(text);
  }

  Color _getBackgroundColor() {
    if (isOutlined) {
      return Colors.transparent;
    }
    return isprimaryLight ? AppColors.primaryLight : AppColors.primary;
  }

  Color _getForegroundColor() {
    if (isOutlined) {
      return isprimaryLight ? AppColors.primaryLight : AppColors.primary;
    }
    return AppColors.white;
  }
} 