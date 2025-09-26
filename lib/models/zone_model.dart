import 'package:cloud_firestore/cloud_firestore.dart';

class ZoneModel {
  final String id;
  final String name;
  final String imageUrl;
  final int order;
  final DateTime createdAt;

  ZoneModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.order,
    required this.createdAt,
  });

  factory ZoneModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ZoneModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}