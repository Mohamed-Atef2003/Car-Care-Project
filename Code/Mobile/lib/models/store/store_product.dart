// Base model for all store products with common properties
abstract class StoreProduct {
  final String id;
  final String name;
  final String category;
  final String brand;
  final double price;
  final double? oldPrice;
  final double rating;
  final int ratingCount;
  final String imageUrl;
  final List<String> images;
  final String description;
  final Map<String, dynamic> specifications;
  final List<String> features;
  final bool inStock;
  final int stockCount;
  final String warranty;
  final bool hasDiscount;
  final double discountPercentage;

  StoreProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.brand,
    required this.price,
    this.oldPrice,
    this.rating = 0.0,
    this.ratingCount = 0,
    required this.imageUrl,
    required this.images,
    required this.description,
    required this.specifications,
    required this.features,
    this.inStock = true,
    this.stockCount = 0,
    required this.warranty,
    this.hasDiscount = false,
    this.discountPercentage = 0.0,
  });

  // Methods to convert to/from Map for Firebase
  Map<String, dynamic> toMap();
  
  // Helper methods for UI
  bool get isDiscounted => hasDiscount && discountPercentage > 0;
  double get actualPrice => isDiscounted ? price * (1 - discountPercentage / 100) : price;
  double get savedAmount => isDiscounted ? price * (discountPercentage / 100) : 0;
} 