import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class NetworkImageHelper {
  /// Check if the device has internet connection
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Preload image and cache it
  static Future<String?> preloadImage(String imageUrl) async {
    try {
      // Skip placeholder URLs
      if (imageUrl.contains('via.placeholder.com') || imageUrl.contains('placeholder')) {
        return null;
      }
      
      // Check for internet connection first
      final hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        return null;
      }

      // Try to get from cache or download
      final file = await DefaultCacheManager().getSingleFile(imageUrl);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  /// Get the local asset path for a specific product type
  static String getLocalAssetForProductType(String productType) {
    switch (productType.toLowerCase()) {
      case 'tire':
        return 'assets/images/tire_placeholder.png';
      case 'tool':
        return 'assets/images/tool_placeholder.png';
      case 'part':
        return 'assets/images/part_placeholder.png';
      case 'glass':
        return 'assets/images/glass_placeholder.png';
      default:
        return 'assets/images/product_placeholder.png';
    }
  }

  /// Widget to display when image loading fails
  static Widget buildErrorWidget(BuildContext context, Object error, {String? productType}) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error is SocketException 
                ? Icons.wifi_off
                : _getIconForProductType(productType),
            size: 40,
            color: error is SocketException 
                ? Colors.orange[300]
                : Colors.grey[500],
          ),
          if (error is SocketException)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                'Check Connection',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  static IconData _getIconForProductType(String? productType) {
    switch (productType?.toLowerCase()) {
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
} 