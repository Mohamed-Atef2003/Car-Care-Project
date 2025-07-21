
class CustomerOrder {
  final String documentId;
  final String orderId;
  final String userName;
  final String emailAddress;
  final String phoneNumber;
  final String address;
  final double amount;
  final String currency;
  final String serviceType;
  final String packageName;
  final String orderType;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime createdAt;
  final List<String>? serviceFeatures;
  final List<String>? packageFeatures;
  final String? description;
  final String? notes;
  final String? deliveryNotes;
  final Map<String, dynamic>? deliveryLocation;
  final List<Map<String, dynamic>>? items;

  CustomerOrder({
    required this.documentId,
    required this.orderId,
    required this.userName,
    required this.emailAddress,
    required this.phoneNumber,
    required this.address,
    required this.amount,
    required this.currency,
    required this.serviceType,
    required this.packageName,
    required this.orderType,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    this.serviceFeatures,
    this.packageFeatures,
    this.description,
    this.notes,
    this.deliveryNotes,
    this.deliveryLocation,
    this.items,
  });

  factory CustomerOrder.fromFirestore(Map<String, dynamic> data) {
    return CustomerOrder(
      documentId: data['id'] ?? '',
      orderId: data['orderId'] ?? '',
      userName: data['customerName'] ?? 'Unknown',
      emailAddress: data['customerEmail'] ?? '',
      phoneNumber: data['customerPhone'] ?? '',
      address: data['deliveryAddress'] ?? '',
      amount: (data['amount'] is int) ? (data['amount'] as int).toDouble() : (data['amount'] ?? 0.0),
      currency: data['currency'] ?? 'SAR',
      serviceType: data['serviceType'] ?? '',
      packageName: data['packageName'] ?? '',
      orderType: data['orderType'] ?? 'product',
      paymentMethod: data['paymentMethod'] ?? '',
      paymentStatus: data['paymentStatus'] ?? 'Pending',
      status: data['status'] ?? 'Pending',
      createdAt: data['createdAt'] != null ? (data['createdAt'] as dynamic).toDate() : DateTime.now(),
      serviceFeatures: data['serviceFeatures'] != null 
          ? List<String>.from(data['serviceFeatures']) 
          : null,
      packageFeatures: data['packageFeatures'] != null 
          ? List<String>.from(data['packageFeatures']) 
          : null,
      description: data['description'],
      notes: data['notes'],
      deliveryNotes: data['deliveryNotes'],
      deliveryLocation: data['deliveryLocation'],
      items: data['items'] != null 
          ? List<Map<String, dynamic>>.from(data['items']) 
          : null,
    );
  }
}
