import 'store_product.dart';

/// Glass product model
class Glass extends StoreProduct {
  final String glassType; // نوع الزجاج (الزجاج الامامي، الجانبي، الخلفي)
  final String carBrand;
  final String carModel;
  final List<int> compatibleYears;
  final double thickness;
  final String material;
  final bool tinted;
  final int tintPercentage;
  final bool hasUVProtection;
  final bool isHeated;
  final bool hasRainSensor;
  final String manufacturingCountry;
  final String position;

  Glass({
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
    required this.glassType,
    required this.carBrand,
    required this.carModel,
    required this.compatibleYears,
    required this.thickness,
    required this.material,
    this.tinted = false,
    this.tintPercentage = 0,
    this.hasUVProtection = false,
    this.isHeated = false,
    this.hasRainSensor = false,
    required this.manufacturingCountry,
    required this.position,
  });

  // إنشاء من Map (سيتم استخدامه مع Firebase)
  factory Glass.fromMap(Map<String, dynamic> data) {
    return Glass(
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
      glassType: data['glassType'] ?? '',
      carBrand: data['carBrand'] ?? '',
      carModel: data['carModel'] ?? '',
      compatibleYears: List<int>.from(data['compatibleYears'] ?? []),
      thickness: (data['thickness'] ?? 0.0).toDouble(),
      material: data['material'] ?? '',
      tinted: data['tinted'] ?? false,
      tintPercentage: data['tintPercentage'] ?? 0,
      hasUVProtection: data['hasUVProtection'] ?? false,
      isHeated: data['isHeated'] ?? false,
      hasRainSensor: data['hasRainSensor'] ?? false,
      manufacturingCountry: data['manufacturingCountry'] ?? '',
      position: data['position'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'glass', // Agregar campo tipo
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
      'glassType': glassType,
      'carBrand': carBrand,
      'carModel': carModel,
      'compatibleYears': compatibleYears,
      'thickness': thickness,
      'material': material,
      'tinted': tinted,
      'tintPercentage': tintPercentage,
      'hasUVProtection': hasUVProtection,
      'isHeated': isHeated,
      'hasRainSensor': hasRainSensor,
      'manufacturingCountry': manufacturingCountry,
      'position': position,
    };
  }

  // Getters auxiliares para la UI
  String get thicknessDisplay => '$thickness مم';
  String get positionDisplay {
    switch (position.toLowerCase()) {
      case 'windshield':
      case 'front':
        return 'زجاج أمامي';
      case 'rear':
        return 'زجاج خلفي';
      case 'side_left':
      case 'left':
        return 'زجاج جانبي (يسار)';
      case 'side_right':
      case 'right':
        return 'زجاج جانبي (يمين)';
      case 'sunroof':
        return 'فتحة سقف';
      default:
        return position;
    }
  }

  String get yearsDisplay {
    if (compatibleYears.isEmpty) return '';
    if (compatibleYears.length == 1) return '${compatibleYears[0]}';
    
    // Sort years
    List<int> sortedYears = List.from(compatibleYears)..sort();
    
    // Find consecutive ranges
    List<String> ranges = [];
    int start = sortedYears[0];
    int end = start;
    
    for (int i = 1; i < sortedYears.length; i++) {
      if (sortedYears[i] == end + 1) {
        end = sortedYears[i];
      } else {
        // Add the previous range
        if (start == end) {
          ranges.add('$start');
        } else {
          ranges.add('$start-$end');
        }
        // Start a new range
        start = end = sortedYears[i];
      }
    }
    
    // Add the last range
    if (start == end) {
      ranges.add('$start');
    } else {
      ranges.add('$start-$end');
    }
    
    return ranges.join(', ');
  }
} 