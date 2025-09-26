import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, client, admin }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? photoUrl;
  final DateTime createdAt;
  final String? venueId; // Solo para clientes

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.photoUrl,
    required this.createdAt,
    this.venueId,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.values.firstWhere(
            (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      venueId: data['venueId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'venueId': venueId,
    };
  }
}