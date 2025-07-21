import 'store_product.dart';

/// Spare parts product model
class SparePart extends StoreProduct {
  final String partType;
  final String carBrand;
  final String carModel;
  final List<int> compatibleYears;
  final bool isOEM;
  final String material;
  final double weight;
  final String dimensions;
  final String location;
  final String partNumber;
  final String manufacturingCountry;

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
    super.hasDiscount,
    super.discountPercentage,
    required this.partType,
    required this.carBrand,
    required this.carModel,
    required this.compatibleYears,
    this.isOEM = false,
    required this.material,
    required this.weight,
    required this.dimensions,
    required this.location,
    required this.partNumber,
    required this.manufacturingCountry,
  });

  // إنشاء من Map (سيتم استخدامه مع Firebase)
  factory SparePart.fromMap(Map<String, dynamic> data) {
    return SparePart(
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
      partType: data['partType'] ?? '',
      carBrand: data['carBrand'] ?? '',
      carModel: data['carModel'] ?? '',
      compatibleYears: List<int>.from(data['compatibleYears'] ?? []),
      isOEM: data['isOEM'] ?? false,
      material: data['material'] ?? '',
      weight: (data['weight'] ?? 0.0).toDouble(),
      dimensions: data['dimensions'] ?? '',
      location: data['location'] ?? '',
      partNumber: data['partNumber'] ?? '',
      manufacturingCountry: data['manufacturingCountry'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'spare_part',
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
      'partType': partType,
      'carBrand': carBrand,
      'carModel': carModel,
      'compatibleYears': compatibleYears,
      'isOEM': isOEM,
      'material': material,
      'weight': weight,
      'dimensions': dimensions,
      'location': location,
      'partNumber': partNumber,
      'manufacturingCountry': manufacturingCountry,
    };
  }

  // Getters auxiliares para la UI
  String get weightDisplay => '$weight كجم';
  String get oem => isOEM ? 'قطعة أصلية' : 'قطعة بديلة';
  
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