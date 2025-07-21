import 'package:flutter/material.dart';

/// A utility class to provide placeholder widgets for products when images can't be loaded
class PlaceholderImageProvider {
  /// Generate a placeholder widget for a product type
  static Widget getPlaceholderWidget(String productType, {
    double? width, 
    double? height,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    // Default values
    backgroundColor = backgroundColor ?? Colors.grey[200];
    iconColor = iconColor ?? Colors.grey[600];
    width = width ?? 200;
    height = height ?? 200;
    
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForProductType(productType),
              size: width / 4,
              color: iconColor,
            ),
            SizedBox(height: 12),
            Text(
              _getTextForProductType(productType),
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Get the appropriate icon for a product type
  static IconData _getIconForProductType(String productType) {
    switch (productType.toLowerCase()) {
      case 'tire':
        return Icons.tire_repair;
      case 'tool':
        return Icons.build;
      case 'part':
        return Icons.settings;
      case 'glass':
        return Icons.grid_view;
      default:
        return Icons.image_not_supported_outlined;
    }
  }

  /// Get the appropriate text for a product type
  static String _getTextForProductType(String productType) {
    switch (productType.toLowerCase()) {
      case 'tire':
        return 'Tire Image';
      case 'tool':
        return 'Tool Image';
      case 'part':
        return 'Spare Part Image';
      case 'glass':
        return 'Glass Image';
      default:
        return 'Product Image';
    }
  }
} 