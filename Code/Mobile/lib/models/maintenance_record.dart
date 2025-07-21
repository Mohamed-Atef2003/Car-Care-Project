class MaintenanceRecord {
  final int? id;
  final String userId;
  final String carModel;
  final String serviceType;
  final String description;
  final DateTime date;
  final double cost;
  final int mileage;

  MaintenanceRecord({
    this.id,
    required this.userId,
    required this.carModel,
    required this.serviceType,
    required this.description,
    required this.date,
    required this.cost,
    required this.mileage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'carModel': carModel,
      'serviceType': serviceType,
      'description': description,
      'date': date.toIso8601String(),
      'cost': cost,
      'mileage': mileage,
    };
  }

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecord(
      id: map['id'],
      userId: map['userId'],
      carModel: map['carModel'],
      serviceType: map['serviceType'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      cost: map['cost'],
      mileage: map['mileage'],
    );
  }
}
