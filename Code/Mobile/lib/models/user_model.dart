class User {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobile;
  final String password;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String?,
      firstName: map['firstName'] as String,
      lastName: map['lastName'] as String,
      email: map['email'] as String,
      mobile: map['mobile'] as String,
      password: map['password'] as String,
    );
  }
}
