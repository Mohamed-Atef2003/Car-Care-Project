// Model classes for store products
// These models are designed to be ready for Firebase integration in the future

/// Base class for all store products with common properties
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
  final List<Map<String, dynamic>> reviews;
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
    this.reviews = const [],
    this.hasDiscount = false,
    this.discountPercentage = 0.0,
  });

  // Methods to convert to/from Map for Firebase
  Map<String, dynamic> toMap();
  
  // Helper methods for UI
  bool get isDiscounted => hasDiscount && discountPercentage > 0;
  double get actualPrice => isDiscounted ? price : (oldPrice ?? price);
  double get savedAmount => isDiscounted ? (oldPrice ?? price) - price : 0;
  
  // Add a stock getter for backward compatibility
  int get stock => stockCount;
}

/// Simple product class for backward compatibility with existing code
class Product extends StoreProduct {
  // Original properties from the old Product class
  @override
  int get stock => stockCount;
  
  Product({
    required super.id,
    required super.name,
    required super.price,
    required super.description,
    required super.imageUrl,
    required int stock,
    super.category = 'Other',
  }) : super(
        brand: '',
        images: [imageUrl],
        specifications: {},
        features: [],
        stockCount: stock,
        warranty: '',
        inStock: stock > 0,
      );
  
  // Create a new Product with modified values (for backward compatibility)
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? imageUrl,
    int? stock,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      stock: stock ?? stockCount,
      category: category ?? this.category,
    );
  }
  
  // Create from a Json map (for backward compatibility)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: (json['imageUrl'] as String?) ?? 'https://via.placeholder.com/300',
      stock: json['stock'] as int,
      category: json['category'] as String? ?? 'Other',
    );
  }
  
  // Convert to Json map (for backward compatibility)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'stock': stockCount,
      'category': category,
    };
  }
  
  @override
  Map<String, dynamic> toMap() {
    return toJson();
  }
}

/// Model for spare parts products
class SparePart extends StoreProduct {
  final List<String> compatibility; // Compatible with which car models
  final String partNumber; // Part number for ordering and identification
  final String origin; // Country of origin

  SparePart({
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
    super.reviews,
    super.hasDiscount,
    super.discountPercentage,
    required this.compatibility,
    required this.partNumber,
    required this.origin,
  });

  // Create from a Map (will be used with Firebase)
  factory SparePart.fromMap(String id, Map<String, dynamic> data) {
    return SparePart(
      id: id,
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
      reviews: List<Map<String, dynamic>>.from(data['reviews'] ?? []),
      hasDiscount: data['hasDiscount'] ?? false,
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      compatibility: List<String>.from(data['compatibility'] ?? []),
      partNumber: data['partNumber'] ?? '',
      origin: data['origin'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
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
      'reviews': reviews,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
      'compatibility': compatibility,
      'partNumber': partNumber,
      'origin': origin,
    };
  }
}

/// Model for tire products
class Tire extends StoreProduct {
  final String size;
  final String speedRating;
  final String loadIndex;
  final String season; // Summer, Winter, All-season
  final String treadPattern; // e.g., Asymmetric, Directional, Symmetric
  final int warrantyMiles; // Warranty in miles
  final double treadDepth; // Tread depth in mm
  final double wetGrip; // Wet grip performance (0-1)
  final double fuelEfficiency; // Fuel efficiency (0-1)
  final double noiseLevel; // Noise level in dB
  final bool runFlat; // Whether it's a run-flat tire
  final String manufacturingCountry; // Country of manufacturing
  final DateTime manufactureDate; // Manufacturing date

  // Static definitions for tire seasons
  static const String SEASON_SUMMER = 'Summer';
  static const String SEASON_WINTER = 'Winter';
  static const String SEASON_ALL_SEASON = 'All Season';
  
  // Static definitions for tread patterns
  static const String PATTERN_ASYMMETRIC = 'Asymmetric';
  static const String PATTERN_DIRECTIONAL = 'Directional';
  static const String PATTERN_SYMMETRIC = 'Symmetric';

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
    super.reviews,
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

  // Create from a Map (will be used with Firebase)
  factory Tire.fromMap(String id, Map<String, dynamic> data) {
    return Tire(
      id: id,
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
      reviews: List<Map<String, dynamic>>.from(data['reviews'] ?? []),
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
      'reviews': reviews,
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

  // Helper getters for UI display
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

/// Model for glass products
class GlassProduct extends StoreProduct {
  final List<String> compatibility; // Compatible with which car models
  final String glassType; // Type of glass (e.g., windshield, side, rear)
  final bool hasTinting; // Whether it has tinting
  final double uvProtectionLevel; // UV protection level (0-1)
  final bool hasHeatingElements; // Whether it has heating elements
  final bool isOriginal; // Whether it's an original manufacturer part

  GlassProduct({
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
    super.reviews,
    super.hasDiscount,
    super.discountPercentage,
    required this.compatibility,
    required this.glassType,
    this.hasTinting = false,
    this.uvProtectionLevel = 0.0,
    this.hasHeatingElements = false,
    this.isOriginal = true,
  });

  // Create from a Map (will be used with Firebase)
  factory GlassProduct.fromMap(String id, Map<String, dynamic> data) {
    return GlassProduct(
      id: id,
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
      reviews: List<Map<String, dynamic>>.from(data['reviews'] ?? []),
      hasDiscount: data['hasDiscount'] ?? false,
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      compatibility: List<String>.from(data['compatibility'] ?? []),
      glassType: data['glassType'] ?? '',
      hasTinting: data['hasTinting'] ?? false,
      uvProtectionLevel: (data['uvProtectionLevel'] ?? 0.0).toDouble(),
      hasHeatingElements: data['hasHeatingElements'] ?? false,
      isOriginal: data['isOriginal'] ?? true,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
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
      'reviews': reviews,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
      'compatibility': compatibility,
      'glassType': glassType,
      'hasTinting': hasTinting,
      'uvProtectionLevel': uvProtectionLevel,
      'hasHeatingElements': hasHeatingElements,
      'isOriginal': isOriginal,
    };
  }
}

/// Model for tools products
class Tool extends StoreProduct {
  final String toolType; // Type of tool (e.g., hand tools, power tools)
  final String powerSource; // For powered tools (e.g., electric, battery, pneumatic)
  final String material; // Material of the tool
  final double weight; // Weight in kg
  final String dimensions; // Dimensions in cm
  final int pieceCount; // For tool sets, how many pieces are included
  final bool includesCase; // Whether it includes a storage case

  Tool({
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
    super.reviews,
    super.hasDiscount,
    super.discountPercentage,
    required this.toolType,
    this.powerSource = 'Manual',
    required this.material,
    this.weight = 0.0,
    this.dimensions = '',
    this.pieceCount = 1,
    this.includesCase = false,
  });

  // Create from a Map (will be used with Firebase)
  factory Tool.fromMap(String id, Map<String, dynamic> data) {
    return Tool(
      id: id,
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
      reviews: List<Map<String, dynamic>>.from(data['reviews'] ?? []),
      hasDiscount: data['hasDiscount'] ?? false,
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      toolType: data['toolType'] ?? '',
      powerSource: data['powerSource'] ?? 'Manual',
      material: data['material'] ?? '',
      weight: (data['weight'] ?? 0.0).toDouble(),
      dimensions: data['dimensions'] ?? '',
      pieceCount: data['pieceCount'] ?? 1,
      includesCase: data['includesCase'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
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
      'reviews': reviews,
      'hasDiscount': hasDiscount,
      'discountPercentage': discountPercentage,
      'toolType': toolType,
      'powerSource': powerSource,
      'material': material,
      'weight': weight,
      'dimensions': dimensions,
      'pieceCount': pieceCount,
      'includesCase': includesCase,
    };
  }
}
