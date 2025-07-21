import 'store_product.dart';

/// نموذج منتجات الأدوات
class Tool extends StoreProduct {
  final String toolType; // نوع الأداة (يدوية، كهربائية، إلخ)
  final String powerSource; // مصدر الطاقة للأدوات الكهربائية (كهرباء، بطارية، هوائية)
  final String material; // مادة صنع الأداة
  final double weight; // الوزن بالكجم
  final String dimensions; // الأبعاد بالسم
  final bool rechargeable;
  final int pieceCount;
  final bool includesCase; // هل تتضمن حقيبة تخزين
  final String motorType;
  final double powerRating;
  final int usageHours;
  final List<String> includedAccessories;
  final String manufacturingCountry;

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
    super.hasDiscount,
    super.discountPercentage,
    required this.toolType,
    required this.material,
    required this.motorType,
    required this.weight,
    required this.dimensions,
    this.rechargeable = false,
    required this.powerSource,
    required this.powerRating,
    required this.usageHours,
    this.includesCase = false,
    required this.includedAccessories,
    required this.manufacturingCountry,
    this.pieceCount = 1,
  });

  // إنشاء من Map (سيتم استخدامه مع Firebase)
  factory Tool.fromMap(Map<String, dynamic> data) {
    return Tool(
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
      toolType: data['toolType'] ?? '',
      material: data['material'] ?? '',
      motorType: data['motorType'] ?? '',
      weight: (data['weight'] ?? 0.0).toDouble(),
      dimensions: data['dimensions'] ?? '',
      rechargeable: data['rechargeable'] ?? false,
      powerSource: data['powerSource'] ?? '',
      powerRating: (data['powerRating'] ?? 0.0).toDouble(),
      usageHours: data['usageHours'] ?? 0,
      includesCase: data['includesCase'] ?? false,
      includedAccessories: List<String>.from(data['includedAccessories'] ?? []),
      manufacturingCountry: data['manufacturingCountry'] ?? '',
      pieceCount: data['pieceCount'] ?? 1,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'tool',
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
      'toolType': toolType,
      'material': material,
      'motorType': motorType,
      'weight': weight,
      'dimensions': dimensions,
      'rechargeable': rechargeable,
      'powerSource': powerSource,
      'powerRating': powerRating,
      'usageHours': usageHours,
      'includesCase': includesCase,
      'includedAccessories': includedAccessories,
      'manufacturingCountry': manufacturingCountry,
      'pieceCount': pieceCount,
    };
  }

  // Getters auxiliares para la UI
  bool get isElectric => powerSource == 'كهربائي';
  bool get isCordless => rechargeable;
  String get weightDisplay => '$weight كجم';
  String get powerDisplay => '$powerRating واط';
} 