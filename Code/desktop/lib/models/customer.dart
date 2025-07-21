
class Customer {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String mobile;
  
  Customer({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobile,
  });
  
  factory Customer.fromFirestore(Map<String, dynamic> data, String id) {
    return Customer(
      id: id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      mobile: data['mobile'] ?? '',
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'mobile': mobile,
    };
  }
  
  String get fullName => '$firstName $lastName';
} 