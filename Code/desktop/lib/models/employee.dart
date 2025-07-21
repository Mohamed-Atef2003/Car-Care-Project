class Employee {
  final String name;
  final String station;
  final String phoneNumber;
  final String id;
  final String birthDate;
  final String avatarUrl;
  final String? docId;

  Employee({
    required this.name,
    required this.station,
    required this.phoneNumber,
    required this.id,
    required this.birthDate,
    required this.avatarUrl,
    this.docId,
  });

  // Convert Employee to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'station': station,
      'phoneNumber': phoneNumber,
      'id': id,
      'birthDate': birthDate,
      'avatarUrl': avatarUrl,
      if (docId != null) 'docId': docId,
    };
  }

  // Create Employee from JSON map
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name'] ?? '',
      station: json['station'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      id: json['id'] ?? '',
      birthDate: json['birthDate'] ?? '',
      avatarUrl: json['avatarUrl'] ?? json['imageUrl'] ?? 'assets/image/profile.png',
      docId: json['docId'],
    );
  }

  // Sample data for testing
  static List<Employee> getSampleData() {
    return List.generate(
      0,
      (index) => Employee(
        name: 'Finja Lamos',
        station: index % 5 == 0
            ? 'Downtown Auto Service'
            : index % 5 == 1
                ? 'Alexandria Car Clinic'
                : index % 5 == 2
                    ? 'Giza Auto Repair Hub'
                    : index % 5 == 3
                        ? 'Nasr City Motor Works'
                        : 'Smart Auto Center',
        phoneNumber: '+01 444444 6669',
        id: '123456789',
        birthDate: 'Feb 09, 2023',
        avatarUrl: 'assets/image/Ellipse 25.png',
      ),
    );
  }
}
