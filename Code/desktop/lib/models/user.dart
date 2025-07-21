import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String profileImage;
  final String status;
  final DateTime lastSeen;
  final DateTime? createdAt;
  final bool isAdmin;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage = '',
    this.status = 'active',
    required this.lastSeen,
    this.createdAt,
    this.isAdmin = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profileImage'] ?? '',
      status: json['status'] ?? 'offline',
      lastSeen: json['lastSeen'] is Timestamp 
        ? (json['lastSeen'] as Timestamp).toDate()
        : json['lastSeen'] is String 
            ? DateTime.parse(json['lastSeen']) 
            : DateTime.now(),
      createdAt: json['createdAt'] is Timestamp 
        ? (json['createdAt'] as Timestamp).toDate()
        : json['createdAt'] is String 
            ? DateTime.parse(json['createdAt']) 
            : null,
      isAdmin: json['isAdmin'] ?? false,
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      profileImage: data['profileImage'] ?? '',
      status: data['status'] ?? 'offline',
      lastSeen: data['lastSeen'] is Timestamp 
        ? (data['lastSeen'] as Timestamp).toDate()
        : data['lastSeen'] is String 
            ? DateTime.parse(data['lastSeen']) 
            : DateTime.now(),
      createdAt: data['createdAt'] is Timestamp 
        ? (data['createdAt'] as Timestamp).toDate()
        : data['createdAt'] is String 
            ? DateTime.parse(data['createdAt']) 
            : null,
      isAdmin: data['isAdmin'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'status': status,
      'lastSeen': lastSeen.toIso8601String(),
      'isAdmin': isAdmin,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'status': status,
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isAdmin': isAdmin,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImage,
    String? status,
    DateTime? lastSeen,
    DateTime? createdAt,
    bool? isAdmin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
