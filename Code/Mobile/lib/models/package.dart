class Package {
  final String id;
  final String name;
  final String description;
  final double price;
  final DateTime validUntil;
  final List<String> servicesIncluded;
  final int usageCount;
  final int maxUsage;

  Package({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.validUntil,
    required this.servicesIncluded,
    required this.usageCount,
    required this.maxUsage,
  });

  // Methods can be added to convert the model to/from JSON when there's API communication
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'validUntil': validUntil.toIso8601String(),
      'servicesIncluded': servicesIncluded,
      'usageCount': usageCount,
      'maxUsage': maxUsage,
    };
  }

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      validUntil: DateTime.parse(json['validUntil']),
      servicesIncluded: List<String>.from(json['servicesIncluded']),
      usageCount: json['usageCount'],
      maxUsage: json['maxUsage'],
    );
  }
} 