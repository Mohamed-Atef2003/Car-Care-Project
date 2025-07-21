import 'store_product.dart';

/// Tire products model
class Tire extends StoreProduct {
  // Static definitions for tire seasons
  static const String SEASON_SUMMER = 'Summer';
  static const String SEASON_WINTER = 'Winter';
  static const String SEASON_ALL_SEASON = 'All Season';
  
  // Static definitions for tread patterns
  static const String PATTERN_ASYMMETRIC = 'Asymmetric';
  static const String PATTERN_DIRECTIONAL = 'Directional';
  static const String PATTERN_SYMMETRIC = 'Symmetric';

  final String size;
  final String speedRating;
  final String loadIndex;
  final String season; // صيفي، شتوي، لجميع المواسم
  final String treadPattern; // نمط المداس
  final int warrantyMiles; // الضمان بالميل
  final double treadDepth; // عمق المداس بالمم
  final double wetGrip; // أداء التماسك على الطرق المبللة (0-1)
  final double fuelEfficiency; // كفاءة استهلاك الوقود (0-1)
  final double noiseLevel; // مستوى الضوضاء بالديسيبل
  final bool runFlat; // إطار يمكن القيادة عليه عند الثقب
  final String manufacturingCountry; // بلد التصنيع
  final DateTime manufactureDate; // تاريخ التصنيع

  Tire({
    required super.id,
    required super.name,
    required super.category,
    required super.brand,
    required super.price,
    super.oldPrice,
    super.rating,
    super.ratingCount,
    required super.imageUrl,
    required super.images,
    required super.description,
    required super.specifications,
    required super.features,
    super.inStock,
    super.stockCount,
    required super.warranty,
    super.hasDiscount,
    super.discountPercentage,
    required this.size,
    required this.speedRating,
    required this.loadIndex,
    required this.season,
    required this.treadPattern,
    required this.warrantyMiles,
    required this.treadDepth,
    required this.wetGrip,
    required this.fuelEfficiency,
    required this.noiseLevel,
    this.runFlat = false,
    required this.manufacturingCountry,
    required this.manufactureDate,
  });

  // Create from Map (will be used with Firebase)
  factory Tire.fromMap(Map<String, dynamic> data) {
    return Tire(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      brand: data['brand'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      oldPrice: data['oldPrice']?.toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      description: data['description'] ?? '',
      specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
      features: List<String>.from(data['features'] ?? []),
      inStock: data['inStock'] ?? false,
      stockCount: data['stockCount'] ?? 0,
      warranty: data['warranty'] ?? '',
      hasDiscount: data['hasDiscount'] ?? false,
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      size: data['size'] ?? '',
      speedRating: data['speedRating'] ?? '',
      loadIndex: data['loadIndex'] ?? '',
      season: data['season'] ?? SEASON_ALL_SEASON,
      treadPattern: data['treadPattern'] ?? PATTERN_SYMMETRIC,
      warrantyMiles: data['warrantyMiles'] ?? 0,
      treadDepth: (data['treadDepth'] ?? 0.0).toDouble(),
      wetGrip: (data['wetGrip'] ?? 0.0).toDouble(),
      fuelEfficiency: (data['fuelEfficiency'] ?? 0.0).toDouble(),
      noiseLevel: (data['noiseLevel'] ?? 0.0).toDouble(),
      runFlat: data['runFlat'] ?? false,
      manufacturingCountry: data['manufacturingCountry'] ?? '',
      manufactureDate: data['manufactureDate'] != null 
          ? DateTime.parse(data['manufactureDate']) 
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'tire',
      'id': id,
      'name': name,
      'category': category,
      'brand': brand,
      'price': price,
      'oldPrice': oldPrice,
      'rating': rating,
      'ratingCount': ratingCount,
      'imageUrl': imageUrl,
      'images': images,
      'description': description,
      'specifications': specifications,
      'features': features,
      'inStock': inStock,
      'stockCount': stockCount,
      'warranty': warranty,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
      'size': size,
      'speedRating': speedRating,
      'loadIndex': loadIndex,
      'season': season,
      'treadPattern': treadPattern,
      'warrantyMiles': warrantyMiles,
      'treadDepth': treadDepth,
      'wetGrip': wetGrip,
      'fuelEfficiency': fuelEfficiency,
      'noiseLevel': noiseLevel,
      'runFlat': runFlat,
      'manufacturingCountry': manufacturingCountry,
      'manufactureDate': manufactureDate.toIso8601String(),
    };
  }

  // Helper functions for display
  String get warrantyDisplay => warrantyMiles > 0 ? '${warrantyMiles * 1.60934} km' : 'No warranty';
  
  String get seasonIcon {
    switch (season) {
      case SEASON_SUMMER:
        return '☀️';
      case SEASON_WINTER:
        return '❄️';
      case SEASON_ALL_SEASON:
        return '🌤️';
      default:
        return '🚗';
    }
  }
} 