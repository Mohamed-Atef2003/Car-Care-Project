class PaymentTransaction {
  final String transactionId;
  final double amount;
  final String currency;
  final DateTime timestamp;
  final String paymentMethod;
  final bool success;
  final String? error;
  final String errorCode;
  final String errorMessage;
  final Map<String, dynamic>? additionalData;
  final String orderId;

  PaymentTransaction({
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.timestamp,
    required this.paymentMethod,
    required this.success,
    this.error,
    this.errorCode = '',
    this.errorMessage = '',
    this.additionalData,
    required this.orderId,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      transactionId: json['transactionId'] ?? '',
      amount: (json['amount'] is int) 
          ? (json['amount'] as int).toDouble() 
          : json['amount'] ?? 0.0,
      currency: json['currency'] ?? 'EGP',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      paymentMethod: json['paymentMethod'] ?? 'unknown',
      success: json['success'] ?? false,
      error: json['error'],
      errorCode: json['errorCode'] ?? '',
      errorMessage: json['errorMessage'] ?? json['error'] ?? '',
      additionalData: json['additionalData'],
      orderId: json['orderId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'currency': currency,
      'timestamp': timestamp.toIso8601String(),
      'paymentMethod': paymentMethod,
      'success': success,
      'error': error,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
      'additionalData': additionalData,
      'orderId': orderId,
    };
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String icon;
  final bool isDefault;
  final Map<String, dynamic>? details;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    this.isDefault = false,
    this.details,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      isDefault: json['isDefault'] ?? false,
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'isDefault': isDefault,
      'details': details,
    };
  }
}

class PaymentSummary {
  final double subtotal;
  final double tax;
  final double deliveryFee;
  final double discount;
  final double total;
  final String currency;
  final List<Map<String, dynamic>>? items;
  final Map<String, dynamic>? additionalData;

  PaymentSummary({
    required this.subtotal,
    required this.tax,
    this.deliveryFee = 20.0,
    required this.discount,
    required this.total,
    required this.currency,
    this.items,
    this.additionalData,
  });

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      subtotal: (json['subtotal'] is int) 
          ? (json['subtotal'] as int).toDouble() 
          : json['subtotal'] ?? 0.0,
      tax: (json['tax'] is int) 
          ? (json['tax'] as int).toDouble() 
          : json['tax'] ?? 0.0,
      deliveryFee: (json['deliveryFee'] is int) 
          ? (json['deliveryFee'] as int).toDouble() 
          : json['deliveryFee'] ?? 20.0,
      discount: (json['discount'] is int) 
          ? (json['discount'] as int).toDouble() 
          : json['discount'] ?? 0.0,
      total: (json['total'] is int) 
          ? (json['total'] as int).toDouble() 
          : json['total'] ?? 0.0,
      currency: json['currency'] ?? 'EGP',
      items: (json['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subtotal': subtotal,
      'tax': tax,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'currency': currency,
      'items': items,
      'additionalData': additionalData,
    };
  }
} 